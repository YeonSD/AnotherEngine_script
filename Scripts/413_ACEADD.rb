# ==============================================================================
# [Another Red] 4인 슬림 에이스 HUD (V34.9 - 패시브 한글화 이식 및 구문 오류 수정)
# ==============================================================================

class Pokemon
  attr_accessor :ace_rank
  attr_accessor :ace_form

  # [패시브만추출.txt 이식] 패시브를 한글로 안전하게 반환하는 함수
  def passive_ability
    if @passive_ability
      # 수동 설정된 패시브가 있을 경우 한글 이름 반환
      return GameData::Ability.get(@passive_ability).name rescue @passive_ability.to_s
    elsif defined?(GameData::Species)
      sp = GameData::Species.get(self.species)
      if sp && sp.abilities[1]
        # 종족 데이터의 2번째 특성(패시브 슬롯)을 한글 이름으로 반환
        return GameData::Ability.get(sp.abilities[1]).name rescue "---"
      end
    end
    return "---"
  end

  def passive_ability=(val)
    @passive_ability = val
  end
end

# --- [에이스 등록 메뉴] ---
def pbAceSelectionMenu
  loop do
    ace_pkmns = [nil, nil, nil, nil]
    $player.party.each { |p| ace_pkmns[p.ace_rank - 1] = p if p && p.ace_rank && p.ace_rank.between?(1, 4) }
    
    commands = []
    4.times do |i|
      p = ace_pkmns[i]
      if p
        f_idx = p.ace_form || 0
        s_data = GameData::Species.get_species_form(p.species, f_idx)
        f_sub = s_data.form_name
        full_name = (f_sub && !f_sub.empty?) ? "#{p.name} (#{f_sub})" : p.name
        commands.push(_INTL("제 {1}에이스: {2}", i + 1, full_name))
      else
        commands.push(_INTL("제 {1}에이스: ---", i + 1))
      end
    end
    commands.push(_INTL("모두 등록 해제"), _INTL("그만두기"))
    
    sel = pbMessage(_INTL("에이스를 관리해 주세요."), commands, 6)
    break if sel == 5
    if sel == 4
      $player.party.each { |p| p.ace_rank = 0 if p }
      next
    end

    rank = sel + 1
    pbChoosePokemon(1, false, false)
    idx = $game_variables[1]
    
    if idx >= 0
      pkmn = $player.party[idx]
      next if !pkmn
      
      valid_forms = []
      all_forms = GameData::Species.keys.select { |sp| (GameData::Species.get(sp).species == pkmn.species rescue false) }
      all_forms.each do |sp_id|
        begin
          sp = GameData::Species.get(sp_id)
          next if sp.id.to_s.include?("GMAX") || sp.id.to_s.include?("DMAX")
          f_sub = sp.form_name
          full_name = (f_sub && !f_sub.empty?) ? "#{sp.name} (#{f_sub})" : sp.name
          valid_forms.push([sp.form, full_name])
        rescue
        end
      end
      valid_forms.uniq! { |f| f[0] }
      valid_forms.sort_by! { |f| f[0] }
      
      selected_form = 0
      if valid_forms.length > 1
        f_commands = valid_forms.map { |f| _INTL("{1}", f[1]) }
        f_sel = pbMessage(_INTL("HUD에 고정할 폼을 선택하세요."), f_commands, 0)
        selected_form = valid_forms[f_sel][0] if f_sel >= 0
      else
        selected_form = pkmn.form || 0
      end

      $player.party.each { |p| p.ace_rank = 0 if p && p.ace_rank == rank }
      pkmn.ace_rank = rank
      pkmn.ace_form = selected_form
      pbMessage(_INTL("에이스 등록 완료!"))
    end
  end
end

