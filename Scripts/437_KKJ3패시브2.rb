#===============================================================================
# 패시브 특성 전투 적용 스크립트 (최종 완성본)
#===============================================================================
# 이 스크립트는 게임에 존재하는 거의 모든 종류의 특성 발동 시점을 예측하고,
# 전투 로직과 UI 표시를 포함한 모든 부분을 수정하여 패시브가 완벽하게
# 작동하도록 보장하는 최종 버전입니다.
#
# ★★★ 중요 ★★★
# 이전에 추가했던 모든 '패시브 전투 적용 로직' 관련 스크립트는 삭제하고,
# 반드시 이 스크립트 하나만 사용해주세요.
#===============================================================================

#-------------------------------------------------------------------------------
# 섹션 1: 패시브의 존재를 게임에 알리는 핵심 기반
# 이 함수들은 게임의 모든 부분이 패시브의 존재를 인식하게 만듭니다.
#-------------------------------------------------------------------------------
class Battle::Battler
  # --- 1-1. 패시브를 포함한 특성 존재 여부 확인 (hasActiveAbility?) ---
  alias _passive_original_hasActiveAbility? hasActiveAbility?
  def hasActiveAbility?(check_ability, ignore_fainted = false)
    return true if _passive_original_hasActiveAbility?(check_ability, ignore_fainted)
    passive = self.pokemon&.passive_ability
    return false if !passive
    return false if fainted? && !ignore_fainted
    return false if @effects[PBEffects::GastroAcid]
    if !@battle.moldBreaker
      @battle.allBattlers.each do |b|
        next if b.index == self.index
        if b.ability == :NEUTRALIZINGGAS && self.ability != :NEUTRALIZINGGAS
          return false
        end
      end
    end
    if check_ability.is_a?(Array)
      return true if check_ability.include?(passive)
    else
      return true if passive == check_ability
    end
    return false
  end

  # --- 1-2. '틀깨기' 패시브 확인 ---
  alias _passive_original_hasMoldBreaker? hasMoldBreaker?
  def hasMoldBreaker?
    return true if _passive_original_hasMoldBreaker?
    return self.hasActiveAbility?([:MOLDBREAKER, :TERAVOLT, :TURBOBLAZE])
  end
end

#-------------------------------------------------------------------------------
# 섹션 2: 패시브 발동을 위한 통합 모듈 (전투 로직)
# 게임의 모든 특성 발동 시점에 끼어들어 패시브를 추가로 실행합니다.
#-------------------------------------------------------------------------------
module PassiveAbilityTriggers
  # 특성 컨텍스트를 임시로 변경하기 위한 헬퍼 메서드
  # KKJ패시브2 스크립트의 기존 with_passive_context 함수를 이걸로 교체

# 특성 컨텍스트를 임시로 변경하기 위한 헬퍼 메서드 [최종 완성 버전]
def with_passive_context(battler, passive_id, &block)
  return if !battler || !passive_id

  original_ability_id = battler.ability_id
  # '임시 통행증'을 사용하므로 포켓몬 원본의 ability_id는 건드리지 않습니다.

  begin
    # 전투원 정보와 '임시 통행증'에 패시브 특성을 기록합니다.
    battler.ability = passive_id
    battler.pokemon.ability_override = passive_id if battler.pokemon

    yield # 특성 효과 발동

  ensure
    # 끝난 후에는 원래대로 되돌립니다.
    battler.ability = original_ability_id
    # '임시 통행증'을 비워서 원래 특성을 읽도록 합니다.
    battler.pokemon.ability_override = nil if battler.pokemon
  end
