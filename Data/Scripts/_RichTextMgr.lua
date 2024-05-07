local prop_FontLookup = script:GetCustomProperty("_FontLookup")
local propGlyphCheckTemplate = script:GetCustomProperty("GlyphCheckTemplate")
local propGlyphTemplate = script:GetCustomProperty("GlyphTemplate")
local propEmbeddedImageTemplate = script:GetCustomProperty("EmbeddedImageTemplate")
local propEmbeddedPanelTemplate = script:GetCustomProperty("EmbeddedPanelTemplate")

local fonts = require(prop_FontLookup)
local imageList = {}

local API = {}
local allFontData = {}

local template = World.SpawnAsset(propGlyphCheckTemplate)
local sizeCheckTextBox = template:GetCustomProperty("GlyhphSizeChecker"):WaitForObject()
sizeCheckTextBox:SetColor(Color.New(0, 0, 0, 0))


-- Todo- make this just grab the glyphs used in the string.
function API.GetGlyphSize(glyph, font, size, outline, shadow)
  local SAMPLE_SIZE = 1
  local fontKey = TypefaceKey(font, size)
  if allFontData[fontKey] == nil then allFontData[fontKey] = {} end
  if allFontData[fontKey][glyph] ~= nil then return allFontData[fontKey][glyph] end

  sizeCheckTextBox:SetFont(font)
  sizeCheckTextBox.outlineSize = outline
  sizeCheckTextBox:SetShadowOffset(shadow)
  sizeCheckTextBox.fontSize = size
  sizeCheckTextBox.text = glyph:rep(SAMPLE_SIZE)

  local dims = sizeCheckTextBox:ComputeApproximateSize()
  while dims == nil do
    Task.Wait()
    dims = sizeCheckTextBox:ComputeApproximateSize()
  end
  dims.x = dims.x / (SAMPLE_SIZE + 0)
  allFontData[fontKey][glyph] = dims
  return dims
end


function TypefaceKey(font, size)
  return string.upper(string.format("%s:%d", font, size))
end

function API.DisplayText(panel, text, options)
  local dimensions = {
    width = panel.width,
    height = -1,
  }

  API.ClearText(panel)

  if options == nil then options = {} end
  --local subChar = "_"
  local subChar = "\a"

  local controlCodes = {}

  for a in text:gmatch("<(.-)>") do
    table.insert(controlCodes, a)
  end

  -- build up a table of the start/end position of every tag, in the
  -- original raw text.  We need this for recursing with panels.
  local controlIndexes = {}
  local tempText = text
  while true do
    local matchStart, matchEnd = tempText:find("<(.-)>")
    if matchStart == nil then break end
    table.insert(controlIndexes, {matchStart = matchStart, matchEnd = matchEnd})
    tempText = tempText:gsub("<.->", function(a) return string.rep("*", a:len()) end, 1)
  end

  local basicText = text:gsub("<.->", subChar)

  local maxX = panel.width - (options.rightMargin or 0)
  local maxY = panel.height

  local baseFont = fonts.GetFontMUID(options.font)
  if baseFont == nil then
    baseFont = options.font
  end
  local baseSize = options.size or 30

  local textData = {
    rawText = text,
    options = options,
    targetPanel = panel,
    maxX = maxX,
    maxY = maxY,
    currentWord = {},
    currentWordLength = 0,
    currentLine = {},
    allElements = {},
    currentLineLength = 0,
    baseFont = baseFont,
    baseSize = baseSize,
    baseColor = options.color or Color.WHITE,
    currentFont = baseFont,
    currentSize = baseSize,
    currentColor = options.color or Color.WHITE,
    currentLineHeight = 0,
    totalHeight = 0,
    leftMargin = options.leftMargin or 0,
    currentX = options.leftMargin or 0,
    currentY = options.topMargin or 0,
    codeIndex = 1,
    controlCodes = controlCodes,
    controlIndexes = controlIndexes,
    isBold = false,
    shadowOffset = Vector2.ZERO,
    shadowColor = options.shadowColor or Color.BLACK,
    outlineSize = 0,
    outlineColor = options.outlineColor or Color.BLACK,
    offsetX = 0,
    offsetY = 0,
    inSubPanel = false,
    needsNewTextElement = true,
    justify = options.justify or "left",
    vJustify = options.vJustify or "top"
  }
  textData.justify = string.lower(textData.justify)

  for _, code in utf8.codes(basicText) do
    c = utf8.char(code)
    if c == " " or c == "\n" then
      if not textData.inSubPanel then
        FlushWord(textData)
        if c == "\n" then
          EndOfLine(textData)
        else
          textData.currentX = textData.currentX 
              + API.GetGlyphSize(" ", textData.currentFont, textData.currentSize, textData.outlineSize, textData.shadowOffset).x
        end
      end
    elseif c == subChar then
      HandleControlCode(textData)
      FlushWord(textData)
      if textData.timeToStop then break end
    else
      -- regular letter.  Add to the current word.
      RenderGlyph(c, textData, panel)
    end
  end
  -- This forces the text to update the line.
  FlushWord(textData)
  RenderGlyph(" ", textData, panel)
  EndOfLine(textData)

  --Vertical centering:
  local vOffset = 0
  if textData.vJustify == "top" then
    --nothing, we're fine
  elseif textData.vJustify == "center" then
    vOffset = (textData.maxY - textData.totalHeight) / 2
  elseif textData.vJustify == "bottom" then
    vOffset = (textData.maxY - textData.totalHeight)
  end
  for k,v in pairs(textData.allElements) do
    v.y = v.y + vOffset
  end
  textData.allElements = {}

  dimensions.height = textData.currentY + textData.currentLineHeight + (options.topMargin or 0)
  return dimensions
