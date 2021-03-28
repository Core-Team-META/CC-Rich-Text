local propGlyphCheckTemplate = script:GetCustomProperty("GlyphCheckTemplate")
local propGlyphTemplate = script:GetCustomProperty("GlyphTemplate")
local prop_FontLookup = script:GetCustomProperty("_FontLookup")

local fonts = require(prop_FontLookup)

local API = {}
local allFontData = {}

local template = World.SpawnAsset(propGlyphCheckTemplate)
local sizeCheckTextBox = template:GetCustomProperty("GlyhphSizeChecker"):WaitForObject()
sizeCheckTextBox:SetColor(Color.New(0, 0, 0, 0))


-- Todo- make this just grab the glyphs used in the string.
function API.GetGlyphSize(glyph, font, size)
  local SAMPLE_SIZE = 1
  local fontKey = TypefaceKey(font, size)
  if allFontData[fontKey] == nil then allFontData[fontKey] = {} end
  if allFontData[fontKey][glyph] ~= nil then return allFontData[fontKey][glyph] end

  sizeCheckTextBox:SetFont(font)
  sizeCheckTextBox.fontSize = size
  sizeCheckTextBox.text = glyph:rep(SAMPLE_SIZE)

  local dims = sizeCheckTextBox:ComputeApproximateSize()
  while dims == nil do
    Task.Wait()
    dims = sizeCheckTextBox:ComputeApproximateSize()
    print("waiting...")
  end
  --print(glyph, ":", dims, "(New!)")
  dims.x = dims.x / (SAMPLE_SIZE + 0)
  allFontData[fontKey][glyph] = dims
  return dims
end


function TypefaceKey(font, size)
  return string.upper(string.format("%s:%d", font, size))
end

function API.DisplayText(panel, text, font, size, options)
  text = text .. "\n"
  if options == nil then options = {} end
  --local subChar = "_"
  local subChar = "\a"

  local controlCodes = {}
  for a in text:gmatch("<(.-)>") do
    print("Code:", a)
    table.insert(controlCodes, a)
  end
  local basicText = text:gsub("<.->", subChar)

  local maxX = panel.width - (options.rightMargin or 0)
  local maxY = panel.height

  local currentWord = {}
  local currentWordLength = 0

  local textData = {
    currentFont = font,
    currentSize = size,
    currentColor = Color.WHITE,
    currentLineHeight = 0,
    leftMargin = options.leftMargin or 0,
    currentX = options.leftMargin or 0,
    currentY = options.topMargin or 0,
    codeIndex = 1,
    controlCodes = controlCodes,
    isBold = false,
    isShadowed = false,
    offsetX = 0,
    offsetY = 0,
  }


  for c in basicText:gmatch(".") do
    if c == " " or c == "\n" then
      -- we got a space.  Figure out if the current word
      -- fits on the line; otherwise move to the next line.

      local newLine = false
      if textData.currentX + currentWordLength > maxX then
        textData.currentX = textData.leftMargin
        textData.currentY = textData.currentY + textData.currentLineHeight
        textData.currentLineHeight = 0
        newLine = true
      end

      for _,v in pairs(currentWord) do
        v.x = v.x + textData.currentX
        v.y = v.y + textData.currentY
      end

      textData.currentX = textData.currentX + currentWordLength
      currentWordLength = 0
      currentWord = {}

      if not newLine then
        textData.currentX = textData.currentX 
            + API.GetGlyphSize(" ", textData.currentFont, textData.currentSize).x
      end

      if c == "\n" then
        textData.currentX = textData.leftMargin
        textData.currentY = textData.currentY + textData.currentLineHeight
        textData.currentLineHeight = 0
      end
    elseif c == subChar then
      HandleControlCode(textData)
    else
      -- regular letter.  Add to the current word.
      local glyphList, newXOffset = RenderGlyph(c, textData, panel, currentWordLength)
      currentWordLength = newXOffset
      for k,v in pairs(glyphList) do
        table.insert(currentWord, v)
      end
    end
  end

  --print(basicText)
