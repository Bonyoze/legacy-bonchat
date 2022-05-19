local PANEL = {
  CallJS = function(self, str, ...)
    self:Call("(function() {" .. string.format(str, ...) .. "})()")
  end,
  jsStr = "",
  ReadyJS = function(self)
    jsStr = ""
  end,
  AddJS = function(self, str, ...)
    str = string.Trim(str)
    if str[#str] ~= ";" then
      str = str .. ";"
    end
    jsStr = jsStr .. string.format(str, ...)
  end,
  RunJS = function(self)
    self:CallJS(jsStr)
  end,
  AddFunc = function(self, name, func)
    self:AddFunction("glua", name, func)
  end
}

vgui.Register("BonChat_DHTML", PANEL, "DHTML")