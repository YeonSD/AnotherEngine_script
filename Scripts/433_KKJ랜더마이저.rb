RANDOM_TYPE_POOL = [
  :NORMAL,:FIRE,:WATER,:ELECTRIC,:GRASS,:ICE,:FIGHTING,:POISON,:GROUND,:FLYING,
	:PSYCHIC,:BUG,:ROCK,:GHOST,:DRAGON,:DARK,:STEEL,:FAIRY,
].uniq

ANOTHER_FORM = [
	:ARCANINE_1,:AVALUGG_1,:BASCULIN_2,:BRAVIARY_1,:DUGTRIO_1,:ELECTRODE_1,
	:COPPERAJAH_1,:CUBONE_1,:DARMANITAN_2,:DARUMAKA_2,:DECIDUEYE_1,:DIGLETT_1,:EXEGGUTOR_1,
	:FARFETCHD_1,:GEODUDE_1,:GOLEM_1,:GOODRA_1,:GRAVELER_1,:GRIMER_1,:GROWLITHE_1,:LILLIGANT_1,
	:LINOONE_1,:MAROWAK_1,:MEOWTH_1,:MEOWTH_2,:MRMIME_1,:MUK_1,:NINETALES_1,:PERSIAN_1,
	:PONYTA_1,:QWILFISH_1,:RAICHU_1,:RAPIDASH_1,:RATICATE_1,:RATTATA_1,:SAMUROTT_1,
	:SANDSHREW_1,:SANDSLASH_1,:SLIGGOO_1,:SLOWBRO_1,:SLOWKING_1,:SLOWPOKE_1,
	:SNEASEL_1,:STUNFISK_1,:TYPHLOSION_1,:VOLTORB_1,:VULPIX_1,:WEEZING_1,:WOOPER_1,:YAMASK_1,
	:ZIGZAGOON_1,:ZOROARK_1,:ZORUA_1,:FLOETTE_5,:LYCANROC_1,:LYCANROC_2,:ARTICUNO_1,
	:GRENINJA_2,:MOLTRES_1,:URSALUNA_1,:URSHIFU_1,:ZAPDOS_1,
].uniq

def giverandom(pkmn)
	#랜덤 타입 부여
	give_random_type(pkmn)
	#랜덤 종족값 부여
	give_random_stats(pkmn)
	#랜덤 기술 목록 부여
	giveRandomMoveList(pkmn)
	#랜덤 기술 목록 부여
	giveRandomEXMoveList(pkmn)
end

def give_random_type(pokemon) #랜덤 포켓몬 타입
	return if !$player.random_type_switch
  return if !pokemon.is_a?(Pokemon)
	
	random_type_hash = {}
	
	formcount=0
	
	GameData::Species.each do |sp|
    next if sp.species != pokemon.species
		# 무작위 타입 2개 선택
		shuffled_list = RANDOM_TYPE_POOL.shuffle
		new_type1 = shuffled_list.sample
		shuffled_list = RANDOM_TYPE_POOL.shuffle
		new_type2 = shuffled_list.sample
    
		#폼 당 배열을 저장
		if new_type1 == new_type2 || rand(100)+1 <= 7
			random_type_hash[formcount] = [new_type1]
		else
			random_type_hash[formcount] = [new_type1, new_type2]
		end
		formcount+=1
  end
	
	# 포켓몬 객체에 해시를 저장합니다.
  pokemon.random_type = random_type_hash
	
	pokemon.calc_stats
end

#랜덤 포켓몬 진화,인카운터
def give_random_pokemon(pokemon)
	pokemon_list = []
	GameData::Species.each do |s|
		next if s.form != 0
		next if s.id == :EGG
		pokemon_list << s
	end
	
	pokemon_list = (pokemon_list+ANOTHER_FORM)
	shuffled_safe_list = pokemon_list.shuffle
	new_species = :NECROZMA_3 
	if !pokemon_list.empty?
		loop do
			new_species = pokemon_list.sample
			break if new_species != pokemon
		end
	end
	return new_species
end