end


function HandleControlCode(textData)
  local code = textData.controlCodes[textData.codeIndex]:upper()
  textData.codeIndex = textData.codeIndex + 1

  local args = {}
  for a in code:gmatch("(%S+)") do
    table.insert(args, a)
  end

  if textData.inSubPanel then
    if args[1] == "/PANEL" then
      textData.inSubPanel = false
    end
  else
      textData.needsNewTextElement = true

    if args[1] == "COLOR" then
      textData.currentColor = AsColor(args[2])
    elseif args[1] == "/COLOR" then
      textData.currentColor = textData.baseColor
    elseif args[1] == "FONT" then
      textData.currentFont = fonts.GetFontMUID(args[2])
      if textData.currentFont == nil then
        textData.currentFont = args[2]
      end
    elseif args[1] == "/FONT" then
      textData.currentFont = textData.baseFont
    elseif args[1] == "SIZE" then
      textData.currentSize = args[2]
    elseif args[1] == "/SIZE" then
      textData.currentSize = textData.baseSize
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
      textData.shadowOffset = Vector2.New(args[2] or 4, args[3] or 4)
      textData.shadowColor = AsColor(args[4]) or "BLACK"
    elseif args[1] == "/SHADOW" then
      textData.shadowOffset = Vector2.ZERO
    elseif args[1] == "OUTLINE" then
      textData.outlineSize = args[2]
      textData.outlineColor = AsColor(args[3])
    elseif args[1] == "/OUTLINE" then
      textData.outlineSize = 0
    elseif args[1] == "IMAGE" then
      InsertImage(args, textData)
    elseif args[1] == "TEMPLATE" then
      InsertTemplate(args, textData)
    elseif args[1] == "PANEL" then
      InsertPanelStart(args, textData)
    elseif args[1] == "/PANEL" then
      FlushWord(textData)
      textData.timeToStop = true
    elseif args[1] == "JUSTIFY" then
      textData.justify = string.lower(args[2])
      if textData.justify ~= "left" and
          textData.justify ~= "right" and
          textData.justify ~= "center" then
        warn("Unknown justification:" .. textData.justify)
        textData.justify = "left"
      end
    elseif args[1] == "VJUSTIFY" then
      textData.vJustify = string.lower(args[2])
      if textData.vJustify ~= "top" and
          textData.vJustify ~= "bottom" and
          textData.vJustify ~= "center" then
        warn("Unknown justification:" .. textData.vJustify)
        textData.vJustify = "top"
      end
    else
      warn("Unknown text code: " .. args[1])
    end
  end
end