end



function HandleControlCode(textData)
  local code = textData.controlCodes[textData.codeIndex]:upper()
  textData.codeIndex = textData.codeIndex + 1
  local args = {}
  for a in code:gmatch("(%S+)") do
    table.insert(args, a)
  end

  if args[1] == "COLOR" then
    textData.currentColor = Color[args[2]]
  elseif args[1] == "FONT" then
    textData.currentFont = fonts.GetFontMUID(args[2])
    if textData.currentFont == nil then
      print("it was nil. [" .. args[2] .. "]")
      textData.currentFont = args[2]
    end
  elseif args[1] == "SIZE" then
    textData.currentSize = args[2]
  elseif args[1] == "OFFSET" then
    if args[3] ~= nil then
      textData.offsetX = args[2]
      textData.offsetY = args[3]
    else
      textData.offsetY = args[2]
    end
  elseif args[1] == "/OFFSET" then
    textData.offsetX = 0
    textData.offsetY = 0
  elseif args[1] == "B" then
    textData.isBold = true
    textData.boldThickness = args[2] or 1
  elseif args[1] == "/B" then
    textData.isBold = false
  elseif args[1] == "SHADOW" then
    textData.isShadowed = true
    textData.shadowOffsetX = args[2] or 2
    textData.shadowOffsetY = args[3] or 2
    textData.shadowColor = args[4] or "BLACK"
  elseif args[1] == "/SHADOW" then
    textData.isShadowed = false
  else
    warn("Unknown text code: " .. args[1])
  end
end


-- This is a mess.  It really needs a cleanup pass.
function RenderGlyph(letter, textData,  panel, xOffset)
  local glyphSize = API.GetGlyphSize(letter, textData.currentFont, textData.currentSize)
  local glyphList = {}

  if textData.isShadowed then
    local bonusGlyph = World.SpawnAsset(propGlyphTemplate, {parent = panel})
    bonusGlyph.x = textData.offsetX + xOffset + textData.shadowOffsetX
    bonusGlyph.y = textData.offsetY + textData.shadowOffsetY
    bonusGlyph.text = letter
    bonusGlyph.fontSize = textData.currentSize
    bonusGlyph:SetFont(textData.currentFont)
    bonusGlyph:SetColor(Color[textData.shadowColor])
    table.insert(glyphList, 1, bonusGlyph)
  end

  local glyph = World.SpawnAsset(propGlyphTemplate, {parent = panel})
  glyph.x = textData.offsetX + xOffset
  glyph.y = textData.offsetY
  glyph.text = letter
  glyph.fontSize = textData.currentSize
  glyph:SetFont(textData.currentFont)
  glyph:SetColor(textData.currentColor)
  local newXOffset = xOffset + glyphSize.x
  textData.currentLineHeight = math.max(textData.currentLineHeight, glyphSize.y)

  table.insert(glyphList, glyph)

  if textData.isBold then
      local offsetList = {
        Vector2.New(-1, -1),
        Vector2.New( 0, -1),
        Vector2.New( 1, -1),
        Vector2.New(-1,  0),
        Vector2.New( 1,  0),
        Vector2.New(-1,  1),
        Vector2.New( 0,  1),
        Vector2.New( 1,  1),
      }
      for k,v in pairs(offsetList) do
        local bonusGlyph = World.SpawnAsset(propGlyphTemplate, {parent = panel})
        bonusGlyph.x = glyph.x + v.x * textData.boldThickness
        bonusGlyph.y = glyph.y + v.y * textData.boldThickness
        bonusGlyph.text = letter
        bonusGlyph.fontSize = textData.currentSize
        bonusGlyph:SetFont(textData.currentFont)
        bonusGlyph:SetColor(textData.currentColor)
        table.insert(glyphList, bonusGlyph)
      end
  end



  return glyphList, newXOffset
end


return API