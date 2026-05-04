# ==============================================================================
# 플레이어 클래스 확장: 랜덤 스위치 변수 관리
# ==============================================================================
class Player
  # 관장 타입 랜덤 스위치 (읽기/쓰기 허용)
  attr_accessor :random_gym_switch3
  
  # [추가] 신규: 종족값 & 특성 고정 랜덤 통합 스위치
  attr_accessor :random_stats_new_switch
  attr_accessor :random_ability_new_switch

  # 상대 기술 랜덤 스위치 (쓰기 허용)
  attr_writer :random_move_switch3

  # 플레이어 객체 생성 시 초기화
  alias gym_random_init initialize
  def initialize(*args)
    gym_random_init(*args)
    @random_gym_switch3 = false # [기본값: OFF]
    
    # [추가] 신규 스위치들의 기본값을 ON(true)으로 설정
    @random_stats_new_switch = true
    @random_ability_new_switch = true
  end

  # 상대 기술 랜덤 스위치 Getter (nil일 경우 true 반환)
  def random_move_switch3
    @random_move_switch3 = true if @random_move_switch3.nil?
    return @random_move_switch3
  end
end

# ==============================================================================
# 랜덤 설정 변경 메뉴 함수
# ==============================================================================
def pbToggleRandomSettings
  # [초기화] 전역 변수나 객체 변수가 비어있을(nil) 경우 초기값 세팅
  $player.random_gym_switch3        = false if $player.random_gym_switch3.nil?
  $player.random_move_switch3       = true  if $player.random_move_switch3.nil?
  $random_item_switch               = true  if $random_item_switch.nil? # [켜짐 상태]
  $random_move_switch               = true  if $random_move_switch.nil?
  
  # [추가] 신규 스위치 초기화 (기존 세이브 파일을 불러올 때 에러 방지용)
  $player.random_stats_new_switch   = true  if $player.random_stats_new_switch.nil?
  $player.random_ability_new_switch = true  if $player.random_ability_new_switch.nil?

  loop do
    # 1. 현재 상태 텍스트 준비
    s_type   = $player.random_gym_switch3 ? "[ON]" : "[OFF]"
    s_move3  = $player.random_move_switch3 ? "[ON]" : "[OFF]"
    s_item   = $random_item_switch ? "[ON]" : "[OFF]"
    s_learn  = $random_move_switch ? "[ON]" : "[OFF]"
    # [추가] 신규 스위치 상태 텍스트
    s_stats  = $player.random_stats_new_switch ? "[ON]" : "[OFF]"
    s_ability= $player.random_ability_new_switch ? "[ON]" : "[OFF]"

    # 2. 메뉴 선택지 구성
    commands = [
      _INTL("관장 타입고정 랜덤 {1}", s_type),
      _INTL("상대 기술 랜덤화 {1}", s_move3),
      _INTL("아이템 랜덤 모드 {1}", s_item),
      _INTL("기술 배우기 랜덤화 {1}", s_learn),
      _INTL("종족값 고정 랜덤 모드 {1}", s_stats),    # [추가]
      _INTL("특성 고정 랜덤 모드 {1}", s_ability),  # [추가]
      _INTL("그만두기")
    ]

    # 3. 메시지 창 출력 및 입력 받기
    command = pbMessage(_INTL("어떤 설정을 변경하시겠습니까?"), commands, -1)

    case command
    when 0 # 관장 타입고정 랜덤 토글
      $player.random_gym_switch3 = !$player.random_gym_switch3
      pbMessage(_INTL("관장 타입고정 랜덤이 {1} 되었습니다.", $player.random_gym_switch3 ? "[ON]" : "[OFF]"))
      
    when 1 # 상대 기술 랜덤화 토글
      $player.random_move_switch3 = !$player.random_move_switch3 
      pbMessage(_INTL("상대 기술 랜덤화가 {1} 되었습니다.", $player.random_move_switch3 ? "[ON]" : "[OFF]"))
      
    when 2 # 랜덤 아이템 모드 토글
      $random_item_switch = !$random_item_switch
      pbMessage(_INTL("아이템 랜덤 모드가 {1} 되었습니다.", $random_item_switch ? "[ON]" : "[OFF]"))
      
    when 3 # 기술 배우기 시스템 토글
      $random_move_switch = !$random_move_switch
      pbMessage(_INTL("기술 배우기 시스템이 {1} 되었습니다.", $random_move_switch ? "[ON]" : "[OFF]"))
      
    # [추가] 종족값 고정 랜덤 토글
    when 4
      $player.random_stats_new_switch = !$player.random_stats_new_switch
      pbMessage(_INTL("종족값 고정 랜덤 모드가 {1} 되었습니다.", $player.random_stats_new_switch ? "[ON]" : "[OFF]"))
      
    # [추가] 특성 고정 랜덤 토글
    when 5
      $player.random_ability_new_switch = !$player.random_ability_new_switch
      pbMessage(_INTL("특성 고정 랜덤 모드가 {1} 되었습니다.", $player.random_ability_new_switch ? "[ON]" : "[OFF]"))
      
    else 
      # "그만두기"를 누르거나 창을 닫으면 반복 종료
      break
    end
  end
end