function EndOfLine(textData)
  local lineOffset = 0
  if textData.justify == "left" then
    -- nothing, we stay at 0
  elseif textData.justify == "right" then
    lineOffset = textData.maxX - textData.currentX
  elseif textData.justify == "center" then
    lineOffset = (textData.maxX - textData.currentX) / 2
  else
    print("Unknown justification:", textData.justify)
  end

  for k,v in pairs(textData.currentLine) do
    v.x = v.x + lineOffset
    table.insert(textData.allElements, v)
  end

  textData.currentLine = {}

  textData.currentX = textData.leftMargin
  if textData.currentLineHeight == 0 then
    textData.currentLineHeight = API.GetGlyphSize(" ", textData.currentFont, textData.currentSize, textData.outlineSize, textData.shadowOffset).y
  end
  textData.currentY = textData.currentY + textData.currentLineHeight
  textData.totalHeight = textData.totalHeight + textData.currentLineHeight
  textData.currentLineHeight = 0

  return lineOffset
end



-- helper function for flushing words.
function FlushWord(textData)
  -- we got a space.  Figure out if the current word
  -- fits on the line; otherwise move to the next line.
  textData.needsNewTextElement = true

  local newLine = false
  if textData.currentX + textData.currentWordLength > textData.maxX then
    local lineOffset = EndOfLine(textData)
    for k,v in pairs(textData.currentWord) do
      table.insert(textData.currentLine, v)
      -- This is a hack - because of how flush word and endofline work,
      -- the first word on the new line has already been shifted, so we need to shift
      -- it back, so that it can be handled propperly by the next line.
      v.x = v.x - lineOffset
    end

    textData.currentX = textData.leftMargin
    textData.currentY = textData.currentY + textData.currentLineHeight
    textData.currentLineHeight = 0
    newLine = true
  end

  for _,v in pairs(textData.currentWord) do
    v.x = v.x + textData.currentX
    v.y = v.y + textData.currentY
  end

  textData.currentX = textData.currentX + textData.currentWordLength
  textData.currentWordLength = 0
  textData.currentWord = {}

  return newLine
end

function InsertPanelStart(args, textData)
  textData.needsNewTextElement = true
  FlushWord(textData)

  --print("inserting new panel...", textData.maxX, textData.currentX)
  local xOffset = textData.currentWordLength
  local width = tonumber(args[2]) or -1
  if width == -1 then width = (textData.maxX - textData.currentX) end

  local bgColor = AsColor(args[3]) or Color.New(0, 0, 0, 0)

  local newPanel = World.SpawnAsset(propEmbeddedPanelTemplate, {parent = textData.targetPanel})
  local propUIImage = newPanel:GetCustomProperty("UIImage"):WaitForObject()

  propUIImage:SetColor(bgColor)

  newPanel.x = textData.offsetX + xOffset
  newPanel.y = textData.offsetY
  newPanel.clientUserData.isText = true


  newPanel.width = width
  local remainingText = textData.rawText:sub(textData.controlIndexes[textData.codeIndex - 1].matchEnd + 1)

  local renderData = API.DisplayText(newPanel, remainingText, textData.options)
  newPanel.height = renderData.height

  textData.currentLineHeight = math.max(textData.currentLineHeight, newPanel.height)
  textData.currentWordLength = xOffset + width

  table.insert(textData.currentWord, newPanel)
  FlushWord(textData)
  textData.inSubPanel = true
end

function InsertTemplate(args, textData)
  local width = tonumber(args[3]) or textData.currentLineHeight
  if width == -1 then width = textData.maxX - textData.leftMargin - 1 end
  local height = tonumber(args[4]) or width

  local xOffset = textData.currentWordLength
  local object = World.SpawnAsset(args[2], {parent = textData.targetPanel})

  if not object:IsA("UIControl") then
    warn("Provided template ID (" .. args[2] .. ") does not point to a UI control.")
    object:Destroy()
    return
  end

  textData.needsNewTextElement = true

  object.x = textData.offsetX + xOffset
  object.y = textData.offsetY

  object.width = width
  object.height = height
  object.clientUserData.isText = true

  --print(imageId)
  textData.currentLineHeight = math.max(textData.currentLineHeight, height)
  textData.currentWordLength = xOffset + width

  table.insert(textData.currentWord, object)
  table.insert(textData.currentLine, object)
end



