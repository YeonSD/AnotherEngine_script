#===============================================================================
#
#===============================================================================

# 한글용
CHOSEONG = %w[ㄱ ㄲ ㄴ ㄷ ㄸ ㄹ ㅁ ㅂ ㅃ ㅅ ㅆ ㅇ ㅈ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ]
JUNGSEONG = %w[ㅏ ㅐ ㅑ ㅒ ㅓ ㅔ ㅕ ㅖ ㅗ ㅘ ㅙ ㅚ ㅛ ㅜ ㅝ ㅞ ㅟ ㅠ ㅡ ㅢ ㅣ]
JONGSEONG = %w[ "" ㄱ ㄲ ㄳ ㄴ ㄵ ㄶ ㄷ ㄹ ㄺ ㄻ ㄼ ㄽ ㄾ ㄿ ㅀ ㅁ ㅂ ㅄ ㅅ ㅆ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ]
JJUNGSEONG_RECIPE = {
  ['ㅗ','ㅏ'] => 'ㅘ',
  ['ㅗ','ㅐ'] => 'ㅙ',
  ['ㅗ','ㅣ'] => 'ㅚ',
  ['ㅜ','ㅓ'] => 'ㅝ',
  ['ㅜ','ㅔ'] => 'ㅞ',
  ['ㅜ','ㅣ'] => 'ㅟ',
  ['ㅡ','ㅣ'] => 'ㅢ'
}
JJONGSEONG_RECIPE = {
  ['ㄱ','ㅅ'] => 'ㄳ',
  ['ㄴ','ㅈ'] => 'ㄵ',
  ['ㄴ','ㅎ'] => 'ㄶ',
  ['ㄹ','ㄱ'] => 'ㄺ',
  ['ㄹ','ㅁ'] => 'ㄻ',
  ['ㄹ','ㅂ'] => 'ㄼ',
  ['ㄹ','ㅅ'] => 'ㄽ',
  ['ㄹ','ㅌ'] => 'ㄾ',
  ['ㄹ','ㅍ'] => 'ㄿ',
  ['ㄹ','ㅎ'] => 'ㅀ',
  ['ㅂ','ㅅ'] => 'ㅄ'
}

