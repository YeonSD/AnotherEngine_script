#===============================================================================
# Trainer class for the player
#===============================================================================
class Player < Trainer
  # 랜덤 포켓몬 확률
  attr_accessor	:random_pokemon_switch
	# 랜덤 특성 on/off
  attr_accessor	:random_ability_switch
	# 랜덤 패시브 on/off
  attr_accessor	:random_passive_switch
	# 랜덤 타입 on/off
  attr_accessor	:random_type_switch
	# 랜덤 진화 on/off
  attr_accessor	:random_evo_switch
	# 랜덤 진화 on/off
  attr_accessor	:random_evo_allow
	# 랜덤 진화 레벨
  attr_accessor	:random_evo_level
	# 랜덤 기술 on/off
  attr_accessor	:random_move_switch
	# 랜덤 기술 on/off
  attr_accessor	:random_exmove_switch
	# 랜덤 기술 습득 레벨
  attr_accessor	:random_exmove_level
	# 랜덤 종족값 on/off
  attr_accessor	:random_stats_switch
  # 랜덤 포켓몬 확률
  attr_accessor	:random_pokemon_switch2
	# 랜덤 특성 on/off
  attr_accessor	:random_ability_switch2
	# 랜덤 패시브 on/off
  attr_accessor	:random_passive_switch2
	# 랜덤 타입 on/off
  attr_accessor	:random_type_switch2
	# 랜덤 기술 on/off
  attr_accessor	:random_move_switch2
	# 랜덤 종족값 on/off
  attr_accessor	:random_stats_switch2
  # 랜덤 아이템 on/off
  attr_accessor :random_item_switch
	# 랜덤 강화
  attr_accessor	:super_random
	# 메진 유지 여부
  attr_accessor	:always_mega
	# 포켓몬 융합
  attr_accessor	:fusion_switch
	# 야생 포켓몬 융합
  attr_accessor	:wild_fusion_switch
	# 트레이너 포켓몬 융합
  attr_accessor	:trainer_fusion_switch
  # @return [Integer] the character ID of the player
  attr_reader   :character_ID
  # @return [Integer] the player's outfit
  attr_reader   :outfit
  # @return [Array<Boolean>] the player's Gym Badges (true if owned)
  attr_accessor :badges
  # @return [Integer] the player's money
  attr_reader   :money
  # @return [Integer] the player's Game Corner coins
  attr_reader   :coins
  # @return [Integer] the player's battle points
  attr_reader   :battle_points
  # @return [Integer] the player's soot
  attr_reader   :soot
  # @return [Pokedex] the player's Pokédex
  attr_reader   :pokedex
  # @return [Boolean] whether the Pokédex has been obtained
  attr_accessor :has_pokedex
  # @return [Boolean] whether the Pokégear has been obtained
  attr_accessor :has_pokegear
  # @return [Boolean] whether the player has running shoes (i.e. can run)
  attr_accessor :has_running_shoes
  # @return [Boolean] whether the player has an innate ability to access Pokémon storage
  attr_accessor :has_box_link
  # @return [Boolean] whether the creator of the Pokémon Storage System has been seen
  attr_accessor :seen_storage_creator
  # @return [Boolean] whether the effect of Exp All applies innately
  attr_accessor :has_exp_all
  # @return [Boolean] whether Mystery Gift can be used from the load screen
  attr_accessor :mystery_gift_unlocked
  # @return [Array<Array>] downloaded Mystery Gift data
  attr_accessor :mystery_gifts

  def initialize(name, trainer_type)
    super
    @character_ID          = 0
    @outfit                = 0
    @badges                = [false] * 8
    @money                 = GameData::Metadata.get.start_money
    @coins                 = 0
    @battle_points         = 0
    @soot                  = 0
    @pokedex               = Pokedex.new
    @has_pokedex           = false
    @has_pokegear          = false
    @has_running_shoes     = false
    @has_box_link          = false
    @seen_storage_creator  = false
    @has_exp_all           = false
    @mystery_gift_unlocked = false
    @mystery_gifts         = []
		@random_evo_switch			= 0
		@random_evo_allow			= false
		@random_pokemon_switch = false
		@random_ability_switch	= 0
		@random_passive_switch	= 0
		@random_type_switch			= false
		@random_move_switch			= false
		@random_exmove_switch		= false
		@random_exmove_level		= 10
		@random_evo_level  			= 1
		@always_mega						= 0
		@random_stats_switch		= 0
		@random_pokemon_switch2 = false
		@random_ability_switch2	= false
		@random_passive_switch2	= false
		@random_type_switch2		= false
		@random_move_switch2		= false
		@random_stats_switch2		= false
		@super_random		= false
		@fusion_switch					= false
		@wild_fusion_switch			= false
		@trainer_fusion_switch	= false
  end

  #=============================================================================

  def character_ID=(value)
    return if @character_ID == value
    @character_ID = value
    $game_player&.refresh_charset
  end

  def outfit=(value)
    return if @outfit == value
    @outfit = value
    $game_player&.refresh_charset
  end

  def trainer_type
    return GameData::PlayerMetadata.get(@character_ID || 1).trainer_type
  end

  # Sets the player's money. It can not exceed {Settings::MAX_MONEY}.
  # @param value [Integer] new money value
  def money=(value)
    validate value => Integer
    @money = value.clamp(0, Settings::MAX_MONEY)
  end

  # Sets the player's coins amount. It can not exceed {Settings::MAX_COINS}.
  # @param value [Integer] new coins value
  def coins=(value)
    validate value => Integer
    @coins = value.clamp(0, Settings::MAX_COINS)
  end

  # Sets the player's Battle Points amount. It can not exceed
  # {Settings::MAX_BATTLE_POINTS}.
  # @param value [Integer] new Battle Points value
  def battle_points=(value)
    validate value => Integer
    @battle_points = value.clamp(0, Settings::MAX_BATTLE_POINTS)
  end

  # Sets the player's soot amount. It can not exceed {Settings::MAX_SOOT}.
  # @param value [Integer] new soot value
  def soot=(value)
    validate value => Integer
    @soot = value.clamp(0, Settings::MAX_SOOT)
  end

  # @return [Integer] the number of Gym Badges owned by the player
  def badge_count
    return @badges.count { |badge| badge == true }
  end

  #=============================================================================

  # (see Pokedex#seen?)
  # Shorthand for +self.pokedex.seen?+.
  def seen?(species)
    return @pokedex.seen?(species)
  end

  # (see Pokedex#owned?)
  # Shorthand for +self.pokedex.owned?+.
  def owned?(species)
    return @pokedex.owned?(species)
  end
end
