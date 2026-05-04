class Battle::Move
  if method_defined?(:apply_rough_accuracy_modifiers)
    alias za_apply_rough_accuracy_modifiers apply_rough_accuracy_modifiers
    
    def apply_rough_accuracy_modifiers(user, target, calc_type, modifiers)
      za_apply_rough_accuracy_modifiers(user, target, calc_type, modifiers)
      if @function_code == "IgnoreTargetDefSpDefEvaStatStagesHitFairyType"
        modifiers[:evasion_stage] = 0 
      end
    end
  end
end

class Battle::Battler
  unless method_defined?(:form_zygarde_hook=)
    alias form_zygarde_hook= form=
  end

  def form=(value)
    self.form_zygarde_hook = value
    if isSpecies?(:ZYGARDE)
      party_pkmn = self.pokemon
      return if party_pkmn.nil?
      if value > 3 && value < 8
        if $game_switches[277] || !self.pbOwnedByPlayer?
          target_move_id = :NIHILLIGHT
        else
          target_move_id = :NIHILLIGHT200
        end

        party_pkmn.moves.each_with_index do |pkmn_move, i|
          if pkmn_move.id == :COREENFORCER
            pkmn_move.id = target_move_id
            @moves[i] = Battle::Move.from_pokemon_move(@battle, pkmn_move)
            if @battle.choices[self.index][0] == :UseMove && @battle.choices[self.index][1] == i
               @battle.choices[self.index][2] = @moves[i]
            end
          end
        end
      else
        party_pkmn.moves.each_with_index do |pkmn_move, i|
          if [:NIHILLIGHT, :NIHILLIGHT200].include?(pkmn_move.id)
            pkmn_move.id = :COREENFORCER
            @moves[i] = Battle::Move.from_pokemon_move(@battle, pkmn_move)
          end
        end
      end
      
    end
  rescue Exception => e
    puts "[ERROR] #{e.message}"
  end
end