end
  # --- 각 발동 시점별 처리 ---
  
  def triggerOnSwitchIn(ability, battler, battle, switch_in = false)
    # ▼▼▼ [추가된 부분] 잠재 능력 해방 효과 적용 로직 ▼▼▼
    if battler.pokemon.unleashed_potential_stat
      stat_to_boost = battler.pokemon.unleashed_potential_stat
      if battler.pbCanRaiseStatStage?(stat_to_boost, battler)
        stat_name = GameData::Stat.get(stat_to_boost).name
        battle.pbDisplay(_INTL("{1}의 잠재 능력이 해방되어 {2}이 올랐다!", battler.pbThis, stat_name))
        battler.pbRaiseStatStage(stat_to_boost, 1, battler)
        # 효과를 한 번 사용했으므로 초기화하여 다시 발동하지 않게 합니다.
        battler.pokemon.unleashed_potential_stat = nil
      end
    end
    # ▲▲▲ [추가된 부분] ▲▲▲
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnSwitchIn[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::OnSwitchIn.trigger(passive_id, battler, battle, switch_in) }
    end
  end

  def triggerDamageCalcFromUser(ability, user, target, move, mults, power, type)
    super # 기존 특성 로직을 먼저 실행합니다.
    passive_id = user.pokemon&.passive_ability

    return if !passive_id || !user.abilityActive? || passive_id == ability

    # 적응력
    if passive_id == :ADAPTABILITY && user.pbHasType?(move.type)
			mults[:power_multiplier] /= 1.5
			mults[:power_multiplier] *= 2.0
			return
    # 테크니션
    elsif passive_id == :TECHNICIAN
      move_data = GameData::Move.get(move.id)
      base_power = move_data.base_damage
      if move.respond_to?(:pbBaseDamage)
        base_power = move.pbBaseDamage(base_power, user, target)
      end
      if base_power && base_power > 0 && base_power <= 60
        # ▼▼▼ [수정된 부분] 배율 값이 nil일 경우를 대비해 1.0으로 초기화합니다. ▼▼▼
        mults[:power_multiplier] ||= 1.0
        # ▲▲▲ [수정된 부분] ▲▲▲
        mults[:power_multiplier] *= 1.5
				return
      end
    end

    # 위에서 처리되지 않은 다른 종류의 패시브들을 위한 기존 로직
    if Battle::AbilityEffects::DamageCalcFromUser[passive_id]
      with_passive_context(user, passive_id) do
        Battle::AbilityEffects::DamageCalcFromUser.trigger(passive_id, user, target, move, mults, power, type)
      end
    end
  end
	
	def triggerOnSwitchIn(ability, battler, battle, switch_in = false)
    # ▼▼▼ [추가된 부분] 잠재 능력 해방 효과 적용 로직 ▼▼▼
    if battler.pokemon.unleashed_potential_stat
      stat_to_boost = battler.pokemon.unleashed_potential_stat
      if battler.pbCanRaiseStatStage?(stat_to_boost, battler)
        stat_name = GameData::Stat.get(stat_to_boost).name
        battle.pbDisplay(_INTL("{1}의 잠재 능력이 해방되어 {2}이 올랐다!", battler.pbThis, stat_name))
        battler.pbRaiseStatStage(stat_to_boost, 1, battler)
        # 효과를 한 번 사용했으므로 초기화하여 다시 발동하지 않게 합니다.
        battler.pokemon.unleashed_potential_stat = nil
      end
    end
    # ▲▲▲ [추가된 부분] ▲▲▲
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnSwitchIn[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::OnSwitchIn.trigger(passive_id, battler, battle, switch_in) }
    end
  end

  def triggerDamageCalcFromAlly(ability, user, target, move, mults, power, type)
    super # 기존 특성 로직을 먼저 실행합니다.
    passive_id = user.pokemon&.passive_ability

    return if !passive_id || !user.abilityActive? || passive_id == ability

    show_splash = false
    applied_passive = nil

    # 애니메이션 발동 부분
    if show_splash
      original_ability = user.ability
      user.ability = applied_passive
      user.battle.pbShowAbilitySplash(user, true, false)
      user.battle.pbHideAbilitySplash(user)
      user.ability = original_ability
      return
    end

    # 위에서 처리되지 않은 다른 종류의 패시브들을 위한 기존 로직
    if Battle::AbilityEffects::DamageCalcFromAlly[passive_id]
      with_passive_context(user, passive_id) do
        Battle::AbilityEffects::DamageCalcFromAlly.trigger(passive_id, user, target, move, mults, power, type)
      end
    end
  end
	
	
  def triggerDamageCalcFromTarget(ability, user, target, move, mults, power, type)#피격시 데미지 경감
    super
    passive_id = target.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !target.abilityActive?
    if Battle::AbilityEffects::DamageCalcFromTarget[passive_id]
      with_passive_context(target, passive_id) { Battle::AbilityEffects::DamageCalcFromTarget.trigger(passive_id, user, target, move, mults, power, type) }
    end
  end
	
	def triggerDamageCalcFromTargetNonIgnorable(ability, user, target, move, mults, power, type)#피격시 데미지 경감
    super
    passive_id = target.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !target.abilityActive?
    if Battle::AbilityEffects::DamageCalcFromTargetNonIgnorable[passive_id]
      with_passive_context(target, passive_id) { Battle::AbilityEffects::DamageCalcFromTargetNonIgnorable.trigger(passive_id, user, target, move, mults, power, type) }
    end
  end
	
	def triggerDamageCalcFromTargetAlly(ability, user, target, move, mults, power, type)#피격시 데미지 경감(팀)
    super
		ablityuse = user
		user.allAllies.each do |b|
      next if !Battle::AbilityEffects::AccuracyCalcFromAlly[b.pokemon&.passive_ability]
      ablityuse = b.pokemon
    end
    passive_id = ablityuse.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !ablityuse.abilityActive?
    if Battle::AbilityEffects::DamageCalcFromTargetAlly[passive_id]
      with_passive_context(target, passive_id) { Battle::AbilityEffects::DamageCalcFromTargetAlly.trigger(passive_id, user, target, move, mults, power, type) }
    end
  end
	
	def triggerAccuracyCalcFromUser(ability, mods, user, target, move, type)#명중률
    super
    passive_id = user.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !user.abilityActive?
    if Battle::AbilityEffects::AccuracyCalcFromUser[passive_id]
      with_passive_context(user, passive_id) { Battle::AbilityEffects::AccuracyCalcFromUser.trigger(passive_id, mods, user, target, move, type) }
    end
  end
	
	def triggerAccuracyCalcFromTarget(ability, mods, user, target, move, type)#명중률
    super
    passive_id = target.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !target.abilityActive?
    if Battle::AbilityEffects::AccuracyCalcFromTarget[passive_id]
      with_passive_context(target, passive_id) { Battle::AbilityEffects::AccuracyCalcFromTarget.trigger(passive_id, mods, user, target, move, type) }
    end
  end
	
	
	def triggerAccuracyCalcFromAlly(ability, mods, user, target, move, type)#명중률
    super
		ablityuse = user
		user.allAllies.each do |b|
      next if !Battle::AbilityEffects::AccuracyCalcFromAlly[b.pokemon&.passive_ability]
      ablityuse = b.pokemon
    end
    passive_id = ablityuse.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !ablityuse.abilityActive?
    if Battle::AbilityEffects::AccuracyCalcFromAlly[passive_id]
      with_passive_context(user, passive_id) { Battle::AbilityEffects::AccuracyCalcFromAlly.trigger(passive_id, mods, user, target, move, type) }
    end
  end
	
  def triggerEndOfRoundEffect(ability, battler, battle) #턴종시
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::EndOfRoundEffect[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::EndOfRoundEffect.trigger(passive_id, battler, battle) }
    end
  end
	
	def triggerEndOfRoundWeather(ability, weather, battler, battle) #턴종시 날씨 관련
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::EndOfRoundWeather[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::EndOfRoundWeather.trigger(passive_id, battler, battle) }
    end
  end
	
	def triggerEndOfRoundGainItem(ability, battler, battle) #턴종시 아이템
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::EndOfRoundGainItem[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::EndOfRoundGainItem.trigger(passive_id, battler, battle) }
    end
  end
	
	def triggerTrappingByTarget(ability, switcher, bearer, battle) #교체 불가
    return true if super
    passive_id = bearer.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !bearer.abilityActive?
    if Battle::AbilityEffects::TrappingByTarget[passive_id]
      with_passive_context(bearer, passive_id) { Battle::AbilityEffects::TrappingByTarget.trigger(passive_id, switcher, bearer, battle) }
    end
		return false
  end

  def triggerSpeedCalc(ability, battler, mult)
    mult_from_ability = super
    passive_id = battler.pokemon&.passive_ability
    return mult_from_ability if !passive_id || passive_id == ability || !battler.abilityActive?
    mult_from_passive = trigger(Battle::AbilityEffects::SpeedCalc, passive_id, battler, mult, ret: mult)
    return [mult_from_ability, mult_from_passive].max
  end

  def triggerOnEndOfUsingMove(ability, user, targets, move, battle)
    super
    passive_id = user.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !user.abilityActive?
    if Battle::AbilityEffects::OnEndOfUsingMove[passive_id]
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      return if numFainted == 0
      with_passive_context(user, passive_id) { Battle::AbilityEffects::OnEndOfUsingMove.trigger(passive_id, user, targets, move, battle) }
    end
  end
	
	def triggerAfterMoveUseFromTarget(ability, target, user, move, switched_battlers, battle)
    super
    passive_id = target.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !target.abilityActive?
    if Battle::AbilityEffects::AfterMoveUseFromTarget[passive_id]
      with_passive_context(target, passive_id) { Battle::AbilityEffects::AfterMoveUseFromTarget.trigger(passive_id, target, user, move, switched_battlers, battle) }
    end
  end

  def triggerOnBeingHit(ability, user, target, move, battle)#피격시
    super
    passive_id = target.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !target.abilityActive?
    if Battle::AbilityEffects::OnBeingHit[passive_id]
      with_passive_context(target, passive_id) { Battle::AbilityEffects::OnBeingHit.trigger(passive_id, user, target, move, battle) }
    end
  end
	
	def triggerOnDealingHit(ability, user, target, move, battle)#공격시
    super
    passive_id = user.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || ! user.abilityActive?
    if Battle::AbilityEffects::OnDealingHit[passive_id]
      with_passive_context(user, passive_id) { Battle::AbilityEffects::OnDealingHit.trigger(passive_id, user, target, move, battle) }
    end
  end
	

  def triggerMoveImmunity(ability, user, target, move, type, battle, show_message)#기술 면역
    return true if super
    passive_id = target.pokemon&.passive_ability
    return false if !passive_id || passive_id == ability || !target.abilityActive?
    if Battle::AbilityEffects::MoveImmunity[passive_id]
      return Battle::AbilityEffects::MoveImmunity.trigger(passive_id, user, target, move, type, battle, show_message)
    end
		return false
  end
	
	def triggerStatLossImmunity(ability, battler, stat, battle, show_messages)#능력 하락 면역
    return true if super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::StatLossImmunity[passive_id]
      return Battle::AbilityEffects::StatLossImmunity.trigger(passive_id, battler, stat, battle, show_messages)
    end
		return false
  end
	
	def triggerStatLossImmunityNonIgnorable(ability, battler, stat, battle, show_messages)#능력 하락 면역
    return true if super
    passive_id = battler.pokemon&.passive_ability
    return false if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::StatLossImmunityNonIgnorable[passive_id]
      return Battle::AbilityEffects::StatLossImmunityNonIgnorable.trigger(passive_id, battler, stat, battle, show_messages)
    end
		return false
  end
	
	def triggerStatLossImmunityFromAlly(ability, bearer, battler, stat, battle, show_messages)#능력 하락 면역
    return true if super
    passive_id = bearer.pokemon&.passive_ability
    return false if !passive_id || passive_id == ability || !bearer.abilityActive?
    if Battle::AbilityEffects::StatLossImmunityFromAlly[passive_id]
      return Battle::AbilityEffects::StatLossImmunityFromAlly.trigger(passive_id, bearer, battler, stat, battle, show_messages)
    end
		return false
  end
	
  def triggerOnSwitchOut(ability, battler, end_of_battle)#필드에서 벗어났을 경우
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnSwitchOut[passive_id]
      Battle::AbilityEffects::OnSwitchOut.trigger(passive_id, battler, end_of_battle)
    end
  end
	
	
	def triggerChangeOnBattlerFainting(ability, battler, fainted, battle)#아군이 쓰러졌을때
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::ChangeOnBattlerFainting[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::ChangeOnBattlerFainting.trigger(passive_id, battler, fainted, battle) }
    end
  end
	
	def triggerOnBattlerFainting(ability, battler, fainted, battle)#아군이 쓰러졌을때
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnBattlerFainting[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::OnBattlerFainting.trigger(passive_id, battler, fainted, battle) }
    end
  end
	
	def triggerOnTerrainChangeg(ability, battler, battle, ability_changed)#필드 따라 변화
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnTerrainChange[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::OnTerrainChange.trigger(passive_id, battler, battle, ability_changed) }
    end
  end
	
	def triggerOnIntimidated(ability, battler, battle)#필드 따라 변화
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnIntimidated[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::OnIntimidated.trigger(passive_id, battler, battle) }
    end
  end
	

