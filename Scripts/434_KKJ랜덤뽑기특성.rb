# KKJ 스크립트 맨 위에 추가
# pbDisplayMessage가 정의되지 않았을 경우, pbMessage를 사용하도록 대체합니다.
unless defined?(pbDisplayMessage)
  def pbDisplayMessage(message)
    pbMessage(message)
  end
end

# ★★★★★ 그룹별 특성 목록 분리 ★★★★★

GROUP_A_ABILITIES = [
  :SPEEDBOOST, :LIBERO, :PROTEAN, :MAGICBOUNCE, :MULTISCALE, :TERAFORMZERO,
  :SHADOWSHIELD, :PARENTALBOND, :INTIMIDATE, :REGENERATOR, :PRANKSTER,
  :WELLBAKEDBODY, :WATERABSORB, :MOTORDRIVE, :SAPSIPPER, :VOLTABSORB, #공격무효
	:FLASHFIRE, :LIGHTNINGROD, :STORMDRAIN,:WINDRIDER, #공격무효
	:POISONPOINT, :STATIC, :EFFECTSPORE, :FLAMEBODY, #상태이상
	:HUGEPOWER,:PUREPOWER, :ASONECHILLINGNEIGH,:ASONEGRIMNEIGH,:MOXIE,:BEASTBOOST,:SOULHEART,  #스텟증가
  :DAUNTLESSSHIELD, :INTREPIDSWORD,
	:VESSELOFRUIN, :SWORDOFRUIN, :TABLETSOFRUIN, :BEADSOFRUIN,
	:STAMINA, :CONTRARY,
  :DROUGHT, :DRIZZLE, :SANDSTREAM, :SNOWWARNING,#날씨
	:SANDRUSH, :SWIFTSWIM, :CHLOROPHYLL, :SLUSHRUSH, #날씨 스피드
	:SOLARPOWER,:FLOWERGIFT,
	:GUTS,:QUICKFEET, :MARVELSCALE, #상태이상
	:LEVITATE,:ADAPTABILITY, :GALEWINGS,
  :IRONBARBS, :TECHNICIAN, :SERENEGRACE,
	:GRASSYSURGE,:MISTYSURGE,:PSYCHICSURGE,:ELECTRICSURGE,
].uniq

GROUP_B_ABILITIES = [
	:NORMALIZE, :AERILATE,:PIXILATE,:REFRIGERATE,:GALVANIZE, #스킨
  :UNBURDEN, :UNNERVE,:TOUGHCLAWS,
  :TOXICCHAIN, :POISONTOUCH,:TOXICDEBRIS, #독
  :MAGICGUARD,:PERISHBODY, :FULLMETALBODY,
  :MIRRORARMOR,:MOODY, :UNSEENFIST, :COMPOUNDEYES, :FLUFFY, 
  :NEUROFORCE, :DAZZLING, :TINTEDLENS, :WATERBUBBLE,
  :MINDSEYE,#심안
  :AIRLOCK, :THERMALEXCHANGE,
  :SHEERFORCE, :SHIELDDUST,:PURIFYINGSALT,
  :UNAWARE, :SUPREMEOVERLORD,:FURCOAT, :PRISMARMOR,
	:ICESCALES, :POISONHEAL,
	:ORICHALCUMPULSE, :HADRONENGINE
].uniq

