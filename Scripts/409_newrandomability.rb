# ==============================================================================
# [Another Red] 전역 랜덤 특성 확정 엔진 (최우선 스위치 + 절대 시드)
# ==============================================================================

# 1. 전역 세이브 데이터 확장 (특성 캐시)
class PokemonGlobalMetadata
  attr_accessor :random_ability_cache

  # 무한 루프 에러(SystemStackError)를 막기 위한 안전한 alias 선언
  alias __random_ability_init initialize unless method_defined?(:__random_ability_init)
  def initialize
    __random_ability_init
    @random_ability_cache = {}
  end
end

# 2. [중앙 통제] 특성 캐시 확정 함수
def pbGetSpeciesFixedAbility(species_id, form_id = 0)
  sp_data = GameData::Species.get_species_form(species_id, form_id) rescue nil
  return :PRESSURE if !sp_data
  
  $PokemonGlobal.random_ability_cache ||= {}
  key = [species_id, form_id]
  
  # 캐시에 없다면 고정 시드로 생성
  if !$PokemonGlobal.random_ability_cache[key]
    ex = [:POWERCONSTRUCT,:SCHOOLING,:DISGUISE,:BATTLEBOND,:WONDERGUARD,:STANCECHANGE,:ZENMODE,:HUNGERSWITCH,:GULPMISSILE,:ICEFACE,:IRONLIZE,:BURININGRESOLVE,:POWERAMPLIFIER,:DRAGONIZE,:MEGASOL]
    pool = GameData::Ability.keys.select { |a| !ex.include?(a) }
    
    # [진화체 중복 방지] 고유 시드값을 훨씬 복잡하고 절대 겹치지 않게 연산
    seed_string = "ABILITY_#{species_id}_#{form_id}_#{$player ? $player.id : 0}"
    seed_val = 0
    seed_string.each_byte.with_index do |b, i|
      seed_val = (seed_val * 37 + b * (i + 1)) % 1000000007
    end
    # 종족명 길이에 소수를 곱해 한 번 더 비틀어줌
    seed_val += species_id.to_s.length * 104729
    
    rng = Random.new(seed_val)
    
    # 단순 sample이 아니라 rng 시드를 기반으로 전체를 섞고 가장 앞의 것을 추출
    res = pool.shuffle(random: rng).first || :PRESSURE
    $PokemonGlobal.random_ability_cache[key] = res
  end
  
  return $PokemonGlobal.random_ability_cache[key]
end

# 3. Pokemon 클래스 강제 오버라이드 (무한 루프 원천 차단)
class Pokemon
  alias orig_ability_id_randomizer ability_id unless method_defined?(:orig_ability_id_randomizer)
  
  def ability_id
    if defined?($player) && $player && $player.respond_to?(:random_ability_new_switch) && $player.random_ability_new_switch
      # [핵심] self.form 대신 @form을 사용하여 특성 검사 중 발생하는 폼체인지 무한 루프 에러 해결
      return pbGetSpeciesFixedAbility(@species, @form || 0)
    end
    
    return orig_ability_id_randomizer
  end

  alias orig_ability_randomizer ability unless method_defined?(:orig_ability_randomizer)
  def ability
    if defined?($player) && $player && $player.respond_to?(:random_ability_new_switch) && $player.random_ability_new_switch
      fixed_id = self.ability_id
      return GameData::Ability.get(fixed_id) if fixed_id
      return GameData::Ability.get(:PRESSURE)
    end
    
    return orig_ability_randomizer
  end
end

# 4. 개체 적용 함수 (플레이어/야생)
def give_random_ability(pokemon)
  return if !pokemon.is_a?(Pokemon)
  
  # 새로운 스위치가 켜져있으면 클래스가 자체 제어하므로 텍스트만 출력하고 통과
  if defined?($player) && $player.respond_to?(:random_ability_new_switch) && $player.random_ability_new_switch
    is_wild = pokemon.owner.id || nil
    if !is_wild && pokemon.ability_id != :PRESSURE
      new_ability_name = GameData::Ability.get(pokemon.ability_id).name
      pbMessage(_INTL("{1}은/는 새로운 특성 「{2}」을/를 얻었다!", pokemon.name, new_ability_name)) rescue nil
    end
    return
  end

  is_wild = pokemon.owner.id || nil
  special_exclusions = [
    :POWERCONSTRUCT, :SCHOOLING, :DISGUISE, :BATTLEBOND, :STANCECHANGE,
    :ZENMODE, :HUNGERSWITCH, :RKSSYSTEM, :DESOLATELAND, :PRIMORDIALSEA,
    :DELTASTREAM, :INTREPIDSWORD, :DAUNTLESSSHIELD, :TRANSISTOR,
    :DRAGONSMAW, :UNSEENFIST, :IRONLIZE, :BURININGRESOLVE, :POWERAMPLIFIER, :DRAGONIZE, :MEGASOL, :WONDERGUARD
  ]
  valid_abilities = GameData::Ability.keys - special_exclusions
  return if valid_abilities.empty?

  new_ability = valid_abilities.sample
  pokemon.ability = new_ability
  pokemon.random_ability = new_ability

  if !is_wild
    new_ability_name = GameData::Ability.get(new_ability).name
    pbMessage(_INTL("{1}은/는 새로운 특성 「{2}」을/를 얻었다!", pokemon.name, new_ability_name)) rescue nil
  end
end

# 5. 개체 적용 함수 (트레이너용)
def give_random_ability_trainer(pkmn)
  return if !pkmn.is_a?(Pokemon)
  
  if defined?($player) && $player.respond_to?(:random_ability_new_switch) && $player.random_ability_new_switch
    return
  end

  return if !($player.random_ability_switch2 rescue false)
  
  triner_pool = TRAINER_ABILITIES.dup rescue []
  return if triner_pool.empty?
  
  ret = 0
  baseStats = pkmn.baseStats
  baseStats.each_value { |s| ret += s }
  
  if rand(10) < 1 && ret < 450 && !$player.super_random
    triner_pool += GameData::Ability.keys
    triner_pool.reject! { |move| FORM_CHANGE_ABILITIES.include?(move) } rescue nil
  elsif rand(10) < 4 && ret < 500 && !$player.super_random
    triner_pool += GROUP_C_ABILITIES rescue []
  end
  return if triner_pool.empty?
  
  random_ability_hash = {}
  GameData::Species.each do |sp|
    next if sp.species != pkmn.species
    random_ability_hash[sp.form] = triner_pool.sample
  end
  
  pkmn.random_ability_list = random_ability_hash
  pkmn.ability = pkmn.random_ability_list[pkmn.form]
  pkmn.random_ability = pkmn.ability
end