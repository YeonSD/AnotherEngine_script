# ==============================================================================
# 포켓몬 통합 관리 시스템 (개체값, 노력치, 성격, 특성 변경)
# ==============================================================================
def pbpokesys
  # 파티에 포켓몬이 아예 없으면 메뉴를 열지 않고 돌려보냅니다.
  if $player.party.empty?
    pbMessage(_INTL("파티에 포켓몬이 없습니다."))
    return
  end

  loop do
    # 메뉴 선택지 구성
    commands = [
      #_INTL("개체값 6V"),
      _INTL("노력치 설정"),
      #_INTL("성격 변경"),
      #_INTL("특성 변경"), # [추가] 특성 변경
      _INTL("그만두기")
    ]
    
    # -1은 플레이어가 취소(X키 등)를 눌렀을 때의 기본값입니다.
    command = pbMessage(_INTL("포켓몬 관리 시스템입니다. 어떤 작업을 수행하시겠습니까?"), commands, -1)
    
    case command
    # when 0
    #   pbChooseAndMake6V       # 개체값 6V 메이커 호출
    when 0
      pbMaxEVMenu if defined?(pbMaxEVMenu) # 노력치 메뉴 호출
    # when 2
    #   pbChangeNatureMenu if defined?(pbChangeNatureMenu) # 성격 변경 호출
    # when 3
    #   pbChangeAbility if defined?(pbChangeAbility) # [추가] 특성 변경 메뉴 호출
    else
      # '그만두기'를 선택하거나 취소 키를 누르면 루프를 빠져나와 메뉴를 닫습니다.
      pbMessage(_INTL("시스템을 종료합니다."))
      break
    end
  end
end