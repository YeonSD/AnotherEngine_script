# NOTE: The order these shapes are registered are the order they are listed in
#       the Pokédex search screen.
#       "Graphics/UI/Pokedex/icon_shapes.png" contains icons for these
#       shapes.
module GameData
  class BodyShape
    attr_reader :id
    attr_reader :real_name
    attr_reader :icon_position   # Where this shape's icon is within icon_shapes.png
    attr_reader :name_k          # ← 여기 추가

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id            = hash[:id]
      @real_name     = hash[:name]          || "Unnamed"
      @name_k        = hash[:name_k]        || @real_name   # ← 기본값은 영어 이름
      @icon_position = hash[:icon_position] || 0
    end

    # @return [String] the translated name of this body shape
    def name
      return _INTL(@real_name)
    end
    def name_k
      return _INTL(@name_k)
    end
  end
end

#===============================================================================

GameData::BodyShape.register({
  :id            => :Head,
  :name          => _INTL("Head"),
  :name_k        => _INTL("머리"),
  :icon_position => 0
})

GameData::BodyShape.register({
  :id            => :Serpentine,
  :name          => _INTL("Serpentine"),
  :name_k        => _INTL("뱀과 같은 몸"),
  :icon_position => 1
})

GameData::BodyShape.register({
  :id            => :Finned,
  :name          => _INTL("Finned"),
  :name_k        => _INTL("지느러미"),
  :icon_position => 2
})

GameData::BodyShape.register({
  :id            => :HeadArms,
  :name          => _INTL("Head and arms"),
  :name_k        => _INTL("머리와 팔"),
  :icon_position => 3
})

GameData::BodyShape.register({
  :id            => :HeadBase,
  :name          => _INTL("Head and base"),
  :name_k        => _INTL("머리와 몸"),
  :icon_position => 4
})

GameData::BodyShape.register({
  :id            => :BipedalTail,
  :name          => _INTL("Bipedal with tail"),
  :name_k        => _INTL("두개의 발과 꼬리"),
  :icon_position => 5
})

GameData::BodyShape.register({
  :id            => :HeadLegs,
  :name          => _INTL("Head and legs"),
  :name_k        => _INTL("머리와 다리"),
  :icon_position => 6
})

GameData::BodyShape.register({
  :id            => :Quadruped,
  :name          => _INTL("Quadruped"),
  :name_k        => _INTL("네개의 발"),
  :icon_position => 7
})

GameData::BodyShape.register({
  :id            => :Winged,
  :name          => _INTL("Winged"),
  :name_k        => _INTL("날개"),
  :icon_position => 8
})

GameData::BodyShape.register({
  :id            => :Multiped,
  :name          => _INTL("Multiped"),
  :name_k        => _INTL("여러개의 발"),
  :icon_position => 9
})

GameData::BodyShape.register({
  :id            => :MultiBody,
  :name          => _INTL("Multi Body"),
  :name_k        => _INTL("여러개의 몸"),
  :icon_position => 10
})

GameData::BodyShape.register({
  :id            => :Bipedal,
  :name          => _INTL("Bipedal"),
  :name_k        => _INTL("두개의 발"),
  :icon_position => 11
})

GameData::BodyShape.register({
  :id            => :MultiWinged,
  :name          => _INTL("Multi Winged"),
  :name_k        => _INTL("여러개의 날개"),
  :icon_position => 12
})

GameData::BodyShape.register({
  :id            => :Insectoid,
  :name          => _INTL("Insectoid"),
  :name_k        => _INTL("곤충 같은 몸"),
  :icon_position => 13
})
