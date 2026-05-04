def give_random_ability_trainer(pkmn)
	return if !$player.random_ability_switch2
  return if !pkmn.is_a?(Pokemon)
  
  triner_pool = TRAINER_ABILITIES
	
	ret = 0
	baseStats = pkmn.baseStats
	baseStats.each_value { |s| ret += s }
	
	if rand(10)<1 && ret <450 && !$player.super_random
		triner_pool += GameData::Ability.keys
		triner_pool.reject! { |move| FORM_CHANGE_ABILITIES.include?(move) }
	elsif rand(10)<4 && ret <500 && !$player.super_random
		triner_pool += GROUP_C_ABILITIES
	end
  return if triner_pool.empty?
	
	GameData::Species.each do |sp|
    next if sp.species != pkmn.species
		new_ability = triner_pool.sample
    pkmn.random_ability_list.push(new_ability)
  end
	pkmn.ability = pkmn.random_ability_list[pkmn.form]
end

#랜덤 트레이너 포켓몬
def triner_random_pokemon(pokemon)
	pokemon_list = []
	
	base = 0
	baseStats = GameData::Species.get(pokemon.species).base_stats
	baseStats.each_value { |s| base += s }
	base += 30 if $player.super_random
	
	GameData::Species.each do |s|
		next if s.form != 0
		next if s.id == :EGG
		sta = 0
		baseStats = GameData::Species.get(s.species).base_stats
		baseStats.each_value { |stat| sta += stat }
		pokemon_list << s if sta >= 450
		next if $player.super_random && rand < 0.50
		pokemon_list << s
	end
	safe_pokemon_list = pokemon_list+POWER_POKEMON+ANOTHER_FORM_TRAINER
	shuffled_safe_list = safe_pokemon_list.shuffle
	new_species = :NECROZMA_3 
	if !safe_pokemon_list.empty?
		loop do
			new_species = shuffled_safe_list.sample
			ret = 0
			baseStats = GameData::Species.get(new_species).base_stats
			baseStats.each_value { |s| ret += s }
			break if ret >= base - 70
		end
	end
  if pokemon.level >= 30
    new_species = new_species.id if new_species.is_a?(GameData::Species)
    
    loop do
      evos = GameData::Species.get(new_species).get_evolutions(true)
      break if evos.empty? # 더 이상 진화할 수 없으면 (최종 폼이면) 스톱
      new_species = evos.sample[0] # 진화체가 있으면 덮어씌우고 다시 확인
    end
  end
	return new_species
end

def random_stats_trainer(pkmn) #랜덤 종족값
	return if !$player.random_stats_switch2
  return if !pkmn.is_a?(Pokemon)
	random_stats_hash = {}
	formcount=0
	GameData::Species.each do |sp|
    next if sp.species != pkmn.species
		
		ret = 0
		baseStats = GameData::Species.get(sp.species).base_stats
		baseStats.each_value { |s| ret += s }
		totalStats = ret/2 + rand(851-ret/2)
		if $player.random_stats_switch == 1
			totalStats = ret-30
		elsif $player.random_stats_switch == 2
			totalStats = ret*(80+rand(121))/100.0 - 30
		end
		totalStats *= 1.3 if $player.super_random
		totalStats = totalStats.round
		randomStats = [5,5,5,5,5,5]
		i=0
		while totalStats > 0
			rstat = rand(120) + 1
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
		if $player.random_stats_switch == 3
			randomStats = []
			baseStats = GameData::Species.get(sp.species).base_stats
			baseStats.each_value { |s|
				stat = ret/4.0*(80+rand(81))/100.0
				stat = stat.round
				randomStats << stat
			}
		end
		randomStats.shuffle!
		random_stats_hash[formcount] = randomStats
		formcount+=1
  end
  pkmn.random_stats = random_stats_hash
	pkmn.calc_stats
end

RANDOM_ITEM = [
	:COVERTCLOAK,:ROCKYHELMET,:LEFTOVERS,:FOCUSSASH,:LIFEORB,:EXPERTBELT,:SITRUSBERRY,
	:LAXINCENSE,:BRIGHTPOWDER,:KINGSROCK,:WHILTEHERB,:ASSAULTVEST,:SCOPELENS,:METRONOME,
	:CLEARARMULET,:QUICKCLAW,:LUMBERRY,:CHOICESCARF,
].uniq

