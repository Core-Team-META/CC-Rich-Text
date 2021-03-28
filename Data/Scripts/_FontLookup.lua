local API = {}


function API.GetFontMUID(fontName)
	return script:GetCustomProperty(fontName:upper())
end

return API