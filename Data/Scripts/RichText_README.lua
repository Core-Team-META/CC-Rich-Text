--[[
Hi!

This is my rich text library.  It's for making
nice, formatted text appear on the screen in Core.

Making it work is really simple:

1. Make a UIPanel item in your game UI somewhere.

2. Include the Rich Text Manager (_RichTextMgr) library
   in a script file, via require().

3. Call the rich text function DisplayText(), with the
   text you want to display, with markup!

See the RichText_Example for a demonstration of this!

--------------------

Some caveats:

Calling this function will add all of the text as children
of the panel you provide.

This library does NOT handle cleaning it up, so if you want
to remove the text, you'll need to either delete the ui panel
itself, or iterate through and delete all the children.

Also, this can have a performance impact, so consider making
the UI panel live inside of a context that has been marked
as a "texture" type, to help mitigate the costs of having
so many ui objects spawned.


--------------------

Function details!

DisplayText(targetUIPanel, textToDisplay, optionalParameters)


The function has three arguments:

* The target panel to use as a parent for the text.  The text
  will automatically word-wrap based on the width of the panel.
* The actual marked-up text to decode and render.
* An optional list of parameters for the function.  This is passed
  as a table.  All parameters of the table are optional, but they
  can change the behavior somewhat:

  * leftMargin, rightMargin, topMargin - how many pixels to indent
    from the left/right/top of the panel.  Use these if you want
    to avoid having your text run right up to the edge.
  * font - a font that you want to use.  This can be either the
    MUID or the actual name of the font.  (Replace spaces with
    underscores in the name.)  You can only use fonts that are
    in the core asset list.
  * size - the size of the font.
  * color - the color to write the text in.  The color is the text
    name of the color.  Any colors defined in the lua Color object
    are allowed.

--------------------


Markup!

This library supports text with markup.  Markup commands are not
rendered as text, but rather control how the text is displayed.

They follow a common format:  They are surrounded by angle-brances,
and the first word is the actual command.  If arguments are provided,
they are separated by spaces.  Markup is not case-sensitive.

Example:

<shadow 4 4 blue>

the command is "shadow", (which adds a drop-shadow effect), and the
arguments are the x/y offset for the shadow, and the color.


The full list of supported commands:

<color colorname> - Sets the font color.  ColorName can be anything
defined on the lua Color object.

<b> - Makes the text bold.

</b> - Makes the text not bold.

<shadow x y color> Draws a dropshadow.  x, y, and color are optional.
If provided, x and y are the offset for the shadow, and color is the
shadow's color.

</color> - Resets the color to the default.

<font fontName> - sets the typeface to the font name.  Any font in
core is allowed - fontName can be either the text name of the font,
with the spaces replaced with underscores, or a muid.

</font> - Resets the font to the default.

<size newSize> - sets the font size.

</size> - resets the typeface size to the default.

<offset x y> - Moves the text by x/y from where it would otherwise
be rendered.  Use this to line up text, or make lines look jiggy.
If only one number is provided, it is used as the Y value instead
of the X.

</offset> - Resets the text offset to 0, 0

<image imageMUID, width, height> - Inserts an image into the text.
The imageMUID argument is the asset reference to the image to
be displayed.  width and height describe the dimensions that the
image will be rendered at.  If not provided, the image will default
to being a square, the height of the surounding text.

]]