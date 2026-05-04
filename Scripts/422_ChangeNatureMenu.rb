#===============================================================================
# 포켓몬 성격 변경 스크립트 (v21.1 호환, +, - 능력치 표시 포함)
#===============================================================================
def pbChangeNatureMenu
  # 1. 파티 화면을 열어 포켓몬 선택
  pbChoosePokemon(1, 2)
  return if $game_variables[1] < 0 # 뒤로가기를 누르면 취소
  
  # v21.1 플레이어 객체
  pkmn = $player.party[$game_variables[1]]
  
  # 알은 성격을 바꿀 수 없도록 예외 처리
  if pkmn.egg?
    pbMessage(_INTL("알의 성격은 바꿀 수 없습니다."))
    return
  end

  # 2. 능력치 이름 매핑
  stat_names = {
    :ATTACK          => "공격",
    :DEFENSE         => "방어",
    :SPECIAL_ATTACK  => "특공",
    :SPECIAL_DEFENSE => "특방",
    :SPEED           => "스핏"
  }

  commands = []
  nature_ids = []
  
  # 3. v21.1 방식: stat_changes 데이터를 읽어와서 상승/하락 스탯 분류
  GameData::Nature.each do |nature|
    stat_up = nil
    stat_down = nil
    
    # 성격에 따른 능력치 변화율 확인 (예: [[:ATTACK, 10], [:SPEED, -10]])
    if nature.respond_to?(:stat_changes) && nature.stat_changes
      nature.stat_changes.each do |change|
        stat_up = change[0] if change[1] > 0   # 0보다 크면 상승 스탯
        stat_down = change[0] if change[1] < 0 # 0보다 작으면 하락 스탯
      end
    end
    
    if stat_up.nil? && stat_down.nil?
      # 상승/하락이 없는 성격
      commands.push("#{nature.name} (변화 없음)")
    else
      # 상승/하락이 있는 성격
      up_str = stat_names[stat_up] || "???"
      down_str = stat_names[stat_down] || "???"
      commands.push("#{nature.name} (+#{up_str}, -#{down_str})")
    end
    nature_ids.push(nature.id)
  end

  # 4. 성격 목록 창 띄우기
  cmd = pbMessage(_INTL("어떤 성격으로 변경하시겠습니까?"), commands, -1)
  
  # 5. 성격을 선택했다면 변경 적용
  if cmd >= 0
    pkmn.nature = nature_ids[cmd]
    
    # 능력치 즉시 재계산
    pkmn.calc_stats 
    
    pbMessage(_INTL("\\me[Pkmn evolution]{1}의 성격이 {2}(으)로 바뀌었다!", pkmn.name, GameData::Nature.get(nature_ids[cmd]).name))
  end
end