# 파일: KKJ패시브2 (또는 KKJ3패시브2)
# module PassiveAbilityTriggers 안에 있는 기존 함수를 아래 코드로 교체하세요.

  def triggerPriorityChange(ability, battler, move, priority)
    # 1. 원래 특성의 우선도 값을 계산합니다.
    # 만약 계산 결과가 nil(값 없음)이면, 원래의 priority 값을 사용합니다.
    priority_from_ability = super
    priority_from_ability = priority if priority_from_ability.nil?

    # 2. 패시브 특성의 우선도 값을 계산합니다.
    priority_from_passive = priority # 기본값은 원래 priority
    passive_id = battler.pokemon&.passive_ability
    if passive_id && passive_id != ability && battler.abilityActive?
      if Battle::AbilityEffects::PriorityChange[passive_id]
        ret = Battle::AbilityEffects::PriorityChange.trigger(passive_id, battler, move, priority, ret: priority)
        # 패시브 계산 결과가 nil이 아닐 경우에만 값을 갱신합니다.
        priority_from_passive = ret if !ret.nil?
      end
    end
    
    # 3. 두 우선도 값(이제 절대 nil이 아님) 중 더 높은 쪽을 최종 결과로 반환합니다.
    return [priority_from_ability, priority_from_passive].max
  end

  def triggerStatusImmunity(ability, battler, status)#상태이상 면역
    return true if super
    passive_id = battler.pokemon&.passive_ability
    return false if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::StatusImmunity[passive_id]
      return Battle::AbilityEffects::StatusImmunity.trigger(passive_id, battler, status)
    end
		return false
  end
	
	def triggerStatusImmunityFromAlly(ability, battler, status)#상태이상면역 동료
    return true if super
    passive_id = battler.pokemon&.passive_ability
    return false if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::StatusImmunityFromAlly[passive_id]
      return Battle::AbilityEffects::StatusImmunityFromAlly.trigger(passive_id, battler, status)
    end
		return false
  end
	
	def triggerStatusCure(ability, battler)#상태이상 치료
    return true if super
    passive_id = battler.pokemon&.passive_ability
    return false if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::StatusCure[passive_id]
      return Battle::AbilityEffects::StatusCure.trigger(passive_id, battler)
    end
		return false
  end
	
	def triggerEndOfRoundHealing(ability, battler, battle)#턴종시 회복
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::EndOfRoundHealing[passive_id]
      return Battle::AbilityEffects::EndOfRoundHealing.trigger(passive_id, battler, battle)
    end
  end
  
  def triggerOnStatusInflicted(ability, battler, user, status)
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnStatusInflicted[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::OnStatusInflicted.trigger(passive_id, battler, user, status) }
    end
  end

  def triggerOnStatLoss(ability, battler, stat, user)#스텟감소시
    super
    passive_id = battler.pokemon&.passive_ability
    return if !passive_id || passive_id == ability || !battler.abilityActive?
    if Battle::AbilityEffects::OnStatLoss[passive_id]
      with_passive_context(battler, passive_id) { Battle::AbilityEffects::OnStatLoss.trigger(passive_id, battler, stat, user) }
    end
  end
  
  def triggerModifyMoveBaseType(ability, user, move, type) #스킨류
    type = super
    passive_id = user.pokemon&.passive_ability
    return type if !passive_id || passive_id == ability || !user.abilityActive?
    if passive_id == :NORMALIZE
			type = :NORMAL
		elsif Battle::AbilityEffects::ModifyMoveBaseType[passive_id] && type == :NORMAL
			type = Battle::AbilityEffects::ModifyMoveBaseType.trigger(passive_id, user, move, type, ret: type)
		end
    return type
  end

  def triggerMoveBlocking(ability, bearer, user, targets, move, battle)#기술 차단
    return true if super
    passive_id = bearer.pokemon&.passive_ability
    return false if !passive_id || passive_id == ability || !bearer.abilityActive?
    if Battle::AbilityEffects::MoveBlocking[passive_id]
      return Battle::AbilityEffects::MoveBlocking.trigger(passive_id, bearer, user, targets, move, battle)
    end
    return false
  end

