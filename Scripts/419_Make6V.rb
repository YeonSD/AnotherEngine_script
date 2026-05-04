# 파티 창을 열어 직접 선택한 포켓몬을 6V로 만듭니다.
def pbChooseAndMake6V
  if $player.party.empty?
    pbMessage(_INTL("파티에 포켓몬이 없습니다."))
    return false
  end

  chosen_index = -1
  
  # v21.1 방식: 파티 창을 열고, 선택하고, 닫는 3단계 과정을 거칩니다.
  pbFadeOutIn do
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene, $player.party)
    # 1. 안내 메시지와 함께 화면 열기
    screen.pbStartScene(_INTL("개체값을 최대(6V)로 만들 포켓몬을 선택하세요."), false)
    # 2. 플레이어가 선택한 포켓몬의 자리 번호 가져오기
    chosen_index = screen.pbChoosePokemon
    # 3. 화면 닫기
    screen.pbEndScene
  end

  # 플레이어가 취소하지 않고 포켓몬을 정상적으로 골랐을 경우
  if chosen_index >= 0
    pkmn = $player.party[chosen_index]
    
    # 알(Egg)인지 확인하는 방어 코드
    if pkmn.egg?
      pbMessage(_INTL("알은 선택할 수 없습니다."))
      return false
    end
    
    # 6V 적용 로직
    GameData::Stat.each_main { |s| pkmn.iv[s.id] = 31 }
    pkmn.calc_stats # 변경된 능력치 재계산
    
    pbMessage(_INTL("{1}의 개체값이 모두 최고(6V)가 되었습니다!", pkmn.name))
    return true
  else
    # 플레이어가 선택을 취소하고 뒤로 가기를 누른 경우
    return false
  end
end