#트레이너 도구 변경
def triner_random_item(pkmn)
	return if !pkmn.item && !$player.super_random
	bestpower=0
	besttype=:NORMAL
	bestcategory=0
	pkmn.moves.each do |move|
		if bestpower<move.power
			bestpower = move.power
			besttype = move.type
			bestcategory = move.category
		end
   end
	if pkmn.item.to_s.include?("IUMZ")#z크리스탈 대체
		case besttype
		when :NORMAL
			besttype = :NORMALIUMZ
		when :FIRE
			besttype = :FIRIUMZ
		when	:WATER
			besttype = :WATERIUMZ
		when	:ELECTRIC
			besttype = :ELECTRIUMZ
		when	:GRASS
			besttype = :GRASSIUMZ
		when	:ICE
			besttype = :ICIUMZ
		when	:FIGHTING
			besttype = :FIGHTINIUMZ
		when	:POISON
			besttype = :POISONIUMZ
		when	:GROUND
			besttype = :GROUNDIUMZ
		when	:FLYING
			besttype = :FLYINIUMZ
		when	:PSYCHIC
			besttype = :PSYCHIUMZ
		when	:BUG
			besttype = :BUGINIUMZ
		when	:ROCK
			besttype = :ROCKIUMZ
		when	:GHOST
			besttype = :GHOSTIUMZ
		when	:DRAGON
			besttype = :DRAGONIUMZ
		when	:DARK
			besttype = :DARKINIUMZ
		when	:STEEL
			besttype = :STEELIUMZ
		when	:FAIRY
			besttype = :FAIRIUMZ
		end
		pkmn.item = besttype
		return
	end
	
	item_list = RANDOM_ITEM.shuffle
	
	case pkmn
	when :KYOGRE
		item_list.push(:BLUEORB)
	when :GROUDON
		item_list.push(:REDORB)
	when :ZACIAN
		item_list.push(:RUSTEDSWORD)
	when :ZAMAZENTA
		item_list.push(:RUSTEDSHIELD)
	end
	
	if pkmn.ability = :MARVELSCALE || pkmn.passive_ability = :MARVELSCALE || pkmn.ability = :GUTS || pkmn.passive_ability = :GUTS
		item_list.push(:FLAMEORB)
	end
		
	if pkmn.type1 != :FLYING && pkmn.type2 != :FLYING &&  pkmn.ability != :LEVITATE && pkmn.passive_ability != :LEVITATE
		item_list.push(:AIRBALLOON)
	end
	
	if pkmn.ability == :POISONHEAL || pkmn.passive_ability == :POISONHEAL
		pkmn.item = :TOXICORB
	end
	
	case bestcategory
	when 0
		item_list.push(:MUSCLEBAND)
		item_list.push(:CHOICEBAND)
	when 1
		item_list.push(:WISEGLASSES)
		item_list.push(:CHOICESPECS)
	end
	pkmn.item = item_list.sample
end

def giveRandomMoveList_Trainer(pkmn) #랜덤 기술
	return if !$player.random_move_switch
  movelist = pkmn.species_data.moves
	random_move = [:TERABLAST]
	high = 3
	if pkmn.attack > pkmn.spatk + 40
		high = 0
	elsif pkmn.spatk > pkmn.attack + 40
		high = 1
	end
	i = 0
	GameData::Move.each do |s|
		i += 1
		if i < 833
			next if s.category == 0 && high = 1 && rand(10)<8
			next if s.category == 1 && high = 0 && rand(10)<8
			random_move.push(s.id)
		end
	end
	i = 0
	GameData::Move.each do |s|
		i += 1
		if i < 833 && s.power >= 65 && s.power != 150
			next if s.category == 0 && high = 1
			next if s.category == 1 && high = 0
			random_move.push(s.id)
		end
	end
	random_move.push(:HORNDRILL)
	random_move.push(:GUILLOTINE)
	random_move.push(:FISSURE)
	random_move.push(:SHEERCOLD)
	
	random_move.reject! { |move| TO_REMOVE_MOVE.include?(move) }
	
	random_move += TO_ADD_MOVE
	
	if high = 0
		random_move.reject! { |move| SATK_MOVE.include?(move) }
	end
	if high = 1
		random_move.reject! { |move| ATK_MOVE.include?(move) }
	end
	
	rmove=random_move.shuffle
	movelist.each do |i|
		i[1] = rmove.pop
  end
	
	pkmn.random_move_list = movelist
end