class CharacterEntryHelper
  attr_accessor :text
  attr_accessor :maxlength
  attr_reader   :passwordChar
  attr_accessor :cursor

  def initialize(text, maxlength = -1)
    @text = text
    @maxlength = maxlength
    @passwordChar = ""
    @cursor = text.scan(/./m).length

    # 한글용
    @hangul_buffer ||= {cho: nil, jung1: nil, jung2: nil, jong1: nil, jong2: nil}
  end

  # 한글용
  def isHangulBufferEmpty?
    return !@hangul_buffer.values.any?
  end

  # 한글용
  def popHangulBuffer
    key = [:jong2, :jong1, :jung2, :jung1, :cho].find { |k| @hangul_buffer[k] }
    return nil unless key
    ch = @hangul_buffer[key]
    @hangul_buffer[key] = nil
    ch
  end

  # 한글용
  def clearHangulBuffer
    @hangul_buffer.keys.each { |k| @hangul_buffer[k] = nil }
  end

  # 한글용
  def makeJJongsung(jong_list)
    return nil if jong_list.empty?
    return jong_list[0] if jong_list.size == 1 || jong_list[1].nil?
    JJONGSEONG_RECIPE[jong_list] || nil
  end

  # 한글용
  def makeJJungsung(jung_list)
    return nil if jung_list.empty?
    return jung_list[0] if jung_list.size == 1 || jung_list[1].nil?
    JJUNGSEONG_RECIPE[jung_list] || nil
  end
  
  # 한글용
  def compose_hangul
    base = 0xAC00
    jjungsung = makeJJungsung([@hangul_buffer[:jung1], @hangul_buffer[:jung2]])
    jjongsung = makeJJongsung([@hangul_buffer[:jong1], @hangul_buffer[:jong2]])
    cho = CHOSEONG.index(@hangul_buffer[:cho]) || -1
    jung = JUNGSEONG.index(jjungsung) || -1
    jong = JONGSEONG.index(jjongsung) || 0
    return @hangul_buffer[:cho] if jung < 0
    return jjungsung if cho < 0
    code = base + (cho * 21 * 28) + (jung * 28) + jong
    return code.chr(Encoding::UTF_8)
  end

  def textChars
    chars = text.scan(/./m)
    if @passwordChar != ""
      chars.length.times { |i| chars[i] = @passwordChar }
    end
    return chars
  end

  def passwordChar=(value)
    @passwordChar = value || ""
  end

  def length
    return self.text.scan(/./m).length
  end

  # 한글용
  def canInsert?
    chars = self.text.scan(/./m)
    return false if isTextFull?
    return false if @maxlength < 0 && chars.length >= @maxlength
    return true
  end

  # 한글용
  def isTextFull?
    return @cursor >= @maxlength if @maxlength >= 0
    return false
  end

  # 한글용
  def canInsertAtCursor?(ch)
    return true if isHangulBufferEmpty?
    last_key = @hangul_buffer.compact.keys.last
    if CHOSEONG.include?(ch)
      return true if [:jung1, :jung2].include?(last_key) && @hangul_buffer[:cho] && JONGSEONG.include?(ch)
      return true if last_key == :jong1 && JJONGSEONG_RECIPE.key?([@hangul_buffer[:jong1], ch])
      clearHangulBuffer
    end
    if JUNGSEONG.include?(ch)
      return true if last_key == :cho
      return true if last_key == :jung1 && JJUNGSEONG_RECIPE.key?([@hangul_buffer[:jung1], ch])
      clearHangulBuffer unless [:jong1, :jong2].include?(last_key)
    end
    return false
  end

  # 한글용
  def insert(ch)
    chars = self.text.scan(/./m)
    return false unless canInsert?
    a = canInsertAtCursor?(ch)
    @cursor += 1 unless a
    if isTextFull?
      clearHangulBuffer
      return false
    end

    last_key = @hangul_buffer.compact.keys.last
    if CHOSEONG.include?(ch)
      target = { nil => :cho, :jung1 => :jong1, :jung2 => :jong1, :jong1 => :jong2}[last_key]
      @hangul_buffer[target] = ch if target
      ch = compose_hangul
    elsif JUNGSEONG.include?(ch)
      case last_key
      when nil, :cho
        @hangul_buffer[:jung1] = ch
      when :jung1
        @hangul_buffer[:jung2] = ch
      else
        jong = popHangulBuffer
        chars[@cursor - 1] = compose_hangul
        clearHangulBuffer
        @hangul_buffer[:cho] = jong
        @hangul_buffer[:jung1] = ch
      end
      ch = compose_hangul
    else
      clearHangulBuffer
    end

    chars[@cursor] = ch
    @text = chars.compact.join
    @cursor += 1 if isHangulBufferEmpty?
    return true
  end

  def canDelete?
    chars = self.text.scan(/./m)
    return false if chars.length <= 0 || @cursor <= 0
    return true
  end

  # 한글용
  def delete
    chars = self.text.scan(/./m)
    return false if chars.length <= 0 || @cursor < 0

    if isHangulBufferEmpty?
      chars.delete_at(@cursor - 1)
      @cursor -= 1 if @cursor > 0
    else
      popHangulBuffer
      chars[@cursor] = compose_hangul
    end
    
    @text = chars.compact.join
    return true
  end

  #-----------------------------------------------------------------------------

  private

  def ensure
    return if @maxlength < 0
    chars = self.text.scan(/./m)
    chars = chars[0, @maxlength] if chars.length > @maxlength && @maxlength >= 0
    @text = chars.compact.join
  end
end