GROUP_C_ABILITIES = [
  :LINGERINGAROMA, :TANGLEDFEET, :SWEETVEIL, :STEELWORKER, :ARENATRAP, :TRUANT,
  :UNBURDEN, :HYPERCUTTER, :UNNERVE, :WEAKARMOR, :WELLBAKEDBODY, :HONEYGATHER,
  :CLOUDNINE, :KEENEYE, :HEATPROOF, :INNARDSOUT, :SEEDSOWER, :NOGUARD,
  :NORMALIZE, :SNOWCLOAK, :DOWNLOAD, :DARKAURA, :TOUGHCLAWS, :SIMPLE,
  :SUPERLUCK, :WIMPOUT, :RUNAWAY, :POISONPOINT, :TOXICCHAIN, :POISONTOUCH,
  :TOXICDEBRIS, :THICKFAT, :OBLIVIOUS, :WANDERINGSPIRIT, :LIGHTMETAL,
  :LEAFGUARD, :MAGMAARMOR, :OWNTEMPO, :MAGICGUARD, :MAGICIAN, :BLAZE,
  :GLUTTONY, :PERISHBODY, :MEGALAUNCHER, :FULLMETALBODY, :SANDSPIT, :SANDVEIL,
  :SANDFORCE, :DEFEATIST, :MERCILESS, :GORILLATACTICS, :DANCER, :GOOEY,
  :WONDERSKIN, :MIRRORARMOR, :MIMICRY, :WINDRIDER, :ROCKYPAYLOAD, :BERSERK,
  :ILLUMINATE, :SOUNDPROOF, :BULLETPROOF, :OVERCOAT, :SCREENCLEANER, :SCRAPPY,
  :SWARM, :MOODY, :COLORCHANGE, :UNSEENFIST, :COMPOUNDEYES, :FLUFFY,
  :BALLFETCH, :CHEEKPOUCH, :CORROSION, :BIGPECKS, :ANGERPOINT, :ANGERSHELL,
  :STEADFAST, :DAUNTLESSSHIELD, :INSOMNIA, :INTREPIDSWORD, :FLAMEBODY,
  :NEUROFORCE, :DAZZLING, :PICKPOCKET, :KLUTZ, :SURGESURFER, :TINTEDLENS,
  :SOLARPOWER, :SOULHEART, :COTTONDOWN, :HARVEST, :WATERVEIL, :WATERBUBBLE,
  :RIPEN, :DAMP, :COMPETITIVE, :VICTORYSTAR, :STALL, :SYNCHRONIZE,
  :SNIPER, :AERILATE, :PROPELLERTAIL, :SKILLLINK, :OVERGROW, :MINDSEYE,
  :STENCH, :ANALYTIC, :AIRLOCK, :QUEENLYMAJESTY, :THERMALEXCHANGE, :SHARPNESS,
  :FOREWARN, :DEFIANT, :AURABREAK, :STRONGJAW, :STURDY, :SHEERFORCE,
  :LONGREACH, :EMERGENCYEXIT, :ANTICIPATION, :LIMBER, :AFTERMATH, :VITALSPIRIT,
  :HUSTLE, :RECKLESS, :MARVELSCALE, :SHIELDDUST, :GALVANIZE, :EARLYBIRD,
  :MAGNETPULL, :NATURALCURE, :STAKEOUT, :CURSEDBODY, :BATTLEARMOR, :COMATOSE,
  :STICKYHOLD, :INNERFOCUS, :JUSTIFIED, :STATIC, :PURIFYINGSALT, :RAINDISH,
  :SHELLARMOR, :RATTLED, :STAMINA, :UNAWARE, :IRONFIST, :SUPREMEOVERLORD,
  :HYDRATION, :LIQUIDVOICE, :HEALER, :TANGLINGHAIR, :QUICKDRAW, :CLEARBODY,
  :SHEDSKIN, :ARMORTAIL, :TELEPATHY, :FRISK, :RIVALRY, :TRACE,
  :TRANSISTOR, :GUARDDOG, :PASTELVEIL, :PUNKROCK, :FURCOAT, :FAIRYAURA,
  :PIXILATE, :OPPORTUNIST, :POISONHEAL, :EFFECTSPORE, :GRASSPELT, :PRESSURE,
  :FRIENDGUARD, :REFRIGERATE, :PRISMARMOR, :FLOWERGIFT, :PICKUP, :FILTER,
  :SOLIDROCK, :WHITESMOKE, :LIQUIDOOZE, :CUTECHARM, :HEAVYMETAL,
  :NEUTRALIZINGGAS, :GOODASGOLD, :SUCTIONCUPS, :TRIAGE, :ILLUSION
].uniq

FORM_CHANGE_ABILITIES = [
	:BATTLEBOND, :TERASHIFT,:ZEROTOHERO,:HUNGERSWITCH,
  :ICEFACE, :DISGUISE,:SCHOOLING,:POWERCONSTRUCT, :STANCECHANGE,:ZENMODE,
  :FORECAST,
].uniq