end

#===============================================================================
# UI에 표시될 기술 위력을 계산하는 헬퍼 모듈 (오류 수정 최종본)
#===============================================================================
module PassivePowerCalculator
  def self.get_display_power(move, battler)
    # --- START: 오류 수정 ---
    # 1. 기술에 'base_damage'라는 개념 자체가 있는지 먼저 확인합니다.
    #    변화 기술처럼 이 개념이 없으면, 오류를 발생시키는 대신 즉시 0을 반환합니다.
    unless move.respond_to?(:base_damage)
      return 0
    end
    # --- END: 오류 수정 ---

    # 2. 'base_damage'가 존재함을 확인했으므로, 이제 안전하게 값을 읽습니다.
    #    위력이 1 이하인 기술(변화 기술 등)은 계산하지 않습니다.
    return 0 if move.base_damage <= 1

    power = move.base_damage

    # 적응력 (패시브 또는 일반 특성)
    if battler.hasActiveAbility?(:ADAPTABILITY) && battler.pbHasType?(move.type)
      return (power * 2).to_i
    end

    # 테크니션 (패시브 또는 일반 특성)
    if battler.hasActiveAbility?(:TECHNICIAN) && power <= 60
      return (power * 1.5).to_i
    end

    return power # 아무 특성도 적용되지 않으면 원래 위력 반환
  end
