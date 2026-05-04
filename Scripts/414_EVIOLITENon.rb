class Pokemon
  #-----------------------------------------------------------------------------
  # 1. 자연적인 진화 체크 (레벨업 등) 가로채기
  #-----------------------------------------------------------------------------
  alias _another_red_check_evolution_internal check_evolution_internal
  def check_evolution_internal
    # [가드] 변수 130번이 1이고 진화의휘석을 들고 있다면 즉시 진화 차단
    if $game_variables && $game_variables[130] == 1 && (self.item == :EVIOLITE || hasItem?(:EVIOLITE))
      return nil
    end
    # 위 조건이 아닐 때만 기존의 진화 로직 실행
    return _another_red_check_evolution_internal { |pkmn, new_species, method, parameter| 
      yield pkmn, new_species, method, parameter if block_given?
    }
  end

  #-----------------------------------------------------------------------------
  # 2. 이벤트/도구에 의한 강제 진화 가로채기
  #-----------------------------------------------------------------------------
  alias _another_red_trigger_event_evolution trigger_event_evolution
  def trigger_event_evolution(number)
    # [가드] 변수 130번이 1이고 진화의휘석을 들고 있다면 강제 진화 차단
    if $game_variables && $game_variables[130] == 1 && (self.item == :EVIOLITE || hasItem?(:EVIOLITE))
      # 여기에 메시지를 넣으면 왜 진화가 안되는지 플레이어에게 알려줄 수 있습니다.
      pbMessage(_INTL("진화의휘석의 영향으로 진화가 억제되었다!")) 
      return false
    end

    # --- 여기서부터는 기존 로직 및 랜덤 진화 처리 ---
    new_species = check_evolution_by_event(number)
    if new_species
      # 랜덤 진화 스위치 체크 (오타 수정: pkmn -> self)
      if $player.random_evo_switch && $player.random_evo_switch != 0 && !hasItem?(:EVERSTONE)
        current_level = self.level
        random_sp = give_random_pokemon(self)
        if random_sp
          new_species = random_sp
          self.level = current_level
        end
      end

      # 진화 연출
      pbFadeOutInWithMusic do
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(self, new_species)
        evo.pbEvolution
        evo.pbEndScreen
      end
      return true
    end
    return false
  end
end