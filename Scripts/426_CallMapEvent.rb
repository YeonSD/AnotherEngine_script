def pbCallMapEvent(map_id, event_id, required_switches = [])
  # 필요한 스위치 ON
  required_switches.each do |sw|
    $game_switches[sw] = true
  end

  # 맵 데이터 로드
  map_data = load_data(sprintf("Data/Map%03d.rxdata", map_id))
  if !map_data
    pbMessage("맵 데이터를 찾을 수 없습니다.")
    return
  end

  # 이벤트 찾기
  event = map_data.events[event_id]
  if !event
    pbMessage("이벤트를 찾을 수 없습니다.")
    return
  end

  # 조건에 맞는 페이지 찾기
  page = nil
  event.pages.reverse_each do |p|
    cond = p.condition

    next if cond.switch1_valid && !$game_switches[cond.switch1_id]
    next if cond.switch2_valid && !$game_switches[cond.switch2_id]
    next if cond.variable_valid && $game_variables[cond.variable_id] < cond.variable_value

    if cond.self_switch_valid
      key = [map_id, event_id, cond.self_switch_ch]
      next if !$game_self_switches[key]
    end

    page = p
    break
  end

  if !page
    pbMessage("조건을 만족하는 이벤트 페이지가 없습니다.")
    return
  end

  # interpreter 실행
  interpreter = Interpreter.new
  interpreter.setup(page.list, event_id)

  loop do
    interpreter.update
    Graphics.update
    Input.update
    break if !interpreter.running?
  end
end
