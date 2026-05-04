#===============================================================================
# 이벤트용 전설 포켓몬 선택 + 배틀 + 결과 처리 (배터리 소모 포함)
#===============================================================================
def pbLegendChoice(legends, level=70)
  # 아직 잡히지 않은 전설만 선택지에 추가
  commands = []
  legends.each do |name, data|
    poke, switch = data
    commands << name if !$game_switches[switch]   # 잡히지 않은 포켓몬만
  end

  # 만날 수 있는 포켓몬이 없으면 종료
  if commands.empty?
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](스캐너가 더 반응하지 않는다...)")
    return
  end

  commands.push("취소")
  
  # 안내 메시지 순서
  pbMessage("\\xn[\\c[1]\\pn]\\c[1](스캐너가 요동친다!)")
  
  pbMessage("\\xn[\\c[1]\\pn]\\c[1](희귀한 포켓몬의 데이터가 발견됐다!)")

  # 선택지 창
  cmd = pbMessage(
    "\\xn[\\c[1]\\pn]\\c[1](레전드배터리를 넣고 스캔해서 어떤 포켓몬을 불러낼까?)",
    commands, commands.size
  )

  # 취소
  if cmd.nil? || cmd == commands.size - 1
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](스캐너를 다시 가방에 넣었다...)")
    return
  end

  # 배터리 체크
  battery_count = $bag.quantity(:LEGENDBATTERY)
  if battery_count <= 0
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](하지만 레전드배터리가 없어서 사용할 수가 없다...)")
    return
  else
    
  end
  
  # 플레이어 위에 애니메이션 재생
  $game_player.animation_id = 10

  # 대기 시간
  pbWait(2)

  # 플레이어 위에 애니메이션 재생
  $game_player.animation_id = 3     

  # 선택한 포켓몬
  chosen_name = commands[cmd]
  poke, switch = legends[chosen_name]

  pbMessage("\\xn[\\c[1]\\pn]\\c[1](스캐너를 작동하니 포켓몬이 나타났다.)")
  
  # ⚡ 배틀 시작
  AutomaticLevelScaling.setTemporarySetting("useMapLevelForWildPokemon", false)
  WildBattle.start(poke, level)
  AutomaticLevelScaling.setTemporarySetting("useMapLevelForWildPokemon", true)
  $bag.remove(:LEGENDBATTERY, 1)   # 배터리 1개 소모

  # 배틀 결과 처리 (WildBattle.start가 $game_variables[1]에 기록)
  case $game_variables[1]
  when 4  # 포획 성공
    $game_switches[switch] = true
  else   # 도망쳤음
    pbMessage(_INTL("\\xn[\\c[1]\\pn]\\c[1](\\j[{1},은,는] 어디론가 모습을 감췄다...)", chosen_name))
  end
end

#==========================================================
def pbPokemonTS(pkmn)
  return unless pkmn

  if pkmn.singleGendered?
    pbMessage(_INTL("\\j[\\c[5]{1}\\c[0],은,는] 성별이 없거나 고정되어 있어 바꿀 수 없어.", pkmn.name))
    return
  end

  # 현재 성별 표시
  msg = _INTL("현재 \\j[\\c[5]{1}\\c[0],의,의] 성별은 {2}이야. 정말 바꿀거야?",
              pkmn.name,
              pkmn.male? ? "\\c[1]수컷\\c[0]" : "\\c[2]암컷\\c[0]")

  # 예/아니오 선택창
  if pbConfirmMessage(msg)
    # 반대 성별로 변경
    if pkmn.male?
      pkmn.makeFemale
      pbMessage(_INTL("\\j[\\c[5]{1}\\c[0],은,는] 이제 \\c[2]암컷\\c[0]이 되었어.", pkmn.name))
    else
      pkmn.makeMale
      pbMessage(_INTL("\\j[\\c[5]{1}\\c[0],은,는] 이제 \\c[1]수컷\\c[0]이 되었어.", pkmn.name))
    end
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](도대체 어떻게 한거지?)")
  else
    pbMessage("그래 고민하고 다음에 다시 와.")
  end
end