#===============================================================================
#
#===============================================================================
class Window_TextEntry < SpriteWindow_Base
  def initialize(text, x, y, width, height, heading = nil, usedarkercolor = false)
    super(x, y, width, height)
    colors = getDefaultTextColors(self.windowskin)
    @baseColor = colors[0]
    @shadowColor = colors[1]
    if usedarkercolor
      @baseColor = Color.new(16, 24, 32)
      @shadowColor = Color.new(168, 184, 184)
    end
    @helper = CharacterEntryHelper.new(text)
    @heading = heading
    @cursor_timer_start = System.uptime
    @cursor_shown = true
    self.active = true
    refresh
  end

  def text
    @helper.text
  end

  def maxlength
    @helper.maxlength
  end

  def passwordChar
    @helper.passwordChar
  end

  def text=(value)
    @helper.text = value
    self.refresh
  end

  def passwordChar=(value)
    @helper.passwordChar = value
    refresh
  end

  def maxlength=(value)
    @helper.maxlength = value
    self.refresh
  end

  def insert(ch)
    if @helper.insert(ch)
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      self.refresh
      return true
    end
    return false
  end

  def delete
    if @helper.delete
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      self.refresh
      return true
    end
    return false
  end

  def update
    cursor_to_show = ((System.uptime - @cursor_timer_start) / 0.35).to_i.even?
    if cursor_to_show != @cursor_shown
      @cursor_shown = cursor_to_show
      refresh
    end
    return if !self.active
    # Moving cursor
    if Input.repeat?(Input::LEFT) && Input.press?(Input::ACTION)
      if @helper.cursor > 0
        @helper.cursor -= 1
        @cursor_timer_start = System.uptime
        @cursor_shown = true
        self.refresh
      end
    elsif Input.repeat?(Input::RIGHT) && Input.press?(Input::ACTION)
      if @helper.cursor < self.text.scan(/./m).length
        @helper.cursor += 1
        @cursor_timer_start = System.uptime
        @cursor_shown = true
        self.refresh
      end
    elsif Input.repeat?(Input::BACK)   # Backspace
      self.delete if @helper.cursor > 0
    end
  end

  def refresh
    self.contents = pbDoEnsureBitmap(self.contents, self.width - self.borderX,
                                     self.height - self.borderY)
    bitmap = self.contents
    bitmap.clear
    x = 0
    y = 0
    if @heading
      textwidth = bitmap.text_size(@heading).width
      pbDrawShadowText(bitmap, x, y, textwidth + 4, 32, @heading, @baseColor, @shadowColor)
      y += 32
    end
    x += 4
    width = self.width - self.borderX
    cursorcolor = Color.new(16, 24, 32)
    textscan = self.text.scan(/./m)
    scanlength = textscan.length
    @helper.cursor = scanlength if @helper.cursor > scanlength
    @helper.cursor = 0 if @helper.cursor < 0
    startpos = @helper.cursor
    fromcursor = 0
    while startpos > 0
      c = (@helper.passwordChar != "") ? @helper.passwordChar : textscan[startpos - 1]
      fromcursor += bitmap.text_size(c).width
      break if fromcursor > width - 4
      startpos -= 1
    end
    (startpos...scanlength).each do |i|
      c = (@helper.passwordChar != "") ? @helper.passwordChar : textscan[i]
      textwidth = bitmap.text_size(c).width
      next if c == "\n"
      # Draw text
      pbDrawShadowText(bitmap, x, y, textwidth + 4, 32, c, @baseColor, @shadowColor)
      # Draw cursor if necessary
      if i == @helper.cursor && @cursor_shown
        bitmap.fill_rect(x, y + 4, 2, 24, cursorcolor)
      end
      # Add x to drawn text width
      x += textwidth
    end
    if textscan.length == @helper.cursor && @cursor_shown
      bitmap.fill_rect(x, y + 4, 2, 24, cursorcolor)
    end
  end
end

#===============================================================================
#
#===============================================================================
class Window_TextEntry_Keyboard < Window_TextEntry
  def update
    cursor_to_show = ((System.uptime - @cursor_timer_start) / 0.35).to_i.even?
    if cursor_to_show != @cursor_shown
      @cursor_shown = cursor_to_show
      refresh
    end
    return if !self.active
    # Moving cursor
    if Input.triggerex?(:LEFT) || Input.repeatex?(:LEFT)
      if @helper.cursor > 0
        @helper.cursor -= 1
        @cursor_timer_start = System.uptime
        @cursor_shown = true
        self.refresh
      end
      return
    elsif Input.triggerex?(:RIGHT) || Input.repeatex?(:RIGHT)
      if @helper.cursor < self.text.scan(/./m).length
        @helper.cursor += 1
        @cursor_timer_start = System.uptime
        @cursor_shown = true
        self.refresh
      end
      return
    elsif Input.triggerex?(:BACKSPACE) || Input.repeatex?(:BACKSPACE)
      self.delete if @helper.cursor > 0
      return
    elsif Input.triggerex?(:RETURN) || Input.triggerex?(:ESCAPE)
      return
    end
    Input.gets.each_char { |c| insert(c) }
  end
end

