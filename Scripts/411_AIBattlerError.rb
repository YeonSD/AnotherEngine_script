# ==============================================================================
# [Another Red] Gen 9 AI 호환성 패치 (V2 - TypeError 수정본)
# ==============================================================================
class Battle
  class AI
    class AIBattler
      # AI가 기술 순위를 매길 때 터지는 unstoppableAbility? 메서드 누락 보정
      if !method_defined?(:unstoppableAbility?)
        def unstoppableAbility?
          return @battler.unstoppableAbility?
        end
      end
      
      # 혹시 모를 추가 안전장치
      if !method_defined?(:hasUnstoppableAbility?)
        def hasUnstoppableAbility?
          return @battler.hasUnstoppableAbility?
        end
      end
    end
  end
end

# 9세대 팩 전용 AI 보정 (특성 무시 기술 계산용)
class Battle::Battler
  if !method_defined?(:unstoppableAbility?)
    def unstoppableAbility?
      return GameData::Ability.get(@ability).has_flag?("Unstoppable") rescue false
    end
  end
end