def pbChangeAbility
  if $player.party.empty?
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](파티에 포켓몬이 없다!)")
    return
  end

  loop do
    # 파티에 있는 포켓몬 이름 목록 생성
    party_cmds = $player.party.map { |p| p.name }
    party_cmds.push(_INTL("취소"))
    
    # 포켓몬 선택
    pkmn_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1]누구의 특성을 바꿀까?", party_cmds, party_cmds.size)
    
    # 취소를 누르거나 범위를 벗어나면 종료
    break if pkmn_choice < 0 || pkmn_choice >= $player.party.size
    
    pkmn = $player.party[pkmn_choice]
    
    # 알 예외 처리
    if pkmn.egg?
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](알의 특성은 바꿀 수 없어!)")
      next
    end
    
    # 선택한 포켓몬의 폼 데이터 불러오기
    species_data = pkmn.species_data
    available_abilities = []
    
    # [중요] 특성 자체뿐만 아니라 '특성 인덱스 번호'도 함께 저장합니다.
    # 일반 특성 (인덱스 0, 1) 배열에 추가
    species_data.abilities.each_with_index do |ab, i|
      available_abilities << [ab, i] unless available_abilities.any? { |a| a[0] == ab }
    end
    
    # 숨겨진 특성 (인덱스 2번부터 시작) 배열에 추가
    species_data.hidden_abilities.each_with_index do |ab, i|
      available_abilities << [ab, i + 2] unless available_abilities.any? { |a| a[0] == ab }
    end
    
    # 변경할 수 있는 특성이 없는 경우
    if available_abilities.empty?
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](이 포켓몬은 변경할 수 있는 특성이 없어!)")
      next
    end
    
    # 특성 이름 목록 생성 (화면에 보여줄 용도)
    ability_cmds = available_abilities.map { |ab_data| GameData::Ability.get(ab_data[0]).name }
    ability_cmds.push(_INTL("취소"))
    
    # 현재 특성 이름 확인
    current_ability_name = GameData::Ability.get(pkmn.ability).name
    
    # 특성 선택
    ab_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1]어떤 특성으로 변경할까?\\n(현재 특성: #{current_ability_name})", ability_cmds, ability_cmds.size)
    
    # 취소 누르면 다시 포켓몬 선택 창으로
    next if ab_choice < 0 || ab_choice >= available_abilities.size
    
    # 선택한 특성 데이터 적용
    new_ability = available_abilities[ab_choice][0]
    new_ability_index = available_abilities[ab_choice][1]
    
    if pkmn.ability == new_ability
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](이미 그 특성을 가지고 있어!)")
    else
      # [핵심] 겉으로 보이는 특성뿐만 아니라 내부 슬롯(인덱스)까지 완전히 바꿔줍니다.
      pkmn.ability_index = new_ability_index
      pkmn.ability = new_ability
      
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](#{pkmn.name}의 특성이 #{GameData::Ability.get(new_ability).name}(으)로 영구 고정되었다!)")
    end
  end
end