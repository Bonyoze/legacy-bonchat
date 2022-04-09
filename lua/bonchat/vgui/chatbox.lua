local PANEL = {
  Init = function(self)
    self:Dock(FILL)
    self:SetKeyBoardInputEnabled(true)
    self:SetMouseInputEnabled(true)

    self:OpenURL("https://bonyoze.github.io/gmod-bonchat/resources/chatbox.html")

    self:AddFunction("glua", "say", function(text)
      if not text or #text == 0 then return end

      net.Start("BonChat_say")
        net.WriteString(string.Left(text, BonChat.GetMsgMaxLen()))
        net.WriteBool(false)
      net.SendToServer()
    end)

    self:AddFunction("glua", "openURL", function(url)
      if not (string.StartWith(url, "https://") or string.StartWith(url, "http://")) then
        return BonChat.Log("Cannot open a URL unless it's using the protocol 'https' or 'http'!")
      end
      if #url > 512 then
        return BonChat.Log("Cannot open a URL more than 512 characters long!", Color(180, 180, 180), " (https://github.com/Facepunch/garrysmod-issues/issues/4663)")
      end
      BonChat.CloseChat()
      gui.OpenURL(url)
    end)
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "DHTML")