#===============================================================================
#
#===============================================================================
class Window_MultilineTextEntry < SpriteWindow_Base
  def initialize(text, x, y, width, height)
    super(x, y, width, height)
    colors = getDefaultTextColors(self.windowskin)
    @baseColor = colors[0]
    @shadowColor = colors[1]
    @helper = CharacterEntryHelper.new(text)
    @firstline = 0
    @cursorLine = 0
    @cursorColumn = 0
    @cursor_timer_start = System.uptime
    @cursor_shown = true
    self.active = true
    refresh
  end

  attr_reader :baseColor
  attr_reader :shadowColor

  def baseColor=(value)
    @baseColor = value
    refresh
  end

  def shadowColor=(value)
    @shadowColor = value
    refresh
  end

  def text
    @helper.text
  end

  def maxlength
    @helper.maxlength
  end

  def text=(value)
    @helper.text = value
    @textchars = nil
    self.refresh
  end

  def maxlength=(value)
    @helper.maxlength = value
    @textchars = nil
    self.refresh
  end

  def insert(ch)
    @helper.cursor = getPosFromLineAndColumn(@cursorLine, @cursorColumn)
    if @helper.insert(ch)
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      @textchars = nil
      moveCursor(0, 1)
      self.refresh
      return true
    end
    return false
  end

  def delete
    @helper.cursor = getPosFromLineAndColumn(@cursorLine, @cursorColumn)
    if @helper.delete
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      moveCursor(0, -1) # use old textchars
      @textchars = nil
      self.refresh
      return true
    end
    return false
  end

  def getTextChars
    if !@textchars
      @textchars = getLineBrokenText(self.contents, @helper.text,
                                     self.contents.width, nil)
    end
    return @textchars
  end

  def getTotalLines
    textchars = getTextChars
    return 1 if textchars.length == 0
    tchar = textchars[textchars.length - 1]
    return tchar[5] + 1
  end

  def getLineY(line)
    textchars = getTextChars
    return 0 if textchars.length == 0
    totallines = getTotalLines
    line = 0 if line < 0
    line = totallines - 1 if line >= totallines
    maximumY = 0
    textchars.each do |text|
      thisline = text[5]
      y = text[2]
      return y if thisline == line
      maximumY = y if maximumY < y
    end
    return maximumY
  end

  def getColumnsInLine(line)
    textchars = getTextChars
    return 0 if textchars.length == 0
    totallines = getTotalLines
    line = 0 if line < 0
    line = totallines - 1 if line >= totallines
    endpos = 0
    textchars.each do |text|
      thisline = text[5]
      thislength = text[8]
      endpos += thislength if thisline == line
    end
    return endpos
  end

  def getPosFromLineAndColumn(line, column)
    textchars = getTextChars
    return 0 if textchars.length == 0
    totallines = getTotalLines
    line = 0 if line < 0
    line = totallines - 1 if line >= totallines
    endpos = 0
    textchars.each do |text|
      thisline = text[5]
      thispos = text[6]
      thiscolumn = text[7]
      thislength = text[8]
      next if thisline != line
      endpos = thispos + thislength
      next if column < thiscolumn || column > thiscolumn + thislength || thislength == 0
      return thispos + column - thiscolumn
    end
    return endpos
  end

  def getLastVisibleLine
    getTextChars
    textheight = [1, self.contents.text_size("X").height].max
    lastVisible = @firstline + ((self.height - self.borderY) / textheight) - 1
    return lastVisible
  end

  def updateCursorPos(doRefresh)
    # Calculate new cursor position
    @helper.cursor = getPosFromLineAndColumn(@cursorLine, @cursorColumn)
    if doRefresh
      @cursor_timer_start = System.uptime
      @cursor_shown = true
      self.refresh
    end
    @firstline = @cursorLine if @cursorLine < @firstline
    lastVisible = getLastVisibleLine
    @firstline += (@cursorLine - lastVisible) if @cursorLine > lastVisible
  end

  def moveCursor(lineOffset, columnOffset)
    # Move column offset first, then lines (since column offset
    # can affect line offset)
