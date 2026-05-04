module GameData
  class EggGroup
    attr_reader :id
    attr_reader :real_name
    attr_reader :name_k          # ← 여기 추가
    
    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id        = hash[:id]
      @real_name = hash[:name] || "Unnamed"
      @name_k    = hash[:name_k]        || @real_name   # ← 기본값은 영어 이름
    end

    # @return [String] the translated name of this egg group
    def name
      return _INTL(@real_name)
    end
    def name_k
      return _INTL(@name_k)
    end    
  end
end

#===============================================================================

GameData::EggGroup.register({
  :id   => :Undiscovered,
  :name => _INTL("Undiscovered"),
  :name_k => _INTL("미발견")
})

GameData::EggGroup.register({
  :id   => :Monster,
  :name => _INTL("Monster"),
  :name_k => _INTL("괴수")  
})

GameData::EggGroup.register({
  :id   => :Water1,
  :name => _INTL("Water 1"),
  :name_k => _INTL("수중 1")  
})

GameData::EggGroup.register({
  :id   => :Bug,
  :name => _INTL("Bug"),
  :name_k => _INTL("벌레")  
})

GameData::EggGroup.register({
  :id   => :Flying,
  :name => _INTL("Flying"),
  :name_k => _INTL("비행")  
})

GameData::EggGroup.register({
  :id   => :Field,
  :name => _INTL("Field"),
  :name_k => _INTL("육상")  
})

GameData::EggGroup.register({
  :id   => :Fairy,
  :name => _INTL("Fairy"),
  :name_k => _INTL("요정")  
})

GameData::EggGroup.register({
  :id   => :Grass,
  :name => _INTL("Grass"),
  :name_k => _INTL("식물")  
})

GameData::EggGroup.register({
  :id   => :Humanlike,
  :name => _INTL("Humanlike"),
  :name_k => _INTL("인간형")  
})

GameData::EggGroup.register({
  :id   => :Water3,
  :name => _INTL("Water 3"),
  :name_k => _INTL("수중 3")  
})

GameData::EggGroup.register({
  :id   => :Mineral,
  :name => _INTL("Mineral"),
  :name_k => _INTL("광물")  
})

GameData::EggGroup.register({
  :id   => :Amorphous,
  :name => _INTL("Amorphous"),
  :name_k => _INTL("부정형")  
})

GameData::EggGroup.register({
  :id   => :Water2,
  :name => _INTL("Water 2"),
  :name_k => _INTL("수중 2")  
})

GameData::EggGroup.register({
  :id   => :Ditto,
  :name => _INTL("Ditto"),
  :name_k => _INTL("메타몽")  
})

GameData::EggGroup.register({
  :id   => :Dragon,
  :name => _INTL("Dragon"),
  :name_k => _INTL("드래곤")  
})
