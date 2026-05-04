# ==============================================================================
# [Another Red] 전역 종족값 확정 엔진 (최우선 스위치 + 절대 시드)
# ==============================================================================

# 1. 전역 세이브 데이터 확장 (스탯 캐시)
class PokemonGlobalMetadata
  attr_accessor :random_stats_cache

  alias __random_stats_init initialize if !method_defined?(:__random_stats_init)
  def initialize
    __random_stats_init
    @random_stats_cache = {}
  end
end

# 2. [중앙 통제] 종족값 절대 확정 함수 (캐싱 엔진)
def pbGetSpeciesFixedStats(species_id, form_id = 0)
  sp_data = GameData::Species.get_species_form(species_id, form_id) rescue nil
  if !sp_data && form_id != 0
    sp_data = GameData::Species.get_species_form(species_id, 0) rescue nil
  end
  return [5,5,5,5,5,5] if !sp_data

  # Switch가 꺼져있으면 캐시 만들지 말고 원본 PBS 반환
  # (switch OFF 상태에서 호출돼도 글로벌 캐시 오염 안 시킴 — export 경로 안전성)
  if !$player || !$player.respond_to?(:random_stats_new_switch) || !$player.random_stats_new_switch
    return sp_data.base_stats.values
  end

  $PokemonGlobal.random_stats_cache ||= {}
  cache_key = "#{species_id}_#{form_id}".to_sym
  
  if !$PokemonGlobal.random_stats_cache[cache_key]
    seed_string = "#{species_id}_#{form_id}_#{$player ? $player.id : 0}"
    seed_val = 0
    seed_string.each_byte { |b| seed_val = (seed_val * 31 + b) % 1000000000 }
    rng = Random.new(seed_val)
    
    orig_total = 0
    sp_data.base_stats.each_value { |s| orig_total += s }
    
    avg_stat = orig_total / 6.0
    randomStats = []
    
    6.times do
      variation = (40 + rng.rand(121)) / 100.0
      stat = (avg_stat * variation).round
      stat = 5 if stat < 5
      randomStats << stat
    end
    
    $PokemonGlobal.random_stats_cache[cache_key] = randomStats
  end
  
  return $PokemonGlobal.random_stats_cache[cache_key]
end

# 3. Pokemon 클래스 강제 오버라이드 (안전 처리 완료)
class Pokemon
  attr_accessor :random_stats

  # 원래 메서드가 존재할 때만 백업하도록 예외 처리 (오류 방지)
  if method_defined?(:baseStats)
    alias __orig_baseStats baseStats if !method_defined?(:__orig_baseStats)
  end
  if method_defined?(:base_stats)
    alias __orig_base_stats base_stats if !method_defined?(:__orig_base_stats)
  end

  # 에센셜 코어가 주로 호출하는 대문자 baseStats
  def baseStats
    if defined?($player) && $player && $player.respond_to?(:random_stats_new_switch) && $player.random_stats_new_switch
      res = pbGetSpeciesFixedStats(self.species, self.form)
      return { :HP => res[0], :ATTACK => res[1], :DEFENSE => res[2], :SPECIAL_ATTACK => res[3], :SPECIAL_DEFENSE => res[4], :SPEED => res[5] }
    end
    
    if self.random_stats && self.random_stats[self.form]
      res = self.random_stats[self.form]
      return { :HP => res[0], :ATTACK => res[1], :DEFENSE => res[2], :SPECIAL_ATTACK => res[3], :SPECIAL_DEFENSE => res[4], :SPEED => res[5] }
    end

    return __orig_baseStats if respond_to?(:__orig_baseStats)
    return GameData::Species.get_species_form(self.species, self.form).base_stats rescue {}
  end

  # 호환성을 위한 소문자 base_stats 연결
  def base_stats
    return self.baseStats
  end
end

# 4. 개체 적용 함수 (플레이어용)
def give_random_stats(pkmn)
  return if !pkmn.is_a?(Pokemon)
  
  if defined?($player) && $player.respond_to?(:random_stats_new_switch) && $player.random_stats_new_switch
    pkmn.calc_stats
    return
  end
  
  return if (!$player.random_stats_switch || $player.random_stats_switch == 0)
  
  random_stats_hash = {}
  GameData::Species.each do |sp|
    next if sp.species != pkmn.species
    next if sp.id.to_s.include?("GMAX") || sp.id.to_s.include?("DMAX")
    
    ret = 0
    baseStats = sp.base_stats
    baseStats.each_value { |s| ret += s }

    totalStats = 100 + rand(651)
    if $player.random_stats_switch == 1
      totalStats = ret - 30
    elsif $player.random_stats_switch == 2
      totalStats = (ret * (40 + rand(121)) / 100.0) - 30
      totalStats = totalStats.round
    end
    
    tempStats = [5, 5, 5, 5, 5, 5]
    i = 0
    while totalStats > 0
      rstat = rand(101)
      rstat = totalStats if rstat > totalStats
      tempStats[i % 6] += rstat
      totalStats -= rstat
      i += 1
      tempStats.shuffle! if i > 6 && i % 6 == 0
    end
    tempStats.shuffle!
    
    if $player.random_stats_switch == 3
      tempStats = []
      baseStats.each_value do |s|
        stat = (ret / 6.0) * (40 + rand(121)) / 100.0
        tempStats << stat.round
      end
    end
    
    random_stats_hash[sp.form] = tempStats
  end
  
  pkmn.random_stats = random_stats_hash
  pkmn.calc_stats
end

# 5. 개체 적용 함수 (트레이너용)
def random_stats_trainer(pkmn)
  return if !pkmn.is_a?(Pokemon)
  
  if defined?($player) && $player.respond_to?(:random_stats_new_switch) && $player.random_stats_new_switch
    pkmn.calc_stats
    return
  end
  
  return if !($player.random_stats_switch2 rescue false)
  
  random_stats_hash = {}
  GameData::Species.each do |sp|
    next if sp.species != pkmn.species
    
    ret = 0
    baseStats = sp.base_stats
    baseStats.each_value { |s| ret += s }

    totalStats = ret / 2 + rand(851 - ret / 2)
    if $player.random_stats_switch == 1
      totalStats = ret - 30
    elsif $player.random_stats_switch == 2
      totalStats = (ret * (80 + rand(121)) / 100.0) - 30
    end
    totalStats *= 1.3 if $player.super_random
    totalStats = totalStats.round
    
    tempStats = [5, 5, 5, 5, 5, 5]
    i = 0
    while totalStats > 0
      rstat = rand(120) + 1
      rstat = totalStats if rstat > totalStats
      tempStats[i % 6] += rstat
      totalStats -= rstat
      i += 1
      tempStats.shuffle! if i > 6 && i % 6 == 0
    end
    
    tempStats.shuffle! if $player.random_stats_switch != 3
    
    if $player.random_stats_switch == 3
      tempStats = []
      baseStats.each_value do |s|
        stat = (ret / 6.0) * (40 + rand(121)) / 100.0
        tempStats << stat.round
      end
    end
    random_stats_hash[sp.form] = tempStats
  end
  
  pkmn.random_stats = random_stats_hash
  pkmn.calc_stats
end