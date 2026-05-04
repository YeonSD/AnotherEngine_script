alias original_pbAddPokemon_for_starters pbAddPokemon unless defined?(original_pbAddPokemon_for_starters)

def pbAddPokemon(pkmn, level = 1, see_form = true)
  # 1. 스타팅 포켓몬 목록 정의 (1~9세대)
  starters = [
    :BULBASAUR, :CHARMANDER, :SQUIRTLE,
    :CHIKORITA, :CYNDAQUIL, :TOTODILE,
    :TREECKO, :TORCHIC, :MUDKIP,
    :TURTWIG, :CHIMCHAR, :PIPLUP,
    :SNIVY, :TEPIG, :OSHAWOTT,
    :CHESPIN, :FENNEKIN, :FROAKIE,
    :ROWLET, :LITTEN, :POPPLIO,
    :GROOKEY, :SCORBUNNY, :SOBBLE,
    :SPRIGATITO, :FUECOCO, :QUAXLY
  ]

  # 넘어온 데이터에서 종족값(species) 추출
  if pkmn.is_a?(Pokemon)
    current_species = pkmn.species
    new_pkmn = pkmn
  else
    current_species = pkmn
    new_pkmn = Pokemon.new(pkmn, level)
  end

  # 2. 조건 확인: 받는 포켓몬이 '스타팅'이고, '파티가 꽉 차 있다면'
  if starters.include?(current_species) && $player.party_full?
    # 도감에는 등록해줌
    $player.pokedex.register(new_pkmn)
    $player.pokedex.set_owned(new_pkmn.species)
    
    # 텍스트 출력 후 PC로 보내지 않고 증발
    pbMessage(_INTL("{1}(을)를 얻었다!", new_pkmn.name))
    pbMessage(_INTL("하지만 파티가 꽉 차서 놓아주었다..."))
    
    return false
  else
    # 파티에 자리가 있거나, 스타팅 포켓몬이 아닌 일반 포켓몬이라면 기존 기능 정상 실행
    return original_pbAddPokemon_for_starters(pkmn, level, see_form)
  end
end