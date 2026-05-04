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

class Pokemon
	def evo_count
		@evo_count = 0 if @evo_count.nil?
		return @evo_count
	end
	attr_writer :evo_count
end

class PokemonGlobalMetadata
	attr_accessor :custom_evo_map

	unless method_defined?(:ys_random_evo_map_initialize)
		alias ys_random_evo_map_initialize initialize
	end
	def initialize
		ys_random_evo_map_initialize
		@custom_evo_map ||= { 0 => {}, 1 => {} }
	end
end

def giverandom(pkmn)
	give_random_type(pkmn)
	give_random_stats(pkmn)
	giveRandomMoveList(pkmn)
	giveRandomEXMoveList(pkmn)
end

def give_random_type(pokemon)
	return if !$player.random_type_switch
	return if !pokemon.is_a?(Pokemon)

	random_type_hash = {}
	formcount = 0
	GameData::Species.each do |sp|
		next if sp.species != pokemon.species
		shuffled_list = RANDOM_TYPE_POOL.shuffle
		new_type1 = shuffled_list.sample
		shuffled_list = RANDOM_TYPE_POOL.shuffle
		new_type2 = shuffled_list.sample
		if new_type1 == new_type2 || rand(100) + 1 <= 7
			random_type_hash[formcount] = [new_type1]
		else
			random_type_hash[formcount] = [new_type1, new_type2]
		end
		formcount += 1
	end
	pokemon.random_type = random_type_hash
	pokemon.calc_stats
end

# Random evolution candidate filter. This blocks temporary/battle-only forms
# while still allowing base species and ordinary regional forms.
def pbRandomEvoAllowedSpecies?(sp)
	return false if !sp
	return false if sp.id == :EGG || sp.has_flag?("Egg")
	return false if sp.mega_stone || sp.mega_move
	return false if sp.unmega_form && sp.unmega_form > 0
	id_text = sp.id.to_s.upcase
	form_text = sp.form_name.to_s.upcase
	return false if id_text.include?("GMAX") || id_text.include?("TERA")
	return false if form_text.include?("MEGA") || form_text.include?("GMAX")
	return false if form_text.include?("GIGANTAMAX") || form_text.include?("PRIMAL")
	return false if form_text.include?("TERA")
	return false if sp.form > 2
	return true
end

def pbRandomEvoHasForwardEvolution?(sp)
	return false if !sp
	return sp.get_evolutions(true).length > 0
end

def pbRandomPokemonLegacyCandidate(except_species = nil)
	pokemon_list = []
	GameData::Species.each do |s|
		next if s.form != 0
		next if s.id == :EGG
		pokemon_list << s.id
	end
	pokemon_list = (pokemon_list + ANOTHER_FORM).uniq
	return nil if pokemon_list.empty?
	new_species = :NECROZMA_3
	loop do
		new_species = pokemon_list.sample
		break if new_species != except_species
	end
	return new_species
end

def pbGenerateAllEvolutionRoutes
	return if !$player || $player.random_evo_switch == 0
	return if !$PokemonGlobal
	$PokemonGlobal.custom_evo_map ||= { 0 => {}, 1 => {} }
	return if !$PokemonGlobal.custom_evo_map[0].empty?

	mid_pool = []
	final_pool = []
	GameData::Species.each do |sp|
		next if !pbRandomEvoAllowedSpecies?(sp)
		if pbRandomEvoHasForwardEvolution?(sp)
			mid_pool.push(sp.id)
		else
			final_pool.push(sp.id)
		end
	end
	mid_pool.uniq!
	final_pool.uniq!
	return if mid_pool.empty? || final_pool.empty?

	source_ids = []
	GameData::Species.each do |sp|
		next if !pbRandomEvoAllowedSpecies?(sp)
		source_ids.push(sp.id)
	end
	source_ids.uniq!

	used_mid = []
	used_fin = []
	source_ids.each do |src_id|
		avail_mid = mid_pool - used_mid
		target_mid = avail_mid.empty? ? mid_pool.sample : avail_mid.sample
		next if !target_mid
		$PokemonGlobal.custom_evo_map[0][src_id] = target_mid
		used_mid.push(target_mid)

		avail_fin = final_pool - used_fin
		target_fin = avail_fin.empty? ? final_pool.sample : avail_fin.sample
		next if !target_fin
		$PokemonGlobal.custom_evo_map[1][target_mid] ||= target_fin
		used_fin.push(target_fin)
	end
end

# Random species evolution. Real Pokemon objects use the saved three-stage map;
# legacy callers such as random party generation keep the old one-shot picker.
def give_random_pokemon(pokemon)
	return pbRandomPokemonLegacyCandidate(pokemon) if !pokemon.is_a?(Pokemon)
	return nil if !$player || $player.random_evo_switch == 0
	return nil if !$PokemonGlobal
	$PokemonGlobal.custom_evo_map ||= { 0 => {}, 1 => {} }
	pbGenerateAllEvolutionRoutes if $PokemonGlobal.custom_evo_map[0].empty?
	count = pokemon.evo_count
	return nil if count >= 2
	current_id = pokemon.species_data.id
	return $PokemonGlobal.custom_evo_map[count][current_id]
end

class PokemonEvolutionScene
	unless method_defined?(:ys_three_stage_evo_success)
		alias ys_three_stage_evo_success pbEvolutionSuccess
	end
	def pbEvolutionSuccess
		ys_three_stage_evo_success
		@pokemon.evo_count = (@pokemon.evo_count || 0) + 1 if $player && $player.random_evo_switch != 0
	end
end

EventHandlers.add(:on_player_create, :generate_all_evo_routes, proc {
	pbGenerateAllEvolutionRoutes
})


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
    pokemon_list << sp.id
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
