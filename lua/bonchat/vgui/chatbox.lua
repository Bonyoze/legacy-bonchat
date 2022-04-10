local PANEL = {
  Init = function(self)
    self:Dock(FILL)
    self:SetKeyBoardInputEnabled(true)
    self:SetMouseInputEnabled(true)
    self:SetHTML(BonChat.GetResource("chatbox.html"))

    self:AddFunction("glua", "say", BonChat.Say)
    self:AddFunction("glua", "openURL", BonChat.OpenURL)

    end)
    
    -- get emoji data and send to panel
    self:Call(string.format(
      "const EMOJI_DATA = JSON.parse(`%s`)",
      BonChat.GetResource("emojis.json")
    ))
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "DHTML")