def pokemonFusion(pkmn, material)
	pkmn.fusion = [] if !pkmn.fusion
	pkmn.fusion.push(material.speciesName)
	
	materialStats = material.baseStats
	i =0
	pkmn.fusion_stat = [0,0,0,0,0,0] if !pkmn.fusion_stat
	materialStats.each_value { |s|
		if pkmn.fusion.length < 5
			pkmn.fusion_stat[i] += s/5
		else
			pkmn.fusion_stat[i] += s/10
		end
		i+=1
	}
	
	pkmn.iv.each_key do |stat|
		pkmn.iv[stat] = material.iv[stat] if pkmn.iv[stat] < material.iv[stat]
	end
	
	pkmn.fusion_move = [] if !pkmn.fusion_move
	pkmn.fusion_move += material.getMoveList if pkmn.fusion.length < 5
	pkmn.fusion += material.fusion if material.fusion
	
	new_ability_name = GameData::Ability.get(material.ability).name
	old_ability_name = GameData::Ability.get(pkmn.ability).name
	if pbConfirmMessage(_INTL("기존의 특성 「{1}」을(를) 잊고 소재의 특성 「{2}」을(를) 배우시겠습니까?", old_ability_name, new_ability_name))
		pkmn.ability = material.ability
		pkmn.random_ability_list[pkmn.form] = pkmn.ability if pkmn.random_ability_list.length > 0
	end
	
	if material.passive_ability && pkmn.passive_ability
		new_ability_name = GameData::Ability.get(material.passive_ability).name
		old_ability_name = GameData::Ability.get(pkmn.passive_ability).name
		if pbConfirmMessage(_INTL("기존의 패시브 「{1}」을(를) 잊고 소재의 패시브 「{2}」을(를) 배우시겠습니까?", old_ability_name, new_ability_name))
			pkmn.passive_ability = material.passive_ability
		end
	elsif material.passive_ability && !pkmn.passive_ability
		pkmn.passive_ability = material.passive_ability
	end
end

def pokemonFusionNP(pkmn, material)
	pkmn.fusion = [] if !pkmn.fusion
	pkmn.fusion.push(material.speciesName)
	pkmn.fusion += material.fusion if material.fusion
	
	materialStats = material.baseStats
	i =0
	pkmn.fusion_stat = [0,0,0,0,0,0] if !pkmn.fusion_stat
	materialStats.each_value { |s| 
		pkmn.fusion_stat[i] += s/5
		i+=1
	}
	
	pkmn.iv.each_key do |stat|
		pkmn.iv[stat] = material.iv[stat] if pkmn.iv[stat] < material.iv[stat]
	end
	
	pkmn.fusion_move = [] if !pkmn.fusion_move
	pkmn.fusion_move += material.getMoveList
	
	new_ability_name = GameData::Ability.get(material.ability).name
	old_ability_name = GameData::Ability.get(pkmn.ability).name
	if rand(10) < 7
		pkmn.ability = material.ability
		pkmn.random_ability_list[pkmn.form] = pkmn.ability if pkmn.random_ability_list.length > 0
	end
end

def FusionName(pkmn)
	return if !pkmn.fusion
	fusionname = pkmn.name.to_s[0,2]
	
	i=0
	if pkmn.fusion.size > 2
		2.times do
			fusionname = fusionname+pkmn.fusion[i].to_s[-2,2]
			i+=1
		end
	else
		pkmn.fusion.size.times do
			fusionname = fusionname+pkmn.fusion[i].to_s[-2,2]
			i+=1
		end
	end
	pkmn.name = fusionname
end