#==========================================================
#변수지정
#==========================================================|
def pbSetEVLimit
  params = ChooseNumberParams.new
  params.setRange(510, 1512)          # 최대치 범위
  params.setDefaultValue($game_variables[150] > 0 ? $game_variables[150] : 510)
  params.setCancelValue(nil)          # 취소하면 nil 반환
  
  current_limit = $game_variables[150] > 0 ? $game_variables[150] : 510
  f = pbMessageChooseNumber("\\xn[\\c[1]\\pn]\\c[1](최대 노력치 합을 몇으로 할까?)\\n현재: #{current_limit}, (최소 510 / 최대 1512)", params)
  
 return if f.nil? || f == current_limit
  
    $game_variables[150] = f
    pbMessage(_INTL("\\xn[\\c[1]\\pn]\\c[1](최대 노력치 합이 {1}으로 변경됐다!)", f))
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](현재 포켓몬의 노력치 합보다 최대 노력치가 적은 경우 오류가 날 수 있습니다.)")
end


#============================================================
def pbCapkachu(pkmn)
  return unless pkmn.isSpecies?(:PIKACHU)
  if pkmn.fainted?
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](기절한 포켓몬에게는 사용할 수 없다)")
    return
  end

  if pkmn.form_simple == 18
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](이 피카츄에게는 사용할 수 없다)")
    return
  end  

  # 모자폼 + 기본폼
  hat_forms = {
    "기본폼" => 0,
    "무인 모자" => 8,
    "호연 모자" => 9,
    "신오 모자" => 10,
    "하나 모자" => 11,
    "칼로스 모자" => 12,
    "알로라 모자" => 13,
    "파트너 모자" => 14,
    "W 모자" => 15
  }
  commands = hat_forms.keys
  commands.push("취소")


  # 선택지 창 표시 및 선택
  cmd = pbMessage("\\xn[\\c[1]\\pn]\\c[1](어떤 모자를 씌울까?)", commands,commands.size)

  # 선택값 처리
  return if cmd.nil? || cmd == commands.size - 1
  
if cmd >= 0
  selected_name = commands[cmd]            # 선택한 모자 이름
  selected_form = hat_forms[selected_name] # 폼 번호
  pkmn.setForm(selected_form) do
    if selected_form == 0
      pbMessage("\\c[6]피카츄\\c[0]가 모자를 벗었다.")
    else
      pbMessage("\\c[6]피카츄\\c[0]가 \\c[2]#{selected_name}\\c[0]를 썼다.")
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](피카츄의 표정이 매우 기뻐보인다.)")
    end
    Graphics.update
  end
else
  pbMessage("\\xn[\\c[1]\\pn]\\c[1](좀 더 고민해보자.)")
end
end

#============================================
# Custom 스크립트 맨 위쪽에 정의
def pbMyRuleSetting
  AutomaticLevelScaling.setTemporarySetting("saveTrainerParties", false)
  setBattleRule("noExp", "noMoney", "canLose", "noBag", "setStyle")
end

