#===============================================================================
# 야생 배틀 종료 후 랜덤 이벤트 시스템
#===============================================================================
module PostBattleEvents
  # ===================
  # ▼▼▼ 설정 부분 ▼▼▼
  # ===================

  # 전체 이벤트가 발생할 확률 (단위: %)
  EVENT_CHANCE = 10 # 100% 확률로 아래 이벤트 중 하나가 발생합니다.

  # 각 이벤트가 선택될 확률 (모두 더해서 100이 되도록 조절하면 편리합니다)
  EVENT_WEIGHTS = {
    :heal_party => 0,          # 파티 회복 이벤트 확률
    :restore_pp => 0,          # PP 회복 이벤트 확률
    :gain_item  => 0,          # 아이템 획득 이벤트 확률
    :exp_bonus  => 0,          # 경험치 보너스 이벤트 확률
    :unleash_potential => 0,   # 잠재 능력 해방 이벤트 확률
    :find_egg   => 0,          # 알 발견 이벤트 확률
		:random_move_learn => 0  #랜덤 기술
  }
  
# 획득 가능한 아이템 목록을 확장합니다.
  # 여러 번 추가할수록 등장 확률이 올라갑니다.
  ITEM_POOL = [
    # --- 일반 소모품 (등장 확률 높음) ---
    :POTION, :POTION, :SUPERPOTION, :SUPERPOTION,       # 상처약, 좋은상처약
    :POKEBALL, :POKEBALL, :GREATBALL, :GREATBALL,       # 몬스터볼, 수퍼볼
    :ANTIDOTE, :PARALYZEHEAL, :AWAKENING, :BURNHEAL,   # 각종 상태이상 회복약
    :FULLHEAL, :REVIVE,                                 # 만병통치제, 기력의조각

    # --- 고급 소모품 및 특수 볼 ---
    :HYPERPOTION, :MAXPOTION,                           # 고급상처약, 풀회복약
    :ULTRABALL, :QUICKBALL, :DUSKBALL, :TIMERBALL,      # 하이퍼볼, 퀵볼, 다크볼, 타이마볼

    # --- 능력치 및 성장 관련 아이템 ---
    :RARECANDY, :RARECANDY,                             # 이상한사탕 (ID를 RARE_CANDY에서 수정)
    :PPUP,                                              # PP에이드
    :HPUP, :PROTEIN, :IRON, :CALCIUM, :ZINC, :CARBOS,    # 기초 포인트(노력치) 상승 도핑약

    # --- 진화의 돌 및 진화 관련 아이템 ---
    :FIRESTONE, :WATERSTONE, :THUNDERSTONE, :LEAFSTONE, # 불꽃, 물, 천둥, 리프의돌
    :MOONSTONE, :SUNSTONE, :SHINYSTONE, :DUSKSTONE,     # 달, 태양, 빛, 어둠의돌
    :DAWNSTONE, :ICESTONE,                              # 각성, 얼음의돌
    :EVERSTONE, :OVALSTONE,                             # 변함없는돌, 동글동글돌
    :METALCOAT,                                         # 금속코트

    # --- 전투용 지닌 물건 (전략적 다양성) ---
    :LEFTOVERS,                                         # 먹다남은음식
    :SHELLBELL,                                         # 조개껍질방울
    :EXPERTBELT,                                        # 달인의띠
    :CHOICEBAND,                                        # 구애머리띠
    :CHOICESPECS,                                       # 구애안경
    :CHOICESCARF,                                       # 구애스카프
    :LIFEORB,                                           # 생명의구슬
    :FOCUSSASH,                                         # 기합의띠 (스크립트에 효과가 정의되어 있어야 함)
    :ASSAULTVEST,                                       # 돌격조끼
    :ROCKYHELMET,                                       # 울퉁불퉁멧
    :EVIOLITE,                                          # 진화의휘석
    :WEAKNESSPOLICY,                                    # 약점보험
    :AIRBALLOON,                                        # 풍선
    :REDCARD,                                           # 레드카드
    :EJECTBUTTON,                                       # 탈출버튼

    # --- 반감 열매 (전략적 방어) ---
    :OCCABERRY, :PASSHOBERRY, :WACANBERRY, :RINDOBERRY, # 불, 물, 전기, 풀 반감
    :YACHEBERRY, :CHOPLEBERRY, :KEBIABERRY, :SHUCABERRY, # 얼음, 격투, 독, 땅 반감
    :COBABERRY, :PAYAPABERRY, :TANGABERRY, :CHARTIBERRY, # 비행, 에스퍼, 벌레, 바위 반감
    :KASIBBERRY, :HABANBERRY, :COLBURBERRY, :BABIRIBERRY, # 고스트, 드래곤, 악, 강철 반감
    :ROSELIBERRY,                                       # 페어리 반감

    # --- 고가 아이템 (금전적 보상) ---
    :NUGGET, :NUGGET,                                   # 금구슬
    :STARPIECE,                                         # 별의조각
    :COMETSHARD,                                        # 혜성조각
    :BIGPEARL,                                          # 큰진주 (items.dat에 정의되어 있는지 확인 필요)

    # --- 매우 희귀한 아이템 ---
    :PPMAX,                                             # PP맥스
    :ABILITYCAPSULE,                                    # 특성캡슐 (items.dat에 정의되어 있는지 확인 필요)
    :SACREDASH                                          # 성스러운불꽃
  ]

  # ===================
  # ▲▲▲ 설정 부분 ▲▲▲
  # ===================

  # --- 이벤트 관리자 (이 메서드를 외부에서 호출합니다) ---
  def self.run
    # ▼▼▼ 추가된 부분 ▼▼▼
    # 배틀 결과가 '트레이너 승리'가 아닐 경우에만 실행 (즉, 야생 배틀에서 이기거나 잡았을 때만)
    return if $game_variables[1] != 1
    # ▲▲▲ 추가된 부분 ▲▲▲
    return if rand(100) >= EVENT_CHANCE

    total_weight = EVENT_WEIGHTS.values.sum
    roll = rand(total_weight)
    
    chosen_event = nil
    cumulative_weight = 0
    EVENT_WEIGHTS.each do |event, weight|
      cumulative_weight += weight
      if roll < cumulative_weight
        chosen_event = event
        break
      end
    end

    case chosen_event
    when :heal_party
      heal_party_event
    when :restore_pp
      restore_pp_event
    when :gain_item
      gain_item_event
    when :exp_bonus
      exp_bonus_event
    when :unleash_potential
      unleash_potential_event
    when :find_egg
      find_egg_event
		when :random_move_learn
      random_move_learn_event
    end
  end

  # --- 개별 이벤트들 ---

  # 1. 파티 포켓몬 체력 회복 이벤트
  def self.heal_party_event
    num_to_heal = rand(1..$player.party.length)
    healable_pokemon = $player.party.select { |p| !p.fainted? && p.hp < p.totalhp }
    return if healable_pokemon.empty?
    healed_names = []
    healable_pokemon.shuffle.first(num_to_heal).each do |pkmn|
      pkmn.heal
      healed_names.push(pkmn.name)
    end
    if healed_names.length > 0
      pbMessage(_INTL("어디선가 신비한 기운이 느껴지더니..."))
      pbMessage(_INTL("{1}의 기력이 완전히 회복되었다!", healed_names.join(", ")))
    end
  end

  # 2. 사용 기술 PP 회복 이벤트
  def self.restore_pp_event
    pkmn = $player.able_party.sample
    return if !pkmn
    pkmn.moves.each do |move|
      move.pp = move.total_pp
    end
    pbMessage(_INTL("배틀의 열기가 가라앉자 {1}의 집중력이 올랐다!", pkmn.name))
    pbMessage(_INTL("{1}이 배운 모든 기술의 PP가 회복되었다.", pkmn.name))
  end

  # 3. 아이템 획득 이벤트
  def self.gain_item_event
    item = ITEM_POOL.sample
    return if !item
    item_name = GameData::Item.get(item).name
    if $bag.add(item)
      pbMessage(_INTL("포켓몬이 무언가를 발견했다!"))
      pbMessage(_INTL("\\se[Item get]{1}(을)를 손에 넣었다!", item_name))
    end
  end

  # 4. 포켓몬 경험치 보너스 이벤트
  def self.exp_bonus_event
    pkmn = $player.able_party.sample
    return if !pkmn
    exp_gain = pkmn.level * 10
    pbMessage(_INTL("놀랍게도 {1}의 경험치가 올랐다!", pkmn.name))
    pkmn.exp += exp_gain
    pbMessage(_INTL("{1}은 {2}의 경험치를 얻었다!", pkmn.name, exp_gain))
  end

  # 5. 잠재 능력 해방 이벤트
  def self.unleash_potential_event
    pkmn = $player.able_party.sample
    return if !pkmn
    boost_stat = [:ATTACK, :DEFENSE, :SPEED].sample
    
    # ▼▼▼ [수정된 부분] 효과를 포켓몬에게 저장합니다. ▼▼▼
    pkmn.unleashed_potential_stat = boost_stat
    # ▲▲▲ [수정된 부분] ▲▲▲
    
    pbMessage(_INTL("배틀이 끝난 후 {1}의 몸에서 빛이 났다!", pkmn.name))
    pbMessage(_INTL("{1}의 {2} 능력이 다음 배틀에서 상승한다!", pkmn.name, GameData::Stat.get(boost_stat).name))
  end

