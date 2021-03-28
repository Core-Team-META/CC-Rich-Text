local API = {}

-- Quick font lookup function.  Names are canonized
-- to be in all caps, so users can capitalize however
-- they want.
function API.GetFontMUID(fontName)
	return script:GetCustomProperty(fontName:upper())
end

return API