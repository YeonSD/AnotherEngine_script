class PokemonMartScreen
  alias force_badge_items_init initialize
  
  def initialize(scene, stock)
    # 뱃지가 3개 이상일 때
    if $player && $player.badge_count >= 3
      
      # 상점에 강제로 띄울 아이템 (원하시는 아이템 내부 이름으로 수정해주세요)
      force_items = [:ADAPTIVELEVELCANDY] 
      
      force_items.each do |item|
        # 상점 목록에 해당 아이템이 없으면 무조건 강제로 추가함
        stock.push(item) unless stock.include?(item)
      end
    end
    
    # 기존 상점 초기화 기능 정상 실행
    force_badge_items_init(scene, stock)
  end
end