# 6. 알 발견 이벤트 (변수 이름 오류 수정)
  def self.find_egg_event
    # 1. 진화의 '결과물'이 되는 모든 포켓몬의 목록을 만듭니다.
    all_prevo_species = []
    GameData::Species.each do |s|
      next if s.nil?
      s.evolutions.each { |evo| all_prevo_species.push(evo[0]) }
    end
    all_prevo_species.uniq!

    # 2. 후보 포켓몬을 담을 빈 배열을 만듭니다.
    egg_pool = []
    GameData::Species.each do |s|
      next if s.nil? || s.form > 0
      
      # ▼▼▼ [수정된 부분] 잘못된 변수 이름을 올바르게 수정했습니다. ▼▼▼
      is_base_form = !all_prevo_species.include?(s.id)
      # ▲▲▲ [수정된 부분] ▲▲▲

      in_valid_egg_group = !s.egg_groups.include?(:Undiscovered)
      is_not_banned = ![:DITTO].include?(s.id) && !s.id.to_s.start_with?("UNOWN")
      if is_base_form && in_valid_egg_group && is_not_banned
        egg_pool.push(s.id)
      end
    end

    egg_species_id = egg_pool.sample
    return if !egg_species_id
    
    egg = Pokemon.new(egg_species_id, 1)
    egg.name = _INTL("알")
    egg.steps_to_hatch = GameData::Species.get(egg_species_id).hatch_steps

    pbMessage(_INTL("야생 포켓몬이 무언가를 떨어뜨리고 갔다!"))
    
    # PC 저장이 가장 안정적으로 작동했던 내장 함수를 사용합니다.
    pbAddPokemon(egg)
  end
	
	def self.random_move_learn_event
    pkmn = $player.able_party.sample
    #랜덤 기술 습득
		random_move = [:TERABLAST]
		i = 0
		GameData::Move.each do |s|
			i += 1
			if i < 833
				id_string = s.id.to_s
				random_move.push(s.id)
			end
		end
		rmove=random_move.sample
    pbMessage(_INTL("{1}가 배틀을 통해 새로운 기술을 깨달았다!", pkmn.name))
		pbLearnMove(pkmn, rmove, true)
  end
end