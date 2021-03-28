local prop_RichTextMgr = script:GetCustomProperty("_RichTextMgr")
local propTargetUIPanel = script:GetCustomProperty("TargetUIPanel"):WaitForObject()
local propImage = script:GetCustomProperty("image")

local rtm = require(prop_RichTextMgr)

--rtm.CalculateGlyphSizes()


--rtm.DisplayText(propTargetUIPanel, "The <b 4>quick</b> <size 70><offset -30><color red>brown fox<color white></offset><size 50> jumped over the <shadow 2 2 green>lazy dog</shadow> again and again and again!!", propBaloo2, 50, {xMargin = 20, yMargin = 20})

--rtm.DisplayText(propTargetUIPanel, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.  Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", propBaloo2, 30, {leftMargin = 20, topMargin = 20})
local text = [[
<size 40>Big text,</size>
<size 18>small text,</size>
<size 10>Barely read at all text</size>
<color red>red</color> text, <color cyan>blue</color> text,
<font baloo_2_extra_bold>Using-font-'baloo' text!</font>
<shadow 4 4 blue>shadowed text,</shadow> <b>bold text.</b>
<color red>C<color orange>r<color yellow>a<color green>z<color cyan>y</color> <offset 2>u<offset -2>n<offset 4>c<offset -1>o<offset 3>n<offset 0>t<offset 3>r<offset -2>o<offset 2>l<offset 4>l<offset -1>e<offset -3>d </offset>text!
Text that goes on veeeeeeeery faaaaaaaar and has to line wrap twice.
Text that has an image (<image ]] .. propImage .. [[">) which I think is very nice.

]]

rtm.DisplayText(propTargetUIPanel, text, {leftMargin = 20, topMargin = 20, rightMargin = 20, size=30})

