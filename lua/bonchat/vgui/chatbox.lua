local PANEL = {
  Init = function(self)
    self:Dock(FILL)
    self:SetHTML(BonChat.GetResource("chatbox.html"))

    self:AddFunction("glua", "showProfile", function(steamID)
      local ply = player.GetBySteamID(steamID)
      if ply then ply:ShowProfile() end
    end)
    self:AddFunction("glua", "say", BonChat.Say)
    self:AddFunction("glua", "openPage", BonChat.OpenPage)
    self:AddFunction("glua", "openImage", BonChat.OpenImage)
    
    -- get emoji data and send to panel
    self:Call(string.format(
      "const TWEMOJI_DATA = JSON.parse('%s')",
      BonChat.GetResource("emojis.json")
    ))
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "DHTML")