#================================
def pbCustomA
  loop do
    # 선택지 배열
    commands = [
      _INTL("설명보기"),
      _INTL("기본 옵션 ({1})", $game_switches[271] ? _INTL("O") : _INTL("X")),
      _INTL("싸라기눈 ({1})", $game_switches[272] ? _INTL("O") : _INTL("X")),
      _INTL("과거의 영광 ({1})", $game_switches[273] ? _INTL("O") : _INTL("X")),
      _INTL("무한다이맥스 ({1})", $game_switches[275] ? _INTL("O") : _INTL("X")),
      _INTL("메가지가르데 조건 ({1})", $game_switches[278] ? _INTL("모든 폼") : _INTL("퍼펙트폼")),
      _INTL("니힐레이저 위력 ({1})", $game_switches[277] ? _INTL("100") : _INTL("200")),
      _INTL("취소")
    ]

    # 메시지와 함께 선택지 표시 (취소는 마지막)
    choice = pbMessage(
      "\\xn[\\c[1]\\pn]\\c[1](필요한 설정을 켜자.)", 
      commands, commands.size
    )

    # pbMessage에서 취소 누르면 nil 반환 가능하므로 안전하게 처리
    break if choice.nil? || choice >= commands.size - 1

    case choice
     when 0
      # === 설명 서브 메뉴 ===
      loop do
        sub_commands = [
          _INTL("기본 옵션"),
          _INTL("싸라기눈"),
          _INTL("과거의영광"),
          _INTL("무한다이맥스"),
          _INTL("메가지가르데 조건"),
          _INTL("니힐레이저 위력"),
          _INTL("뒤로가기")
        ]
        sub_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1](보고 싶은 설명을 선택하자.)", sub_commands, sub_commands.size)
        break if sub_choice.nil? || sub_choice >= sub_commands.size - 1

        case sub_choice
        when 0
          pbMessage("이 옵션이 켜져 있을 경우 리베로, 변환자재가 8세대 사양, 탈이 7세대 사양으로 바뀝니다.")
        when 1
          pbMessage("이 옵션이 켜져 있을 경우 눈이 내리는 날씨에 싸라기눈 대미지가 추가 됩니다.")
        when 2
          pbMessage("이 옵션이 켜져 있을 경우 기본 옵션에 추가로 불요의검, 불굴의방패가 8세대 사양, 질풍날개가 6세대 사양으로 바뀝니다.")
        when 3
          pbMessage("이 옵션이 켜져 있을 경우 무한다이노가 무한다이맥스 가능하게 됩니다. \\n단, 다이맥스밴드를 가지고 있어야하며 무한다이노는 다이버섯을 지닌 상태여야지만 가능합니다.")
        when 4
          pbMessage("플레이어의 지가르데가 메가진화 가능한 조건을 퍼펙트폼(기본값) 또는 모든 폼으로 설정합니다.\\nNPC는 항상 퍼펙트폼에서 메가진화합니다.")
        when 5
          pbMessage("플레이어가 사용하는 니힐레이저의 위력을 200(기본값) 또는 100으로 설정합니다.\\nNPC는 항상 위력 100의 니힐레이저를 사용합니다.")
        end
      end
      # 서브 메뉴 종료 → 다시 메인 메뉴로 돌아감       
     when 1
      if $game_switches[273]
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](과거의영광이 켜져 있으므로 기본 옵션을 켤 수 없다. 기본 옵션은 과거의 영광 옵션에 포함되어 있다.)")
      else
    $game_switches[271] = !$game_switches[271]
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](기본 옵션을 #{$game_switches[271] ? '켰다' : '껐다'}.)")
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](해당 옵션은 순정버전 설정이 아닙니다. 일부 특성들이 바뀌는 옵션입니다.)")
      end
    when 2
      $game_switches[272] = !$game_switches[272]
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](싸라기눈 대미지 옵션을 #{$game_switches[272] ? '켰다' : '껐다'}.)")
    when 3
      $game_switches[273] = !$game_switches[273]
      $game_switches[271] = false if $game_switches[273] && $game_switches[271]
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](과거의영광 옵션을 #{$game_switches[273] ? '켰다' : '껐다'}.)")
    when 4
      $game_switches[275] = !$game_switches[275]
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](무한다이맥스 옵션을 #{$game_switches[275] ? '켰다' : '껐다'}.)")      
    when 5
      $game_switches[278] = !$game_switches[278]
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](플레이어의 지가르데가 #{$game_switches[278] ? '모든 폼에서' : '퍼펙트폼에서만'} 메가진화할 수 있도록 설정했다.)")     
    when 6
      $game_switches[277] = !$game_switches[277]
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](플레이어가 사용하는 니힐레이저의 위력을 #{$game_switches[277] ? '100' : '200'}으로 설정했다.)")     
    when 7
      break
    end
  end
end

#================================
def pbCustomB
  loop do   # 메인 메뉴 루프 시작
      # ===== 기본 ON 설정 =====
  $game_switches[251] = true    # 배틀 후 자동회복
  $game_switches[260] = true    # 1회용 도구 유지
  $game_switches[259] = true    # 트레이너 배틀 가방 금지

  $game_variables[151] = 1      # 딸피 BGM 끄기

  $game_switches[252] = true    # 포획률 100%
  $game_switches[276] = true    # 자동 낚시
  $game_switches[61] = true     # 노력치 보이기

  $game_variables[148] = 1      # 박치기 100%
  $game_variables[147] = 1      # 메진 1회제한 해제
  $game_variables[144] = 1      # 포켓몬 창 기술 떠올리기

    # 선택지 배열
    commands = if $game_switches[155]
      [
        _INTL("설명보기"),
        _INTL("배틀기믹 도구 상점"),
        _INTL("전설의 포켓몬 도구 상점"),
        _INTL("배틀 관련 설정"),
        _INTL("유틸 관련 설정"),
        _INTL("올인원 패치 설정"),
        _INTL("경험치 설정"),
        _INTL("취소")
      ]
    else
      [
        _INTL("설명보기"),
        _INTL("배틀기믹 도구 받기"),
        _INTL("전설의 포켓몬 도구 상점"),
        _INTL("배틀 관련 설정"),
        _INTL("유틸 관련 설정"),
        _INTL("올인원 패치 설정"),
        _INTL("경험치 설정"),
        _INTL("취소")
      ]
    end

    # 메시지와 함께 선택지 표시 (취소는 마지막)
    choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1](무엇을 할까?)", commands, commands.size)
    break if choice.nil? || choice >= commands.size - 1

    case choice   # 메인 메뉴 case 시작
    when 0
      # === 설명 서브 메뉴 ===
      loop do
        sub_commands = [
          _INTL("배틀기믹 도구 받기(상점)"),
          _INTL("전설의 포켓몬 도구 상점"),
          _INTL("배틀 관련 설정"),
          _INTL("유틸 관련 설정"),
          _INTL("뒤로가기")
        ]
        sub_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1](보고 싶은 설명을 선택하자.)", sub_commands, sub_commands.size)
        break if sub_choice.nil? || sub_choice >= sub_commands.size - 1

        case sub_choice   # 설명 서브 메뉴 case
        when 0
          pbMessage("메가링, Z링, 다이맥스밴드, 테라스탈오브를 얻습니다. 얻고나면 이 메뉴가 상점메뉴로 바뀝니다.")
        when 1
          pbMessage("전설의 포켓몬 전용 도구를 팝니다.")
        when 2
          # 기타 설정 서브 서브 메뉴
          loop do
            sub_sub_commands = [
              _INTL("배틀 후 자동회복"),
              _INTL("1회용 도구 유지"),
              _INTL("PWT, 배틀타워 금지 제거"),
              _INTL("테라or다맥 도구 자유"),
              _INTL("트레이너 배틀 가방 금지"),
              _INTL("메진 배틀당 1회 제한 해제"),
              _INTL("다맥 배틀당 1회 제한 해제"),
              _INTL("테라 배틀당 1회 제한 해제"),
              _INTL("딸피 BGM 끄기"),
              _INTL("날씨 도구착용시 날씨 무한지속"),
              _INTL("전투 중 포켓몬 타입 표시"),
              _INTL("전투 중 기술 효과 표시"),
              _INTL("뒤로가기")
            ]
            sub_sub_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1](보고 싶은 설명을 선택하자.)", sub_sub_commands, sub_sub_commands.size)
            break if sub_sub_choice.nil? || sub_sub_choice >= sub_sub_commands.size - 1

            case sub_sub_choice
            when 0
              pbMessage("이 옵션이 켜져 있을 경우 배틀 후에 자동으로 회복됩니다.")
            when 1
              pbMessage("이 옵션이 켜져 있을 경우 1회용 도구가 배틀 후에 사라지지 않고 유지됩니다.")
            when 2
              pbMessage("이 옵션이 켜져 있을 경우 PWT에서 전설 제한과 배틀타워에서 600족 포켓몬 금지가 풀립니다.")
            when 3
              pbMessage("이 옵션이 켜져 있을 경우 테라피스or다이버섯을 지니지 않아도 테라스탈or다이맥스가 가능해집니다. \\n동시에는 두가지를 활성화 하지 못합니다.")
              pbMessage("테라스탈 도구 자유의 경우 메가스톤, Z크리스탈, 다이버섯을 지닌 포켓몬과 원시회귀 포켓몬, 화룡점정을 배운 레쿠쟈는 불가능합니다. 또한 벽록의 가면 폼 오거폰을 제외한 모든 오거폰은 가면을 착용해야 테라스탈이 가능해집니다.")
              pbMessage("다이맥스 도구 자유의 경우 메가스톤, Z크리스탈, 테라피스를 지닌 포켓몬과 원시회귀 포켓몬, 화룡점정을 배운 레쿠쟈는 불가능합니다.")
            when 4
              pbMessage("이 옵션이 켜져 있을 경우 트레이너 배틀에서 가방 사용이 금지가 됩니다. 상대 트레이너도 포함입니다.")
            when 5
              pbMessage("이 옵션이 켜져 있을 경우 한 배틀에서 1번만 가능하던 메가진화가 여러번 가능해집니다. 단, 이미 해당 배틀에서 메가진화를 했던 포켓몬은 다시 메가진화가 불가능합니다.")
            when 6
              pbMessage("이 옵션이 켜져 있을 경우 한 배틀에서 1번만 가능하던 다이맥스가 여러번 가능해집니다. 단, 이미 해당 배틀에서 다이맥스를 했던 포켓몬은 다시 다이맥스가 불가능합니다.")
            when 7
              pbMessage("이 옵션이 켜져 있을 경우 한 배틀에서 1번만 가능하던 테라스탈이 여러번 가능해집니다. 단, 이미 해당 배틀에서 테라스탈을 했던 포켓몬은 다시 테라스탈이 불가능합니다.")
            when 8
              pbMessage("이 옵션이 켜져 있을 경우 한 배틀에서 낮은 HP일 때 나오던 BGM이 나오지 않습니다.")              
            when 9
              pbMessage("이 옵션이 켜져 있을 경우 뜨거운바위를 지닌 포켓몬의 쾌청, 축축한바위를 지닌 포켓몬의 비바라기, 차가운바위를 지닌 포켓몬의 설경 및 싸라기눈, 보송보송바위를 지닌 포켓몬의 모래바람의 지속 턴이 무한으로 바뀝니다.")
            when 10
              pbMessage("이 옵션을 켜면 전투 중 포켓몬의 레벨 위에 작게 포켓몬의 타입 아이콘이 표시됩니다.")
            when 11 
              pbMessage("이 옵션을 켜면 전투 중 효과가 4배/2배/0.5배/0.25배/0배인 기술의 이름이 하늘색/초록색/주황색/빨간색/회색으로 표시됩니다.")
            end   # sub_sub_choice case 끝
          end   # 기타 설정 loop 끝
         when 3
          # 기타 설정 서브 서브 메뉴
          loop do
            sub_sub_commands4 = [
              _INTL("노력치 보이기"),
              _INTL("포획률 100%"),
              _INTL("자동 낚시"),
              _INTL("박치기 확률 100%"),
              _INTL("포켓몬 창 기술 떠올리기"),
              _INTL("진화의휘석 착용시 진화X"),
              _INTL("학습장치 경험치 변경"),
              _INTL("스프레이 걸음 수 변경"),
              _INTL("노력치 총합 변경"),
              _INTL("뒤로가기")
            ]
            sub_sub_choice4 = pbMessage("\\xn[\\c[1]\\pn]\\c[1](보고 싶은 설명을 선택하자.)", sub_sub_commands4, sub_sub_commands4.size)
            break if sub_sub_choice4.nil? || sub_sub_choice4 >= sub_sub_commands4.size - 1

            case sub_sub_choice4
            when 0
              pbMessage("이 옵션이 켜져 있을 경우 포켓몬 스탯창에서 확인키(C, 스페이스바)를 누르면 종족값과 노력치가 보입니다.")
            when 1
              pbMessage("이 옵션이 켜져 있을 경우 포켓몬 포획률이 100%로 바뀝니다.")
            when 2
              pbMessage("이 옵션이 켜져 있을 경우 낚시를 할 때 확인키를 누르지 않아도 자동으로 낚시합니다.")
            when 3
              pbMessage("이 옵션이 켜져 있을 경우 나무에 박치기 사용시 100% 확률로 야생 포켓몬이 등장합니다.")
            when 4
              pbMessage("이 옵션이 켜져 있을 경우 포켓몬 선택 창에서 기술떠올리기or기술배우기가 가능해집니다.")
            when 5
              pbMessage("이 옵션이 켜져 있을 경우 진화의휘석을 지닌 포켓몬은 진화를 하지 않습니다.")              
            when 6  
              pbMessage("학습장치 경험치량을 조절할 수 있습니다. 적용이 안 될경우 학습장치를 껐다가 켜주세요.")              
            when 7  
              pbMessage("최대 스프레이 걸음 수를 바꿀 수 있습니다. (최소 100 / 최대 1000) \\n기본 스프레이 값을 설정하는 것이며 실버는 2배, 골드는 3배 수치입니다.")
            when 8
              pbMessage("최대 노력치 합을 원하는대로 바꿀 수 있습니다. (최소 510 / 최대 1512) \\n단, 현재 합보다 높으면 오류가 날 가능성이 있습니다.")                            
            end   # sub_sub_choice case 끝
          end   # 기타 설정 loop 끝         
        end   # sub_choice case 끝
      end   # 설명 서브 메뉴 loop 끝

    when 1
      if !$game_switches[155]
        $game_switches[155] = true
        pbReceiveItem(:MEGARING)
        pbReceiveItem(:ZRING)
        pbReceiveItem(:DYNAMAXBAND)
        pbReceiveItem(:TERAORB)
        pbMessage("\\xn[\\c[1]\\pn]\\c[1](배틀기믹 도구는 상점에서 구매하자.)")
        $game_switches[142] = true
      else
        # 배틀기믹 상점
        loop do
          sub_commands2 = [
            _INTL("메가스톤"),
            _INTL("Z크리스탈"),
            _INTL("다이버섯, 테라피스"),
            _INTL("뒤로가기")
          ]
          sub_choice2 = pbMessage("\\xn[\\c[1]\\pn]\\c[1](무엇을 구매할까?)", sub_commands2, sub_commands2.size)
          break if sub_choice2.nil? || sub_choice2 >= sub_commands2.size - 1

          case sub_choice2
          when 0 then pbPokemonMart2
          when 1 then pbPokemonMart3
          when 2 then pbPokemonMart5
          end   # sub_choice2 case 끝
        end   # 배틀기믹 상점 loop 끝
      end   # if-else 끝

    when 2
      pbPokemonMart4   # 전설 포켓몬 도구 상점

    when 3
      # 기타 설정 메뉴
      loop do
        text = if $game_switches[257] && $game_switches[258]
         "둘다"
       elsif $game_switches[257]
         "테라"
       elsif $game_switches[258]
         "다맥"
       else
         "X"
       end
        sub_sub_commands2 = [
          _INTL("배틀 후 자동회복 ({1})", $game_switches[251] ? _INTL("O") : _INTL("X")),
          _INTL("1회용 도구 유지 ({1})", $game_switches[260] ? _INTL("O") : _INTL("X")),
          _INTL("PWT, 배틀타워 금지 제거 ({1})", $game_switches[256] ? _INTL("O") : _INTL("X")),
          _INTL("테라or다맥 도구 자유 ({1})", text),
          _INTL("트레이너 배틀 가방 금지 ({1})", $game_switches[259] ? _INTL("O") : _INTL("X")),
          _INTL("메진 배틀당 1회 제한 해제 ({1})", $game_variables[147] == 0 ? "X" : "O"),
          _INTL("다맥 배틀당 1회 제한 해제 ({1})", $game_variables[146] == 0 ? "X" : "O"),
          _INTL("테라 배틀당 1회 제한 해제 ({1})", $game_variables[145] == 0 ? "X" : "O"),
          _INTL("딸피 BGM 끄기 ({1})", $game_variables[151] == 0 ? "X" : "O"),
          _INTL("날씨도구 착용시 날씨 무한지속 ({1})", $game_variables[129] == 0 ? "X" : "O"),
          _INTL("전투 중 포켓몬 타입 표시 ({1})", $game_switches[279] ? _INTL("O") : _INTL("X")),
          _INTL("전투 중 기술 효과 표시 ({1})", $game_switches[280] ? _INTL("O") : _INTL("X")),
          _INTL("뒤로가기")
        ]
        sub_sub_choice2 = pbMessage("\\xn[\\c[1]\\pn]\\c[1](필요한 설정을 켜자.)\\nO는 켜짐, X는 꺼짐", sub_sub_commands2, sub_sub_commands2.size)
        break if sub_sub_choice2.nil? || sub_sub_choice2 >= sub_sub_commands2.size - 1

        case sub_sub_choice2
        when 0
          $game_switches[251] = !$game_switches[251]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](배틀 후 자동회복 옵션을 #{$game_switches[251] ? '켰다' : '껐다'}.)")
        when 1
          $game_switches[260] = !$game_switches[260]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](1회용 도구 유지 옵션을 #{$game_switches[260] ? '켰다' : '껐다'}.)")
        when 2
          $game_switches[256] = !$game_switches[256]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](PWT, 배틀타워 금지 제거 옵션을 #{$game_switches[256] ? '켰다' : '껐다'}.)")
        when 3
          if !$game_switches[257] && !$game_switches[258]
            # 둘 다 꺼져 있으면 257 켬
            $game_switches[257] = true
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](테라스탈 도구 자유 옵션을 켰다.)")
          elsif $game_switches[257] && !$game_switches[258]
            # 257 켜져 있고 258 꺼져 있으면 257 끄고 258 켬
            $game_switches[257] = false
            $game_switches[258] = true
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](다이맥스 도구 자유 옵션을 켰다. 대신 테라스탈 도구 자유 옵션은 꺼졌다.)")
          elsif !$game_switches[257] && $game_switches[258]
            # 257 꺼져 있고 258 켜져 있으면 둘 다 끔
            $game_switches[257] = false
            $game_switches[258] = false
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](테라스탈or다이맥스 도구 자유 옵션을 껐다.)")
          end
        when 4
          $game_switches[259] = !$game_switches[259]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](트레이너 배틀 가방 금지 옵션을 #{$game_switches[259] ? '켰다' : '껐다'}.)")
        when 5
          $game_variables[147] = ($game_variables[147] + 1) % 2
          case $game_variables[147]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](메가진화 배틀당 1회 제한 해제 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](메가진화 배틀당 1회 제한 해제 옵션을 켰다.)")
          end
        when 6
          $game_variables[146] = ($game_variables[146] + 1) % 2
          case $game_variables[146]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](다이맥스 배틀당 1회 제한 해제 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](다이맥스 배틀당 1회 제한 해제 옵션을 켰다.)")
          end
        when 7
          $game_variables[145] = ($game_variables[145] + 1) % 2
          case $game_variables[145]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](테라스탈 배틀당 1회 제한 해제 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](테라스탈 배틀당 1회 제한 해제 옵션을 켰다.)")
          end    
        when 8
          $game_variables[151] = ($game_variables[151] + 1) % 2
          case $game_variables[151]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](딸피 BGM 끄기 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](딸피 BGM 끄기 옵션을 켰다.)")
          end  
        when 9
          $game_variables[129] = ($game_variables[129] + 1) % 2
          case $game_variables[129]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](날씨 관련 도구착용시 날씨 무한지속 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](날씨 관련 도구착용시 날씨 무한지속 옵션을 켰다.)")
          end
        when 10
          $game_switches[279] = !$game_switches[279]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](타입 표시 옵션을 #{$game_switches[279] ? '켰다' : '껐다'}.)")    
        when 11
          $game_switches[280] = !$game_switches[280]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1] (기술 효과 옵션을 #{$game_switches[280] ? '켰다' : '껐다'}.)")
        end   # sub_sub_choice2 case 끝
      end   # 기타 설정 메뉴 loop 끝

    when 4
      # 기타 설정 메뉴
      loop do
        sub_sub_commands3 = [
          _INTL("노력치 보이기 ({1})", $game_switches[61] ? _INTL("O") : _INTL("X")),
          _INTL("포획률 100% ({1})", $game_switches[252] ? _INTL("O") : _INTL("X")),
          _INTL("자동 낚시 ({1})", $game_switches[276] ? _INTL("O") : _INTL("X")),
          _INTL("박치기 확률 100% ({1})", $game_variables[148] == 0 ? "X" : "O"),
          _INTL("포켓몬 창 기술 떠올리기 ({1})", $game_variables[144] == 0 ? "X" : "O"),
          _INTL("진화의 휘석 착용시 진화X ({1})", $game_variables[130] == 0 ? "X" : "O"),
          _INTL("학습장치 경험치 변경 ({1}%)", [50, 75, 100][$game_variables[143]]),   # ← 이 줄 수정됨!
          _INTL("스프레이 걸음 수 변경 ({1})", $game_variables[149] == 0 ? 100 : $game_variables[149]),
          _INTL("노력치 총합 변경 ({1})", $game_variables[150] == 0 ? 510 : $game_variables[150]),
          _INTL("뒤로가기")
        ]
        sub_sub_choice3 = pbMessage("\\xn[\\c[1]\\pn]\\c[1](필요한 설정을 켜자.)\\nO는 켜짐, X는 꺼짐 / 숫자는 현재 수치", sub_sub_commands3, sub_sub_commands3.size)
        break if sub_sub_choice3.nil? || sub_sub_choice3 >= sub_sub_commands3.size - 1

        case sub_sub_choice3
        when 0
          $game_switches[61] = !$game_switches[61]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](노력치 보이기 옵션을 #{$game_switches[61] ? '켰다' : '껐다'}.)")
        when 1
          $game_switches[252] = !$game_switches[252]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](포획률 100% 옵션을 #{$game_switches[252] ? '켰다' : '껐다'}.)")
        when 2
          $game_switches[276] = !$game_switches[276]
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](자동 낚시 옵션을 #{$game_switches[276] ? '켰다' : '껐다'}.)")
        when 3
          $game_variables[148] = ($game_variables[148] + 1) % 2
          case $game_variables[148]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](박치기 100% 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](박치기 100% 옵션을 켰다.)")
          end
        when 4
          $game_variables[144] = ($game_variables[144] + 1) % 2
          case $game_variables[144]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](포켓몬 창에서 기술 떠올리기 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](포켓몬 창에서 기술 떠올리기 옵션을 켰다.)")
          end
        when 5
          $game_variables[130] = ($game_variables[130] + 1) % 2
          case $game_variables[130]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](진화의휘석 지닌 포켓몬 진화금지 옵션을 껐다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](진화의휘석 지닌 포켓몬 진화금지 옵션을 켰다.)")
          end        
        when 6
          $game_variables[143] = ($game_variables[143] + 1) % 3
          case $game_variables[143]
           when 0
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](학습장치 경험치가 50%가 되었다.)")
           when 1
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](학습장치 경험치가 75%가 되었다.)")
           when 2
            pbMessage("\\xn[\\c[1]\\pn]\\c[1](학습장치 경험치가 100%가 되었다.)")            
          end        
        when 7
          pbCustomRepel       
        when 8
          pbSetEVLimit          
        end   # sub_sub_choice2 case 끝
      end   # 기타 설정 메뉴 loop 끝
		when 5
      pbCustomR
    when 6
      pbCustomE
      break
    end   # choice case 끝
  end   # 메인 메뉴 loop 끝