end
#===============================================================================
# 섹션 3: 전투 중 기술 설명창 수정 (UI 로직) - [최종 최적화 버전]
#===============================================================================
module PassiveUIInfoText
  # 특정 특성이 주어진 기술에 UI적으로 영향을 주는지 확인하는 헬퍼 메서드
  def ability_applies_to_move_for_ui?(ability_id, battler, move)
    return false if !ability_id || !battler || !move || !move.id || move.is_a?(Battle::Move::None)
    
    case ability_id
    when :TECHNICIAN
      return move.respond_to?(:base_damage) && move.base_damage && move.base_damage > 0 && move.base_damage <= 60
    when :ADAPTABILITY
      return battler.pbHasType?(move.type)
    when :GALEWINGS
      return move.type == :FLYING && (Settings::MECHANICS_GENERATION <= 6 || battler.hp == battler.totalhp)
    when :AERILATE, :PIXILATE, :REFRIGERATE, :GALVANIZE, :NORMALIZE
      return move.type == :NORMAL
    when :LIQUIDVOICE
      return move.soundMove?
    else
      return Battle::AbilityEffects::DamageCalcFromUser[ability_id]  ||
             Battle::AbilityEffects::ModifyMoveBaseType[ability_id]  ||
             Battle::AbilityEffects::PriorityChange[ability_id]  ||
             Battle::AbilityEffects::AccuracyCalcFromUser[ability_id] 
    end
    return false
  end

  # ★★★ [최적화] 기술 정보를 미리 계산하여 캐시에 저장하는 메서드 ★★★
  def refresh_move_info_cache
    @move_info_cache = []
    return if !@battler || !@battler.moves
    @battler.moves.each do |move|
      passive_id = @battler.pokemon&.passive_ability
      ability_id = @battler.ability_id
      
      info_ability_id = nil
      if ability_applies_to_move_for_ui?(passive_id, @battler, move)
        info_ability_id = passive_id
      elsif ability_applies_to_move_for_ui?(ability_id, @battler, move)
        info_ability_id = ability_id
      end
      @move_info_cache.push(info_ability_id)
    end
  end

  # FightWindow가 활성화될 때 캐시를 생성/갱신하도록 합니다.
  def refresh
    refresh_move_info_cache
    super
  end

  # 기술 정보를 그릴 때, 미리 계산된 캐시 값을 사용합니다.
  def draw_move_info_text(move)
    # 현재 선택된 기술의 인덱스를 찾습니다.
    move_index = -1
    @battler.moves.each_with_index do |m, i|
      move_index = i if m.id == move.id
    end
    
    # 캐시에서 해당 기술에 적용할 특성 정보를 가져옵니다.
    info_ability_id = (move_index >= 0) ? @move_info_cache[move_index] : nil
    
    if info_ability_id
      original_ability_id = @battler.ability_id
      original_pokemon_ability_id = @battler.pokemon&.ability_id
      begin
        @battler.ability = info_ability_id
        @battler.pokemon.ability_id = info_ability_id if @battler.pokemon
        super(move)
      ensure
        @battler.ability = original_ability_id
        @battler.pokemon.ability_id = original_pokemon_ability_id if @battler.pokemon
      end
    else
      super(move)
    end
  end
end
#===============================================================================
# 최종 적용: 위에서 만든 모듈들을 게임의 원래 기능에 안전하게 끼워넣습니다.
#===============================================================================

# ▼▼▼▼▼ 이 부분을 추가해주세요! ▼▼▼▼▼
module Battle::AbilityEffects
  class << self
    prepend PassiveAbilityTriggers
  end
end
# ▲▲▲▲▲ 여기까지 추가해주세요! ▲▲▲▲▲

if defined?(Battle::Scene::FightWindow)
  class Battle::Scene::FightWindow
    prepend PassiveUIInfoText
  end
end

#-------------------------------------------------------------------------------
# 최종 적용: 위에서 만든 모듈들을 게임의 원래 기능에 안전하게 끼워넣습니다.
#-------------------------------------------------------------------------------
if defined?(Battle::Scene::FightWindow)
  class Battle::Scene::FightWindow
    prepend PassiveUIInfoText
  end
end
