local PANEL = {
  Init = function(self)
    self:Dock(FILL)
    self:SetHTML(BonChat.GetResource("chatbox.html"))

    self:AddFunction("glua", "showProfile", function(steamID)
      local ply = player.GetBySteamID(steamID)
      if ply then
        -- this function allows us to open the profile without having to ask first
        ply:ShowProfile()
      else
        -- fallback method if we can't get the player entity
        gui.OpenURL("https://steamcommunity.com/id/" .. util.SteamIDTo64(steamID))
      end
    end)
    self:AddFunction("glua", "say", BonChat.Say)
    self:AddFunction("glua", "openPage", BonChat.OpenPage)
    self:AddFunction("glua", "openImage", BonChat.OpenImage)
    self:AddFunction("glua", "setClipboardText", SetClipboardText)
    
    -- get emoji data and send to panel
    self:Call(string.format(
      "const EMOJI_DATA = JSON.parse('%s')",
      BonChat.GetResource("emoji_data.json")
    ))
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "DHTML")