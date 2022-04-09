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
  end
}

vgui.Register("BonChat_Settings", PANEL, "DFrame")