end   # def 끝


#=========================
def pbCustomC
  loop do
    sub_commands = [
      _INTL("디버그 모드 ({1})", $game_switches[274] ? _INTL("O") : _INTL("X")),
      _INTL("취소"),
        ]
        sub_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1](필요한 설정을 켜자.)\\nO는 켜짐, X는 꺼짐", sub_commands, sub_commands.size)
        break if sub_choice.nil? || sub_choice >= sub_commands.size - 1

        case sub_choice
        when 0
          $game_switches[274] = !$game_switches[274]
          if $game_switches[274]
            $DEBUG=true
          else
            $DEBUG=false
          end
          pbMessage("\\xn[\\c[1]\\pn]\\c[1](디버그 모드를 #{$game_switches[274] ? '켰다' : '껐다'}.)")
        end
      end
    end
    
#==========================================================|
def pbCustomRepel
  params = ChooseNumberParams.new
  params.setRange(100, 1000)          # 최대치 범위
  params.setDefaultValue($game_variables[149] > 0 ? $game_variables[149] : 100)
  params.setCancelValue(nil)          # 취소하면 nil 반환
  
  current_limit = $game_variables[149] > 0 ? $game_variables[149] : 100
  f = pbMessageChooseNumber("\\xn[\\c[1]\\pn]\\c[1](스프레이 최대 걸음수를 몇으로 할까?)\\n현재: #{current_limit}, (최소 100 / 최대 1000)", params)
  
 return if f.nil? || f == current_limit
  
    $game_variables[149] = f
    pbMessage(_INTL("\\xn[\\c[1]\\pn]\\c[1](스프레이 걸음수가 {1}으로 변경됐다!)", f))
    pbMessage("\\xn[\\c[1]\\pn]\\c[1](일반 스프레이 기준이며, 실버는 2배, 골드는 3배 수치입니다.)")
  end
#=============================================================
def pbPokeballedit(pkmn)
  return if !pkmn
  return if !pkmn.poke_ball  # 포켓몬에 볼이 없으면 종료

  # 기존 볼 제외한 변경 가능한 볼 목록
  balls = []
  GameData::Item.each do |i|
    balls.push([i.id, i.name]) if i.is_poke_ball? && i.id != pkmn.poke_ball
  end
  return if balls.empty?

  hisui_balls = [:HISUIANPOKEBALL, :HISUIANGREATBALL, :HISUIANULTRABALL]

  commands = balls.map do |b|
    name = b[1]
    name += "(히스이)" if hisui_balls.include?(b[0])
    name
  end

  choice = pbMessage("어떤 볼로 바꿀래?", commands)
  return if choice < 0  # 취소

  selected_ball = balls[choice]


  selected_name = selected_ball[1]
  selected_name += "(히스이)" if hisui_balls.include?(selected_ball[0])

  pkmn.poke_ball = selected_ball[0]
  pbMessage("#{pkmn.name}의 볼이 #{selected_name}로 바뀌었어!")
end



