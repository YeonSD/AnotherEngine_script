def pbChooseOneSpecialItem
  loop do
    # 1. 큰 카테고리 선택
    categories = [
      _INTL("메가스톤 고르기"),
      _INTL("전용 도구 고르기"),
      _INTL("플레이트 고르기"),
      _INTL("실버디 메모리 고르기"),
      _INTL("닫기")
    ]
    cat_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1](어떤 종류의 도구를 살펴볼까?)", categories, -1)
    break if cat_choice == -1 || cat_choice == 4

    items_to_show = []
    
    # 2. 선택한 카테고리에 맞는 아이템 리스트 불러오기
    case cat_choice
    when 0
      items_to_show = [
    :VENUSAURITE, :CHARIZARDITEX, :CHARIZARDITEY, :BLASTOISINITE, :BEEDRILLITE,
    :PIDGEOTITE, :ALAKAZITE, :SLOWBRONITE, :GENGARITE, :KANGASKHANITE,
    :PINSIRITE, :GYARADOSITE, :AERODACTYLITE, :DRAGONITENITE, :MEGANIUMITE, :FERALIGITE,
    :AMPHAROSITE, :STEELIXITE, :SCIZORITE, :HERACRONITE, :HOUNDOOMINITE,
    :TYRANITARITE, :SCEPTILITE, :BLAZIKENITE, :SWAMPERTITE, :GARDEVOIRITE,
    :SABLENITE, :MAWILITE, :AGGRONITE, :MEDICHAMITE, :MANECTITE, :SHARPEDONITE,
    :CAMERUPTITE, :ALTARIANITE, :BANETTITE, :ABSOLITE, :GLALITITE, :SALAMENCITE,
    :METAGROSSITE, :LOPUNNITE, :GARCHOMPITE, :LUCARIONITE, :DIANCITE,
    :ABOMASITE, :GALLADITE, :EMBOARITE, :AUDINITE, :DRAMPANITE, :LATIASITE, :LATIOSITE, :MEWTWONITEX, :MEWTWONITEY,
    :CLEFABLITE, :VICTREEBELITE, :STARMINITE, :SKARMORITE, :FROSLASSITE,
    :EXCADRITE, :SCOLIPITE, :SCRAFTINITE, :EELEKTROSSITE, :CHANDELURITE,
    :CHESNAUGHTITE, :DELPHOXITE, :GRENINJITE, :PYROARITE, :FLOETTITE,
    :MALAMARITE, :BARBARACITE, :DRAGALGITE, :HAWLUCHANITE, :ZYGARDITE,
    :FALINKSITE, :RAICHUNITEX, :RAICHUNITEY, :CHIMECHITE, :ABSOLITEZ,
    :STARAPTITE, :GARCHOMPITEZ, :LUCARIONITEZ, :HEATRANITE, :DARKRANITE,
    :GOLURKITE, :MEOWSTICITE, :CRABOMINITE, :GOLISOPITE, :MAGEARNITE,
    :ZERAORITE, :SCOVILLAINITE, :GLIMMORANITE, :TATSUGIRINITE, :BAXCALIBRITE
     ]
    when 1
      items_to_show = [
        :ADAMANTORB, :ADAMANTCRYSTAL, :LUSTROUSORB, :LUSTROUSGLOBE,
        :GRISEOUSORB, :GRISEOUSCORE, :RUSTEDSWORD, :RUSTEDSHIELD,
        :BOOSTERENERGY, :HEARTHFLAMEMASK, :CORNERSTONEMASK, :WELLSPRINGMASK, :SOULDEW,
        :REDORB, :BLUEORB, :PRISONBOTTLE, :REVEALGLASS, :DNASPLICERS, :NSOLARIZER, :NLUNARIZER
      ]
    when 2
      items_to_show = [
        :DRACOPLATE, :DREADPLATE, :EARTHPLATE, :FISTPLATE, :FLAMEPLATE, :ICICLEPLATE,
        :INSECTPLATE, :IRONPLATE, :MINDPLATE, :PIXIEPLATE, :SKYPLATE, :SPLASHPLATE,
        :SPOOKYPLATE, :STONEPLATE, :TOXICPLATE, :ZAPPLATE, :MEADOWPLATE
      ]
    when 3
      items_to_show = [
        :BUGMEMORY, :DARKMEMORY, :DRAGONMEMORY, :ELECTRICMEMORY, :FAIRYMEMORY,
        :FIREMEMORY, :FLYINGMEMORY, :GHOSTMEMORY, :GRASSMEMORY, :GROUNDMEMORY,
        :ICEMEMORY, :POISONMEMORY, :PSYCHICMEMORY, :ROCKMEMORY, :STEELMEMORY, :WATERMEMORY
      ]
    end

    # 데이터에 존재하는 유효한 아이템만 걸러내기 (에러 방지)
    valid_items = items_to_show.select { |i| GameData::Item.exists?(i) }
    
    if valid_items.empty?
      pbMessage(_INTL("이 카테고리에는 받을 수 있는 도구가 없습니다."))
      next
    end

    # 3. 세부 아이템 선택 루프 (여러 개를 연속해서 받을 수 있게 해줌)
    loop do
      # 게임 내 실제 한글(또는 설정된 언어) 아이템 이름으로 목록 만들기
      item_names = valid_items.map { |i| GameData::Item.get(i).name }
      item_names.push(_INTL("뒤로 가기")) # 맨 마지막에 뒤로 가기 추가

      # 스크롤 가능한 선택창 띄우기
      item_choice = pbMessage("\\xn[\\c[1]\\pn]\\c[1](원하는 도구를 선택하자.)", item_names, -1)
      
      # 취소 키를 누르거나 '뒤로 가기'를 선택하면 이전 카테고리 화면으로 돌아감
      break if item_choice == -1 || item_choice == item_names.length - 1
      
      # 선택한 아이템 지급
      selected_item = valid_items[item_choice]
      $bag.add(selected_item, 1)
      
      # 어떤 아이템을 받았는지 메시지로 확인
      item_real_name = GameData::Item.get(selected_item).name
      pbMessage("\\xn[\\c[1]\\pn]\\c[1](#{item_real_name}을(를) 가방에 넣었다!)")
    end
  end
end