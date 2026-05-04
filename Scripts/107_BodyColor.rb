# NOTE: The order these colors are registered are the order they are listed in
#       the Pokédex search screen.
module GameData
  class BodyColor
    attr_reader :id
    attr_reader :real_name
    attr_reader :name_k  # ← 여기 추가

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id        = hash[:id]
      @real_name = hash[:name] || "Unnamed"
      @name_k    = hash[:name_k] || @real_name  # ← 기본값은 영어 이름
    end

    # @return [String] the translated name of this body color
    def name
      return _INTL(@real_name)
    end
    def name_k
      return _INTL(@name_k)
    end    
  end
end

#===============================================================================

GameData::BodyColor.register({
  :id   => :Red,
  :name => _INTL("Red"),
  :name_k => _INTL("빨간색")
})

GameData::BodyColor.register({
  :id   => :Blue,
  :name => _INTL("Blue"),
  :name_k => _INTL("파란색")
})

GameData::BodyColor.register({
  :id   => :Yellow,
  :name => _INTL("Yellow"),
  :name_k => _INTL("노란색")
})

GameData::BodyColor.register({
  :id   => :Green,
  :name => _INTL("Green"),
  :name_k => _INTL("초록색")
})

GameData::BodyColor.register({
  :id   => :Black,
  :name => _INTL("Black"),
  :name_k => _INTL("검정색")
})

GameData::BodyColor.register({
  :id   => :Brown,
  :name => _INTL("Brown"),
  :name_k => _INTL("갈색")
})

GameData::BodyColor.register({
  :id   => :Purple,
  :name => _INTL("Purple"),
  :name_k => _INTL("보라색")
})

GameData::BodyColor.register({
  :id   => :Gray,
  :name => _INTL("Gray"),
  :name_k => _INTL("회색")
})

GameData::BodyColor.register({
  :id   => :White,
  :name => _INTL("White"),
  :name_k => _INTL("하얀색")
})

GameData::BodyColor.register({
  :id   => :Pink,
  :name => _INTL("Pink"),
  :name_k => _INTL("분홍색")
})