def give_random_stats(pkmn) #랜덤 종족값
	return if !$player.random_stats_switch || $player.random_stats_switch == 0
  return if !pkmn.is_a?(Pokemon)
	random_stats_hash = {}
	formcount=0
	GameData::Species.each do |sp|
    next if sp.species != pkmn.species
		ret = 0
		baseStats = GameData::Species.get(sp.species).base_stats
		baseStats.each_value { |s| ret += s }
		totalStats = 100+rand(651)
		if $player.random_stats_switch == 1
			totalStats = ret-30
		elsif $player.random_stats_switch == 2
			totalStats = ret*(40+rand(121))/100.0 - 30
			totalStats = totalStats.round
		end
		randomStats = [5,5,5,5,5,5]
		i=0
		while totalStats > 0
			rstat = rand(101)
			if rstat > totalStats
        rstat = totalStats
			end
			randomStats[i%6] += rstat
			totalStats = totalStats - rstat
			i+=1
			if i>6 && i%6==0
				randomStats.shuffle!
			end
		end
		randomStats.shuffle!
		if $player.random_stats_switch == 3
			randomStats = []
			baseStats = GameData::Species.get(sp.species).base_stats
			baseStats.each_value { |s|
				stat = ret/6.0*(40+rand(121))/100.0
				stat = stat.round
				randomStats << stat
			}
		end
		random_stats_hash[formcount] = randomStats
		formcount+=1
  end
  pkmn.random_stats = random_stats_hash
	pkmn.calc_stats
end

def giveRandomMoveList(pkmn) #랜덤 기술
	return if !$player.random_move_switch
  movelist = pkmn.species_data.moves
	random_move = [:TERABLAST]
	i = 0
	GameData::Move.each do |s|
		i += 1
		if i < 833
			random_move.push(s.id)
		end
	end
	rmove=random_move.shuffle
	movelist.each do |i|
		i[1] = rmove.pop
  end
	pkmn.random_move_list = movelist
end

def getRandomMoveList(pkmn) #랜덤 기술 반환
	if !pkmn.random_move_list
    giveRandomMoveList(pkmn)
	end
  return pkmn.random_move_list
end



def giveRandomEXMoveList(pkmn) #추가 랜덤 기술
	return if !$player.random_exmove_switch
  movelist = []
	random_move = [:TERABLAST]
	i = 0
	GameData::Move.each do |s|
		i += 1
		if i < 833
			random_move.push(s.id)
		end
	end
	rmove=random_move.shuffle
	exlevel = $player.random_exmove_level || 10
	level = 0
	cnt = 0
	while level<=150
		movelist.push([level, rmove.pop])
		level += exlevel
		cnt += 1
  end
	pkmn.random_exmove_list = movelist
end

def getRandomEXMoveList(pkmn) #추가 랜덤 기술 반환
	return if !$player.random_exmove_switch
	if !pkmn.random_exmove_list
    giveRandomEXMoveList(pkmn)
	end
	checklevel = $player.random_exmove_level || 10
	if pkmn.random_exmove_list.length != 150/checklevel + 1
		giveRandomEXMoveList(pkmn)
	end
  return pkmn.random_exmove_list
end

def getRandomItem(item) #랜덤 아이템 반환(미완)
	return item if item.is_key_item?
	itemlist[]
	if item.is_machine?
    GameData::Item.each do |s|
			itemlist << s if s.is_machine?
		end
	else
		GameData::Item.each do |s|
			itemlist << s if !s.is_machine?
		end
	end
	itemlist.shuffle!
  return itemlist.sample
end

def give_random_pokemon_baby
	pokemon_list = []
	GameData::Species.each do |sp|
    next if sp.get_baby_species != sp.species
    next if sp.flags.include?("Legendary")
    next if sp.flags.include?("Mythical")
    next if sp.flags.include?("UltraBeast")
    next if sp.form != 0
    next if sp.flags.include?("Paradox")
    pokemon_list << sp
  end
	
	shuffled_safe_list = pokemon_list.shuffle
	new_species = :NECROZMA_3 
	if !pokemon_list.empty?
		loop do
			new_species = pokemon_list.sample
			break
		end
	end
	return new_species
end

def getRandomParty #랜덤 파티
	party = []
  species = []
	6.times{species.push(give_random_pokemon(:NECROZMA_3))}
  species.each { |id| party.push(id) if GameData::Species.exists?(id) }
  $player.party.clear
  # Generate Pokémon of each species at level 20
  party.each do |spec|
    pkmn = Pokemon.new(spec, 10)
    $player.party.push(pkmn)
		give_random_ability_guaranteed(pkmn)
		giverandom(pkmn)
		$player.pokedex.register(pkmn)
    $player.pokedex.set_owned(spec)
    pkmn.record_first_moves
  end
end

def getRandomPartybady #랜덤 파티
	party = []
  species = []
	6.times{species.push(give_random_pokemon_baby)}
  species.each { |id| party.push(id) if GameData::Species.exists?(id) }
  $player.party.clear
  # Generate Pokémon of each species at level 20
  party.each do |spec|
    pkmn = Pokemon.new(spec, 10)
    $player.party.push(pkmn)
		give_random_ability_guaranteed(pkmn)
		giverandom(pkmn)
		$player.pokedex.register(pkmn)
    $player.pokedex.set_owned(spec)
    pkmn.record_first_moves
  end
end