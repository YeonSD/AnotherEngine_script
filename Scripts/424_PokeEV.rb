def pbMaxEVMenu
  # 1. 파티에서 포켓몬 선택 화면 띄우기
  pbChoosePokemon(1, 2)
  return if $game_variables[1] < 0 # 취소했을 경우 종료
  
  pokemon = $player.party[$game_variables[1]]
  
  # 알인지 확인
  if pokemon.egg?
    pbMessage(_INTL("알에는 노력치를 줄 수 없어!"))
    return
  end

  # 2. 노력치 선택 메뉴 루프
  loop do
    # 현재 포켓몬의 총 노력치 합산 계산
    total_ev = 0
    GameData::Stat.each_main do |s|
      total_ev += pokemon.ev[s.id]
    end

    # 메뉴 커맨드 구성 (초기화 옵션 추가)
    commands = [
      _INTL("체력 (현재: {1})", pokemon.ev[:HP]),
      _INTL("공격 (현재: {1})", pokemon.ev[:ATTACK]),
      _INTL("방어 (현재: {1})", pokemon.ev[:DEFENSE]),
      _INTL("특수공격 (현재: {1})", pokemon.ev[:SPECIAL_ATTACK]),
      _INTL("특수방어 (현재: {1})", pokemon.ev[:SPECIAL_DEFENSE]),
      _INTL("스피드 (현재: {1})", pokemon.ev[:SPEED]),
      _INTL("모든 노력치 초기화"), # 6번 선택지
      _INTL("그만두기")          # 7번 선택지
    ]
    
    # 510 제한 중 남은 노력치 표시
    remaining_total = Pokemon::EV_LIMIT - total_ev
    choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1]어떤 노력치를 최대로 올릴까? (남은 총 노력치: #{remaining_total})", commands, -1)
    
    # 취소(B버튼) 누르거나 '그만두기(7번)' 선택 시 루프 탈출
    break if choice < 0 || choice == 7
    
    # ========================================
    # [추가된 기능] 모든 노력치 초기화 처리
    # ========================================
    if choice == 6
      if total_ev == 0
        pbMessage("\\xn[\\c[1]\\pn]\\c[1]이미 모든 노력치가 0이야!")
      else
        GameData::Stat.each_main do |s|
          pokemon.ev[s.id] = 0 # 모든 노력치를 0으로 리셋
        end
        pokemon.calc_stats     # 스탯 재계산 (매우 중요!)
        pbMessage("\\xn[\\c[1]\\pn]\\c[1]#{pokemon.name}의 모든 노력치가 깨끗하게 초기화되었다!")
      end
      next # 다시 메뉴 처음으로 돌아감
    end
    
    # ========================================
    # 기존 개별 노력치 최대화 처리
    # ========================================
    stat_id = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED][choice]
    stat_name = ["체력", "공격", "방어", "특수공격", "특수방어", "스피드"][choice]
    
    current_ev = pokemon.ev[stat_id]
    max_stat_ev = Pokemon::EV_STAT_LIMIT # 단일 스탯 최대치 (252)
    
    if current_ev >= max_stat_ev
      pbMessage("\\xn[\\c[1]\\pn]\\c[1]이미 #{stat_name} 노력치가 최대치(#{max_stat_ev})야!")
      next
    end
    
    if total_ev >= Pokemon::EV_LIMIT
      pbMessage("\\xn[\\c[1]\\pn]\\c[1]더 이상 노력치를 줄 수 없어! (총합 #{Pokemon::EV_LIMIT} 도달)")
      next
    end

    # 해당 스탯을 252까지 채우기 위해 필요한 양과, 510 한도까지 남은 양 중 더 작은 값을 더함
    remaining_for_stat = max_stat_ev - current_ev
    add_ev = [remaining_for_stat, remaining_total].min
    
    # 노력치 적용 및 스탯 재계산
    pokemon.ev[stat_id] += add_ev
    pokemon.calc_stats
    
    pbMessage("\\xn[\\c[1]\\pn]\\c[1]#{pokemon.name}의 #{stat_name} 노력치가 #{add_ev}만큼 올라서 #{pokemon.ev[stat_id]}가 되었다!")
  end
end