class AceStatusHUD
  def initialize(viewport)
    @viewport = viewport
    @sprite = Sprite.new(@viewport)
    @sprite.bitmap = Bitmap.new(Graphics.width, 78)
    @sprite.z = 100
    @old_aces = []
    reposition_hud
  end

  def reposition_hud
    @sprite.x = 0
    @sprite.y = Graphics.height - @sprite.bitmap.height
  end

  def dispose
    @sprite.bitmap.dispose
    @sprite.dispose
  end

  def update
    return if !@sprite || @sprite.disposed?
    
    should_be_visible = $scene.is_a?(Scene_Map) && !$game_temp.message_window_showing && 
                        !$game_temp.in_menu && !$game_temp.in_battle && !$player.party.empty?
    @sprite.visible = should_be_visible
    return if !@sprite.visible
    
    # 감시 대상에 passive_ability를 포함하여 변경 시 HUD 갱신
    current_aces = $player.party.select { |p| p && p.ace_rank && p.ace_rank > 0 }.map { |p| 
      [p.species, p.level, p.ace_rank, p.form, p.hp, p.ability_id, p.passive_ability] 
    } rescue []

    if @old_aces != current_aces || Graphics.frame_count % 20 == 0
      @old_aces = current_aces
      update_hud
    end
  end

  def update_hud
    @sprite.bitmap.clear
    aces = [nil, nil, nil, nil]
    $player.party.each { |p| aces[p.ace_rank - 1] = p if p && p.ace_rank && p.ace_rank.between?(1, 4) }
    return if aces.compact.empty?
    
    @sprite.bitmap.fill_rect(0, 0, Graphics.width, 80, Color.new(0, 0, 0, 160))
    pbSetSystemFont(@sprite.bitmap) 
    slot_width = Graphics.width / 4.0
    banned_abilities = [:IRONLIZE, :BURININGRESOLVE, :POWERAMPLIFIER, :DRAGONIZE, :MEGASOL]

    aces.each_with_index do |pkmn, i|
      next if !pkmn
      begin
        x_base = (i * slot_width)
        display_f = pkmn.ace_form || 0
        s_data = GameData::Species.get_species_form(pkmn.species, display_f) rescue nil
        next if !s_data 
        
        # 1. 아이콘
        icon_bmp = GameData::Species.icon_bitmap(pkmn.species, display_f) rescue nil
        @sprite.bitmap.stretch_blt(Rect.new(x_base + 1, 0, 54, 54), icon_bmp, Rect.new(0, 0, 64, 64)) if icon_bmp

        # 2. 종족값 (종족값특성hud.txt의 전역 캐시 연동 유지)
        @sprite.bitmap.font.size = 13
        @sprite.bitmap.font.bold = true
        stats = pbGetSpeciesFixedStats(pkmn.species, display_f)
        
        stats.each_with_index do |val, s_idx|
          txt = sprintf("%03d", val || 0)
          pbDrawTextPositions(@sprite.bitmap, [[txt, x_base + 58 + ((s_idx % 2) * 28), 4 + ((s_idx / 2) * 16), 0, Color.new(255, 255, 255), Color.new(50, 50, 50)]])
        end

        # 3. 특성 (종족값특성hud.txt의 전역 캐시 연동 유지)
        ability_id = pbGetSpeciesFixedAbility(pkmn.species, display_f)
        ability_name = banned_abilities.include?(ability_id) ? "---" : (GameData::Ability.get(ability_id).name rescue "---")
        
        # 4. 패시브 (패시브만추출.txt의 한글화 로직 적용)
        p_ability_name = pkmn.passive_ability
        # Symbol 형태인 경우 최종적으로 한글 이름으로 변환 시도
        if p_ability_name.is_a?(Symbol)
          p_ability_name = GameData::Ability.get(p_ability_name).name rescue p_ability_name.to_s
        end

        @sprite.bitmap.font.size = 12
        @sprite.bitmap.font.bold = false
        pbDrawTextPositions(@sprite.bitmap, [
          ["#{stats.sum} / #{ability_name}", x_base + 4, 55, 0, Color.new(120, 255, 120), Color.new(0, 0, 0)],
          ["P: #{p_ability_name}", x_base + 4, 68, 0, Color.new(255, 180, 50), Color.new(0, 0, 0)]
        ])
      rescue
        next
      end
    end
  end
end

class Spriteset_Map
  alias __ace_init initialize unless method_defined?(:__ace_init)
  def initialize(map)
    __ace_init(map)
    @ace_status_hud = AceStatusHUD.new(@viewport3)
  end

  alias __ace_dispose dispose unless method_defined?(:__ace_dispose)
  def dispose
    @ace_status_hud.dispose if @ace_status_hud
    __ace_dispose
  end

  alias __ace_update update unless method_defined?(:__ace_update)
  def update
    __ace_update
    @ace_status_hud.update if @ace_status_hud
  end
end