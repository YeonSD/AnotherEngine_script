class Pokemon
  #=============================================================================
  # Mega Evolution
  # NOTE: These are treated as form changes in Essentials.
  #=============================================================================
  def getMegaForm
    if @species == :ZYGARDE && [2].include?(form_simple)
      GameData::Species.each do |data|
        next if data.species != @species
        if data.mega_stone && hasItem?(data.mega_stone)
          return 4
        elsif data.mega_move && hasMove?(data.mega_move)
          return 4
        end
      end
    end
    if @species == :ZYGARDE && [3].include?(form_simple)
      GameData::Species.each do |data|
        next if data.species != @species
        if data.mega_stone && hasItem?(data.mega_stone)
          return 5
        elsif data.mega_move && hasMove?(data.mega_move)
          return 5
        end
      end
    end
    if @species == :FLOETTE && [5].include?(form_simple)
      GameData::Species.each do |data|
        next if data.species != @species
        if data.mega_stone && hasItem?(data.mega_stone)
          return 6
        elsif data.mega_move && hasMove?(data.mega_move)
          return 6
        end
      end
    end
  
    ret = 0
    GameData::Species.each do |data|
      next if data.species != @species || data.unmega_form != form_simple
      if data.mega_stone && hasItem?(data.mega_stone)
        ret = data.form
        break
      elsif data.mega_move && hasMove?(data.mega_move)
        ret = data.form
        break
      end
    end
    return ret   # form number, or 0 if no accessible Mega form
  end

  def getUnmegaForm
    return (mega?) ? species_data.unmega_form : -1
  end

  def hasMegaForm?
    megaForm = self.getMegaForm
    return megaForm > 0 && megaForm != form_simple
  end

  def mega?
    return (species_data.mega_stone || species_data.mega_move) ? true : false
  end

  def makeMega
    megaForm = self.getMegaForm
    self.form = megaForm if megaForm > 0
  end

  def makeUnmega
		alwaysMega = $player.always_mega || 0
		if alwaysMega == 2 || alwaysMega == 1 && self.species_data.mega_stone && self.hasItem?(self.species_data.mega_stone)
      return
    end
    unmegaForm = self.getUnmegaForm
    self.form = unmegaForm if unmegaForm >= 0
  end

  def megaName
    formName = species_data.form_name
    return (formName && !formName.empty?) ? formName : _INTL("Mega {1}", species_data.name)
  end

  # 0=default message, 1=Rayquaza message.
  def megaMessage
    megaForm = self.getMegaForm
    message_number = GameData::Species.get_species_form(@species, megaForm)&.mega_message
    return message_number || 0
  end

  #=============================================================================
  # Primal Reversion
  # NOTE: These are treated as form changes in Essentials.
  #=============================================================================
  def hasPrimalForm?
    v = MultipleForms.call("getPrimalForm", self)
    return !v.nil?
  end

  def primal?
    v = MultipleForms.call("getPrimalForm", self)
    return !v.nil? && v == @form
  end

  def makePrimal
    v = MultipleForms.call("getPrimalForm", self)
    self.form = v if !v.nil?
  end

  def makeUnprimal
		alwaysMega = $player.always_mega || 0
		if alwaysMega == 2
      return
    elsif alwaysMega == 1 && self.species == :GROUDON && self.hasItem?(:REDORB) || alwaysMega == 0 && self.species == :KYOGRE && self.hasItem?(:BLUEORB)
			return
		end
    v = MultipleForms.call("getUnprimalForm", self)
    if !v.nil?
      self.form = v
    elsif primal?
      self.form = 0
    end
		if self.species.include?("GROUDON")
			self.form = 0
		elsif self.species.include?("KYOGRE")
			self.form = 0
		end
  end
end
