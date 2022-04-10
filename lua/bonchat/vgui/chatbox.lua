include("bonchat/vgui/popout.lua")

local PANEL = {
  Init = function(self)
    self:Dock(FILL)
    self:SetKeyBoardInputEnabled(true)
    self:SetMouseInputEnabled(true)
    self:SetHTML(BonChat.GetResource("chatbox.html"))

    self:AddFunction("glua", "say", BonChat.Say)
    self:AddFunction("glua", "openURL", BonChat.OpenURL)

    self.popOut = vgui.Create("BonChat_PopOut")
    self:AddFunction("glua", "showImage", function(...)
      self.popOut:ShowImage(...)
    end)
    
    -- get emoji data and send to panel
    self:Call(string.format(
      "const EMOJI_DATA = JSON.parse(`%s`)",
      BonChat.GetResource("emojis.json")
    ))
  end,
  OnRemove = function(self)
    self.popOut:Remove()
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "DHTML")