function InsertImage(args, textData)
  textData.needsNewTextElement = true
  local imageId = ImageLookup(args[2])

  local width = tonumber(args[3]) or textData.currentLineHeight
  if width == -1 then width = textData.maxX - textData.leftMargin - 1 end
  local height = tonumber(args[4]) or width  
  local imgColor = AsColor(args[5]) or Color.New(1, 1, 1, 1)

  local xOffset = textData.currentWordLength
  local img = World.SpawnAsset(propEmbeddedImageTemplate, {parent = textData.targetPanel})

  img.x = textData.offsetX + xOffset
  img.y = textData.offsetY

  img.width = width
  img.height = height
  img.clientUserData.isText = true

  img:SetImage(imageId)
  img:SetColor(imgColor)
  --print(imageId)
  textData.currentLineHeight = math.max(textData.currentLineHeight, height)
  textData.currentWordLength = xOffset + width

  table.insert(textData.currentWord, img)
  table.insert(textData.currentLine, img)
end


-- This is a mess.  It really needs a cleanup pass.
function RenderGlyph(letter, textData)
  --print(letter, textData.inSubPanel)
  if textData.inSubPanel then return end

  local xOffset = textData.currentWordLength
  local glyphSize = API.GetGlyphSize(letter, textData.currentFont, textData.currentSize, textData.outlineSize, textData.shadowOffset)
  local glyphList = {}

  local newXOffset = 0
  if textData.needsNewTextElement then

    local glyph = World.SpawnAsset(propGlyphTemplate, {parent = textData.targetPanel})
    glyph.clientUserData.isText = true
    glyph.x = textData.offsetX + xOffset
    glyph.y = textData.offsetY
    glyph.text = letter
    glyph.fontSize = textData.currentSize
    glyph:SetFont(textData.currentFont)
    glyph:SetColor(textData.currentColor)
    glyph.outlineSize = textData.outlineSize
    glyph:SetOutlineColor(textData.outlineColor)
    glyph:SetShadowOffset(textData.shadowOffset)
    glyph:SetShadowColor(textData.shadowColor)
    newXOffset = xOffset + glyphSize.x
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
          local bonusGlyph = World.SpawnAsset(propGlyphTemplate, {parent = textData.targetPanel})
          bonusGlyph.clientUserData.isText = true
          bonusGlyph.x = glyph.x + v.x * textData.boldThickness
          bonusGlyph.y = glyph.y + v.y * textData.boldThickness
          bonusGlyph.text = letter
          bonusGlyph.fontSize = textData.currentSize
          bonusGlyph:SetFont(textData.currentFont)
          bonusGlyph:SetColor(textData.currentColor)
          table.insert(glyphList, bonusGlyph)
        end
    end

  else -- needsNewTextElement is false
    textData.currentLineHeight = math.max(textData.currentLineHeight, glyphSize.y)
    newXOffset = xOffset + glyphSize.x

    local newWordText = nil
    for k,v in pairs(textData.currentWord) do
      if v:IsA("UIText") then
        if newWordText == nil then newWordText = v.text .. letter end
        v.text = newWordText
        v.width = newXOffset + 10
      end
    end
  end
  textData.needsNewTextElement = false

  textData.currentWordLength = newXOffset
  for k,v in pairs(glyphList) do
    table.insert(textData.currentWord, v)
    table.insert(textData.currentLine, v)
  end
end



function API.SetImageSource(obj)
  warn("RichText.SetImageSource is deprecated.  Use AddImageSource instead.")
  API.ClearImageSources()
  API.AddImageSource(obj)
end

function API.ClearImageSources()
  imageList = {}
end

function API.AddImageSource(obj)
  for k,v in pairs(obj:GetCustomProperties()) do
    imageList[k:upper()] = v
  end
end


function API.ClearText(panel)
  for k,v in pairs(panel:GetChildren()) do
    if v.clientUserData.isText then
      v:Destroy()
    end
  end
end


function ImageLookup(name)
  local result = imageList[name:upper()]
  if result ~= nil then
    return result
  else
    return name
  end
end

function AsColor(str)
  if Color[str] ~= nil then return Color[str] end
  if str == nil or str:sub(1, 1) ~= "#" then return nil end
  return Color.FromStandardHex(str)
  --[[

  local r = tonumber(str:sub(2, 3), 16)
  local g = tonumber(str:sub(4, 5), 16)
  local b = tonumber(str:sub(6, 7), 16)
  -- If they didn't provide an alpha, assume 100%
  local a = 255
  if str:len() > 7 then a = tonumber(str:sub(8, 9), 16)  end
  --print(r, g, b, a, str)
  return Color.New(r / 255, g / 255, b / 255, a / 255)
  ]]
end

return API