#   echoln ["beforemoving",@cursorLine,@cursorColumn]
    totalColumns = getColumnsInLine(@cursorLine) # check current line
    totalLines = getTotalLines
    oldCursorLine = @cursorLine
    oldCursorColumn = @cursorColumn
    @cursorColumn += columnOffset
    if @cursorColumn < 0 && @cursorLine > 0
      # Will happen if cursor is moved left from the beginning of a line
      @cursorLine -= 1
      @cursorColumn = getColumnsInLine(@cursorLine)
    elsif @cursorColumn > totalColumns && @cursorLine < totalLines - 1
      # Will happen if cursor is moved right from the end of a line
      @cursorLine += 1
      @cursorColumn = 0
    end
    # Ensure column bounds
    totalColumns = getColumnsInLine(@cursorLine)
    @cursorColumn = totalColumns if @cursorColumn > totalColumns
    @cursorColumn = 0 if @cursorColumn < 0 # totalColumns can be 0
    # Move line offset
    @cursorLine += lineOffset
    @cursorLine = 0 if @cursorLine < 0
    @cursorLine = totalLines - 1 if @cursorLine >= totalLines
    # Ensure column bounds again
    totalColumns = getColumnsInLine(@cursorLine)
    @cursorColumn = totalColumns if @cursorColumn > totalColumns
    @cursorColumn = 0 if @cursorColumn < 0 # totalColumns can be 0
    updateCursorPos(oldCursorLine != @cursorLine || oldCursorColumn != @cursorColumn)
#   echoln ["aftermoving",@cursorLine,@cursorColumn]
  end

  def update
    cursor_to_show = ((System.uptime - @cursor_timer_start) / 0.35).to_i.even?
    if cursor_to_show != @cursor_shown
      @cursor_shown = cursor_to_show
      refresh
    end
    return if !self.active
    # Moving cursor
    if Input.triggerex?(:UP) || Input.repeatex?(:UP)
      moveCursor(-1, 0)
      return
    elsif Input.triggerex?(:DOWN) || Input.repeatex?(:DOWN)
      moveCursor(1, 0)
      return
    elsif Input.triggerex?(:LEFT) || Input.repeatex?(:LEFT)
      moveCursor(0, -1)
      return
    elsif Input.triggerex?(:RIGHT) || Input.repeatex?(:RIGHT)
      moveCursor(0, 1)
      return
    end
    if Input.press?(Input::CTRL) && Input.triggerex?(:HOME)
      # Move cursor to beginning
      @cursorLine = 0
      @cursorColumn = 0
      updateCursorPos(true)
      return
    elsif Input.press?(Input::CTRL) && Input.triggerex?(:END)
      # Move cursor to end
      @cursorLine = getTotalLines - 1
      @cursorColumn = getColumnsInLine(@cursorLine)
      updateCursorPos(true)
      return
    elsif Input.triggerex?(:RETURN) || Input.repeatex?(:RETURN)
      self.insert("\n")
      return
    elsif Input.triggerex?(:BACKSPACE) || Input.repeatex?(:BACKSPACE)   # Backspace
      self.delete
      return
    end
    Input.gets.each_char { |c| insert(c) }
  end

  def refresh
    newContents = pbDoEnsureBitmap(self.contents, self.width - self.borderX,
                                   self.height - self.borderY)
    @textchars = nil if self.contents != newContents
    self.contents = newContents
    bitmap = self.contents
    bitmap.clear
    getTextChars
    height = self.height - self.borderY
    cursorcolor = Color.black
    textchars = getTextChars
    startY = getLineY(@firstline)
    textchars.each do |text|
      thisline = text[5]
      thislength = text[8]
      textY = text[2] - startY
      # Don't draw lines before the first or zero-length segments
      next if thisline < @firstline || thislength == 0
      # Don't draw lines beyond the window's height
      break if textY >= height
      c = text[0]
      # Don't draw spaces
      next if c == " "
      textwidth = text[3] + 4   # add 4 to prevent draw_text from stretching text
      textheight = text[4]
      # Draw text
      pbDrawShadowText(bitmap, text[1], textY, textwidth, textheight, c, @baseColor, @shadowColor)
    end
    # Draw cursor
    if @cursor_shown
      textheight = bitmap.text_size("X").height
      cursorY = (textheight * @cursorLine) - startY
      cursorX = 0
      textchars.each do |text|
        thisline = text[5]
        thiscolumn = text[7]
        thislength = text[8]
        next if thisline != @cursorLine || @cursorColumn < thiscolumn ||
                @cursorColumn > thiscolumn + thislength
        cursorY = text[2] - startY
        cursorX = text[1]
        textheight = text[4]
        posToCursor = @cursorColumn - thiscolumn
        if posToCursor >= 0
          partialString = text[0].scan(/./m)[0, posToCursor].join
          cursorX += bitmap.text_size(partialString).width
        end
        break
      end
      cursorY += 4
      cursorHeight = [4, textheight - 4, bitmap.text_size("X").height - 4].max
      bitmap.fill_rect(cursorX, cursorY, 2, cursorHeight, cursorcolor)
    end
  end
end
