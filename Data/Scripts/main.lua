local prop_RichTextMgr = script:GetCustomProperty("_RichTextMgr")
local propTargetUIPanel = script:GetCustomProperty("TargetUIPanel"):WaitForObject()
local propBaloo2 = script:GetCustomProperty("Baloo2")

local rtm = require(prop_RichTextMgr)

--rtm.CalculateGlyphSizes()


--rtm.DisplayText(propTargetUIPanel, "The <b 4>quick</b> <size 70><offset -30><color red>brown fox<color white></offset><size 50> jumped over the <shadow 2 2 green>lazy dog</shadow> again and again and again!!", propBaloo2, 50, {xMargin = 20, yMargin = 20})

--rtm.DisplayText(propTargetUIPanel, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.  Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", propBaloo2, 30, {leftMargin = 20, topMargin = 20})
local text = [[
This text is <b>bold</b>
This text has a <shadow>drop shadow</shadow>
<font pirata_one>This text has a font!<font baloo_2>
<size 60>Big text!
<size 20> little text!
<size 40><color red>Red text!<color white>
Long text that goes far enough that it needs to wrap!
]]




rtm.DisplayText(propTargetUIPanel, text, propBaloo2, 40, {xMargin = 20, yMargin = 20})