def pbLearnRandomAbilityOnLevelUp(pkmn)
	return if $player.random_ability_switch == 0 || !$player.random_ability_switch
	return if rand(100)+1 > 60 && $player.random_passive_switch == 0 || rand(100)+1 > 40 && $player.random_passive_switch != 0
	return if pkmn.random_ability_list && $player.random_ability_switch == 2
	
	level_up_pool = (GROUP_A_ABILITIES + GROUP_C_ABILITIES).uniq
  return if level_up_pool.empty?
	
	level_up_pool += GameData::Ability.keys if rand < 0.65
	level_up_pool.reject! { |move| FORM_CHANGE_ABILITIES.include?(move) }
	
  new_ability = nil
  loop do
    new_ability = level_up_pool.sample
    break if new_ability != pkmn.ability
  end
	

  awakening_messages = [
    _INTL("\\j[{1},이,가] 순간적으로 무언가 깨달은 듯하다!", pkmn.name),
    _INTL("\\j[{1},의,의] 잠재력이 폭발했다!", pkmn.name),
    _INTL("\\j[{1},에게,에게] 새로운 가능성이 눈을 떴다!", pkmn.name)
  ]
  random_message = awakening_messages.sample
  new_ability_name = GameData::Ability.get(new_ability).name
  new_ability_desc = GameData::Ability.get(new_ability).description
  old_ability_name = GameData::Ability.get(pkmn.ability).name
	
	pbMessage(_INTL("새로운 특성 「{1}」를 발견했다!", new_ability_name))
  pbMessage(_INTL("<c2=7038F8,ADB5B9>{1}</c2>", new_ability_desc))
	if pbConfirmMessage(_INTL("기존의 특성 「{1}」을(를) 잊고 새로운 특성 「{2}」을(를) 배우시겠습니까?", old_ability_name, new_ability_name))
		pkmn.ability = new_ability
		pbMessage(_INTL("\\j[{1},의,의] 특성은 「{2}」이 되었다!", pkmn.name, new_ability_name))
		pkmn.random_ability_list = []
		GameData::Species.each do |sp|
			next if sp.species != pkmn.species
			loop do
				new_ability = level_up_pool.sample
				break if new_ability != pkmn.ability
			end
			pkmn.random_ability_list.push(new_ability)
		end
		pkmn.random_ability_list[pkmn.form] = pkmn.ability
	end
end

# ★★★★★ 야생 포켓몬용 특성 부여 (메시지 없음) ★★★★★
def give_random_ability_wild(pokemon)
	return if $player.random_ability_switch == 0 || !$player.random_ability_switch
  return if !pokemon.is_a?(Pokemon)
  
  # --- 야생 포켓몬은 C그룹 특성 중에서만 뽑습니다 ---
  wild_pool = GROUP_C_ABILITIES.clone
	wild_pool += GameData::Ability.keys if rand < 0.5
	wild_pool.reject! { |move| FORM_CHANGE_ABILITIES.include?(move) }
  return if wild_pool.empty?
	
	GameData::Species.each do |sp|
    next if sp.species != pokemon.species
		new_ability = wild_pool.sample
    pokemon.random_ability_list.push(new_ability)
  end
	pokemon.ability = pokemon.random_ability_list[pokemon.form]
end

# ★★★★★ [수정] 스타팅 등 확정적으로 특성을 부여할 때 사용 ★★★★★
def give_random_ability_guaranteed(pokemon)
	return if $player.random_ability_switch == 0 || !$player.random_ability_switch
  return if !pokemon.is_a?(Pokemon)

  # --- [수정] 스타팅 포켓몬은 C그룹 특성 중에서만 뽑습니다 ---
  starter_pool = GROUP_C_ABILITIES.clone
	starter_pool += GameData::Ability.keys if rand < 0.5
	starter_pool.reject! { |move| FORM_CHANGE_ABILITIES.include?(move) }
  return if starter_pool.empty?
  
	GameData::Species.each do |sp|
    next if sp.species != pokemon.species
		new_ability = starter_pool.sample
    pokemon.random_ability_list.push(new_ability)
  end
	pokemon.ability = pokemon.random_ability_list[pokemon.form]
end

