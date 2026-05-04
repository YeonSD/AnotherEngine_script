#===============================================================================
# 호환용 메시지
#===============================================================================
unless defined?(pbDisplayMessage)
  def pbDisplayMessage(message)
    pbMessage(message)
  end
end

#===============================================================================
# 스타터 1마리 셋업
#===============================================================================
def setup_random_starter(pkmn)
  if pkmn
    $game_variables[4001] = pkmn           # 포켓몬 객체
    $game_variables[4002] = pkmn.name      # 포켓몬 이름
    $game_switches[100]   = true
  else
    Kernel.pbMessage("오류: 스타터를 선택하지 못했습니다.")
    $game_switches[100] = false
  end
end

#===============================================================================
# 스타터 포켓몬 1마리 이미지/타입 표시
#===============================================================================
def show_starter_sprite
  hide_starter_sprite

  $starter_sprite_container = {}
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  $starter_sprite_container["viewport"] = viewport

  pkmn = $game_variables[4001]
  return if !pkmn

  # 위치
  x_base = Graphics.width / 2
  y_pokemon_floor = 200
  y_offset_types = 30

  # 포켓몬 이미지
  sprite = Sprite.new(viewport)
  bitmap = Bitmap.new(GameData::Species.sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?))
  sprite.bitmap = bitmap
  frame_width = bitmap.height
  sprite.src_rect.set(0, 0, frame_width, bitmap.height)
  sprite.ox = frame_width / 2
  sprite.oy = bitmap.height
  sprite.x = x_base
  sprite.y = y_pokemon_floor
  sprite.zoom_x = 2
  sprite.zoom_y = 2
  $starter_sprite_container["poke"] = sprite

  # 타입 아이콘
  pkmn.types.each_with_index do |type, i|
    type_icon = Sprite.new(viewport)
    type_bitmap = Bitmap.new("Graphics/UI/types.png")
    type_rect = Rect.new(0, GameData::Type.get(type).icon_position * 28, 64, 28)
    type_icon.bitmap = type_bitmap
    type_icon.src_rect = type_rect
    type_icon.ox = type_rect.width / 2
    type_icon.x = x_base + ((pkmn.types.length == 1) ? 0 : (i == 0 ? -34 : 34))
    type_icon.y = y_pokemon_floor + y_offset_types
    $starter_sprite_container["type#{i}"] = type_icon
  end
end

def hide_starter_sprite
  if $starter_sprite_container
    $starter_sprite_container.values.each do |graphic|
      graphic.dispose if graphic && !graphic.disposed?
    end
    $starter_sprite_container = nil
  end
end

#===============================================================================
# 카탈로그 (1마리 선택 → setup_random_starter 적용)
#===============================================================================
def pbOpenSpeciesCatalog
  level = 5  # 스타터는 Lv.5 고정
entries = []
if $game_switches[254]   # 스위치 254가 켜지면 스타터용 필터 적용
  GameData::Species.each do |sp|
    next if sp.get_baby_species != sp.species
    next if sp.flags.include?("Legendary")
    next if sp.flags.include?("Mythical")
    next if sp.flags.include?("UltraBeast")
    next if sp.form != 0
    next if sp.flags.include?("Paradox")
    entries << sp
  end
elsif $game_switches[255] # 스위치 255가 켜지면 전체 수집
  GameData::Species.each do |sp|
    next if sp.form != 0
    entries << sp
  end
end

  return pbMessage(_INTL("등록된 종 데이터가 없습니다.")) if entries.empty?

  index = 0
  current_pkmn = nil

  build_current = proc do
    sp = entries[index]
    current_pkmn = Pokemon.new(sp.species, level)
    begin
      current_pkmn.forceForm(sp.form) if sp.form && sp.form > 0 && current_pkmn.respond_to?(:forceForm)
    rescue
    end
    # 순번 텍스트
    order_text = _INTL("{1}/{2}", index + 1, entries.length)

    # 화면 표시
    hide_starter_sprite
    $game_variables[4001] = current_pkmn
    show_starter_sprite

    # 순번 텍스트 오버레이
    vp = $starter_sprite_container["viewport"]
    label = Sprite.new(vp)
    label.bitmap = Bitmap.new(Graphics.width, 36)
    f = label.bitmap.font
    f.size = 22
    f.bold = true
    f.color = Color.new(160,160,160)
    label.y = 6
    label.bitmap.draw_text(0, 0, label.bitmap.width, 32, order_text.to_s, 1)
    $starter_sprite_container["label"] = label
    
# === 채팅창 스타일 윈도우 ===
if !$starter_sprite_container["msgwin"]
  msgwin = Window_AdvancedTextPokemon.new("")
  msgwin.viewport = vp
  msgwin.z = 99999
  msgwin.width  = Graphics.width
  msgwin.height = 96
  msgwin.y = Graphics.height - msgwin.height
  $starter_sprite_container["msgwin"] = msgwin
end

species_name = sp.name
species_cat  = sp.category
text = _INTL("{2}포켓몬 {1}", species_name, species_cat)
$starter_sprite_container["msgwin"].setText(text)  # <- 여기서 escape 코드 해석
  end

  build_current.call

  loop do
    Graphics.update
    Input.update

    if Input.trigger?(Input::B) || Input.trigger?(Input::X)
        # 스타터 선택 취소 시 변수 초기화
    break
    elsif Input.trigger?(Input::LEFT)
      index = (index - 1) % entries.length; build_current.call
    elsif Input.trigger?(Input::RIGHT)
      index = (index + 1) % entries.length; build_current.call
    elsif Input.trigger?(Input::UP)
      index = (index - 10) % entries.length; build_current.call
    elsif Input.trigger?(Input::DOWN)
      index = (index + 10) % entries.length; build_current.call
    elsif Input.trigger?(Input::L) || (defined?(Input::Q) && Input.trigger?(Input::Q))
      index = (index - 50) % entries.length; build_current.call
    elsif Input.trigger?(Input::R) || (defined?(Input::W) && Input.trigger?(Input::W))
      index = (index + 50) % entries.length; build_current.call
    elsif Input.trigger?(Input::C) || Input.trigger?(Input::A) ||
          Input.trigger?(Input::Z) || Input.trigger?(Input::Y) ||
          Input.trigger?(Input::SHIFT) ||
          (defined?(Input::SPACE) && Input.trigger?(Input::SPACE)) ||
          (defined?(Input::RETURN) && Input.trigger?(Input::RETURN))
      setup_random_starter(current_pkmn)
      hide_starter_sprite
      break
    end
  end

  hide_starter_sprite
end