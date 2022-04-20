surface.CreateFont("BonChatSettings", {
	font = "Arial",
	extended = false,
	size = 18,
  weight = 600
})

local PANEL = {
  Init = function(self)
    self:SetTitle("Chat Settings")
    self:ShowCloseButton(false)
    self:SetDraggable(false)

    self.Paint = function(self, w, h)
      surface.SetDrawColor(30, 30, 30)
      surface.DrawOutlinedRect(0, 0, w, h, 2)
      surface.DrawRect(0, 0, w, 25)
      surface.SetDrawColor(50, 50, 50)
      surface.DrawRect(2, 25, w - 4, h - 27)
    end

    self.panel = self:Add("DScrollPanel")
    self.panel:Dock(FILL)
    self.panel:GetVBar():SetWide(0)

    self:AddButton("Reload Chatbox", function()
      RunConsoleCommand("bonchat_reload")
    end)
    self:AddButton("Clear Chat", function()
      RunConsoleCommand("bonchat_clear")
    end)
  end,
  AddButton = function(self, text, callback)
    local btn = self.panel:Add("DButton")
    btn:SetText(text)
    btn:Dock(TOP)
    btn:DockMargin(20, 0, 20, 0)
    btn.DoClick = callback
  end
}

vgui.Register("BonChat_Settings", PANEL, "DFrame")