#===============================================================================
# 레벨업 시 패시브 특성 각성 시스템
#===============================================================================
# 포켓몬이 레벨업할 때, 일정 확률로 두 번째 특성인 "패시브"를 얻습니다.
#===============================================================================

#-------------------------------------------------------------------------------
# ▼▼▼ 설정 부분 ▼▼▼
#-------------------------------------------------------------------------------
module PassiveAbilitySettings
	WEATHER_PASSIVE = [
		:DROUGHT, :DRIZZLE, :SANDSTREAM, :SNOWWARNING, :AIRLOCK, :CLOUDNINE,
		:PRIMORDIALSEA, :DELTASTREAM, :DESOLATELAND
	]	
	SAME_PASSIVE = [:LIBERO, :PROTEAN]
end
#-------------------------------------------------------------------------------
class Pokemon
  attr_accessor :passive_ability
  # 게임을 로드할 때 패시브 변수가 없으면 nil로 초기화
  alias _initialize_passive initialize
  def initialize(*args)
    _initialize_passive(*args)
    @passive_ability = nil
  end
end

#-------------------------------------------------------------------------------
# 레벨업 시 패시브 각성 함수
#-------------------------------------------------------------------------------
def pbLearnPassiveAbilityOnLevelUp(pkmn)
	return if $player.random_passive_switch == 0 || !$player.random_passive_switch
	return if pkmn.passive_ability && rand(100)+1 > 20 && $player.random_ability_switch != 0 || pkmn.passive_ability && rand(100)+1 > 60 && $player.random_ability_switch ==0 
	return if pkmn.passive_ability && $player.random_passive_switch == 2
	
	passive_pool = (GROUP_A_ABILITIES + GROUP_B_ABILITIES + GROUP_C_ABILITIES).uniq
	
  new_passive = nil
  loop do
		new_passive = passive_pool.sample
		# 둘 다 날씨면 리롤
		next if PassiveAbilitySettings::WEATHER_PASSIVE.include?(new_passive) &&
						PassiveAbilitySettings::WEATHER_PASSIVE.include?(pkmn.ability)
		# 변환자재 리베로 중복시 리롤
		next if PassiveAbilitySettings::SAME_PASSIVE.include?(new_passive) &&
						PassiveAbilitySettings::SAME_PASSIVE.include?(pkmn.ability)
		break if new_passive != pkmn.ability && new_passive != pkmn.passive_ability
  end
	
  return if !new_passive
	
	awakening_messages = [
    _INTL("\\j[{1},이,가] 순간적으로 무언가 깨달은 듯하다!", pkmn.name),
    _INTL("\\j[{1},의,의] 잠재력이 폭발했다!", pkmn.name),
    _INTL("\\j[{1},에게,에게] 새로운 가능성이 눈을 떴다!", pkmn.name)
  ]
  random_message = awakening_messages.sample
	
  new_passive_name = GameData::Ability.get(new_passive).name
  new_passive_desc = GameData::Ability.get(new_passive).description
	
  pbMessage(_INTL("새로운 패시브 「{1}」를 발견했다!", new_passive_name))
  pbMessage(_INTL("<c2=7038F8,ADB5B9>{1}</c2>", new_passive_desc))
	if pkmn.passive_ability
		old_passive_name = GameData::Ability.get(pkmn.passive_ability).name
		if pbConfirmMessage(_INTL("기존의 패시브 「{1}」을(를) 잊고 새로운 패시브 「{2}」을(를) 배우시겠습니까?", old_passive_name, new_passive_name))
			pkmn.passive_ability = new_passive
			pbMessage(_INTL("\\j[{1},의,의] 패시브는 「{2}」이 되었다!", pkmn.name, new_passive_name))
		end
	else
		pkmn.passive_ability = new_passive
	end
end
