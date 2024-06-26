local prop_RichTextMgr = script:GetCustomProperty("_RichTextMgr")
local propTargetUIPanel = script:GetCustomProperty("TargetUIPanel"):WaitForObject()
local propImage = script:GetCustomProperty("image")
local propImageDir = script:GetCustomProperty("ImageDir"):WaitForObject()
local propUIPanel = script:GetCustomProperty("UIPanel"):WaitForObject()
local propVerticalAlignPanel = script:GetCustomProperty("AnotherPanel"):WaitForObject()


local rtm = require(prop_RichTextMgr)

local text = [[
<justify left><size 40>Big text,</size>
<size 18>small text,</size>
<size 10>Barely read at all text</size>

<justify right><color red>red</color> text, <color cyan>blue</color> text,
<font baloo_2_extra_bold>Using-font-'baloo' text!</font>

<shadow 4 4 blue>shadowed text,</shadow> <b>bold text.</b>
<color red>C<color orange>r<color yellow>a<color green>z<color cyan>y</color> <offset 2>u<offset -2>n<offset 4>c<offset -1>o<offset 3>n<offset 0>t<offset 3>r<offset -2>o<offset 2>l<offset 4>l<offset -1>e<offset -3>d </offset>text!

<justify center><font pirata_one>Text that goes on veeeeeeeery faaaaaaaar and has to line wrap twice.
Text that has an image (<image sword>) which I think is very nice!</font>

]]

UI.SetCursorVisible(true)
UI.SetCanCursorInteractWithUI(true)


local text2 = [[
<size 30><font luckiest_guy>4/21/2021</font></size>
<image square -1 3 #FFFF00>
<image book 50 50><panel -1 #FFFFFF22>Unicode support added!
你好世界
こんにちは世界
여보세요 세계
</panel>

<size 30><font luckiest_guy>3/30/2021</font></size>
<image square -1 3 #FFFF00>
<image sword 50 50><panel -1 #FFFFFF22>Swords are really good right now as a weapon we increased their damage by like 50 points!</panel>
<image thread 50 50><panel -1 #FFFFFF22>Sewing-based classes continue to dominate.  We're not nerfing yet but will continue to monitor.</panel>
<image square -1 3 #FFFF00>

We've decided that double cash weekend was not providing enough cash so now you all just get a hojillion gold coins or whatever.  Knock yourselves out.


<size 30><font luckiest_guy>3/25/2021</font></size>
<image square -1 3 #FFFF00>
<image staff 50 50><panel -1 #FFFFFF22>Staffs should be at least 13% sparklier after this most recent resparkling pass.</panel>

<size 30><font luckiest_guy>3/30/2021</font></size>
<image square -1 3 #FFFF00>
<image sword 50 50><panel -1 #FFFFFF22>Swords are really good right now as a weapon we increased their damage by like 50 points!</panel>
<image thread 50 50><panel -1 #FFFFFF22>Sewing-based classes continue to dominate.  We're not nerfing yet but will continue to monitor.</panel>
<image square -1 3 #FFFF00>

We've decided that double cash weekend was not providing enough cash so now you all just get a hojillion gold coins or whatever.  Knock yourselves out.


<size 30><font luckiest_guy>3/25/2021</font></size>
<image square -1 3 #FFFF00>
<image staff 50 50><panel -1 #FFFFFF22>Staffs should be at least 13% sparklier after this most recent resparkling pass.</panel>

This is a test of <outline 3 PINK>outline</outline> and <shadow -5 -5 YELLOW>shadowed</shadow> text

]]

rtm.SetImageSource(propImageDir)
rtm.DisplayText(propUIPanel, text, {leftMargin = 20, topMargin = 20, rightMargin = 20, size=30})

local dims = rtm.DisplayText(propTargetUIPanel, text2, {leftMargin = 20, topMargin = 20, rightMargin = 20, size=20})
propTargetUIPanel.height = dims.height



rtm.DisplayText(propVerticalAlignPanel, "Hello world\nargleblargle\ndfdf", {vJustify = "center", justify = "center"})




local player = Game.GetLocalPlayer()
player.lookSensitivity = 0
