local PANEL = {
  Init = function(self)
    self:SetSize(ScrW() * 0.4, ScrH() * 0.31)
    self:SetPos(ScrW() * 0.01875, ScrH() * 0.875 - self:GetTall())
    self:SetMinWidth(self:GetWide() * 0.5)
    self:SetMinHeight(self:GetTall() * 0.5)
    self:SetTitle(GetHostName())
    self:ShowCloseButton(false)
    self:SetSizable(true)
    self:SetScreenLock(true)

    -- paint function used when the chat is open
    self.openPaint = function(self, w, h)
      self:DrawBlur(1, 1)
      surface.SetDrawColor(30, 30, 30)
      surface.DrawOutlinedRect(0, 0, w, h, 2)
      surface.DrawRect(0, 0, w, 25)
    end

    -- DHTML panel used for the actual chatbox
    self.chatbox = self:Add("BonChat_Chatbox")

    -- DFrame panel used for opening links in-game
    self.browser = vgui.Create("BonChat_Browser")

    self.subPanels = {}
    self.settings = self:AddSubPanel("BonChat_Settings", "cog")
    self.emojis = self:AddSubPanel("BonChat_Emojis", "emoticon_grin")
    self.attachments = self:AddSubPanel("BonChat_Attachments", "image")

    local function updateSubPanels()
      local scrW, w, h, x, y = ScrW(), self:GetWide(), self:GetTall(), self:GetX(), self:GetY()

      for i = 1, #self.subPanels do
        local subPanel = self.subPanels[i]
        subPanel.btn:SetPos(w - i * 20 - 4, 3)
        subPanel:SetSize(scrW * 0.15, h)
        subPanel:SetPos(x + w + 4, y)
      end
    end

    self.OnSizeChanged = updateSubPanels
    hook.Add("Think", self, updateSubPanels)

    -- hover label drawing

    local color_hoverlabel1, color_hoverlabel2 = Color(131, 123, 96), Color(250, 237, 185)
    
    hook.Add("DrawOverlay", self, function(self)
      if not system.HasFocus() or not self:HasHierarchicalFocus() or not self.hoverLabelText then return end
      local x, y = input.GetCursorPos()
      surface.SetFont("DermaDefault")
      local w, h = surface.GetTextSize(self.hoverLabelText)
      draw.RoundedBox(4, x + 25, y - 5, w + 10, h + 10, color_hoverlabel1)
      draw.RoundedBox(4, x + 26, y - 4, w + 8, h + 8, color_hoverlabel2)
      draw.SimpleText(self.hoverLabelText, "DermaDefault", x + 30, y + h / 2, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    self:CloseFrame()
  end,
  SetHoverLabel = function(self, text)
    self.hoverLabelText = text
  end,
  AddSubPanel = function(self, class, icon)
    local pnl = self:Add(class)
    pnl.btn = self:Add("DButton")
    local index = table.insert(self.subPanels, pnl)

    pnl:ShowCloseButton(false)
    pnl:SetDraggable(false)
    pnl.OnCursorExited = function(self) BonChat.HideHoverLabel() end

    pnl.btn:SetSize(20, 20)
    pnl.btn:SetText("")
    pnl.btn:SetPos(self:GetWide() - index * 20 - 4, 3)
    pnl.btn:SetImage("icon16/" .. icon .. ".png")

    pnl.btn.Paint = function() end
    pnl.btn.DoClick = function()
      if pnl:IsVisible() then return pnl:Hide() end
      self:HideAllSubPanels()
      pnl:Show()
      pnl:MakePopup()
    end

    return pnl
  end,
  HideAllSubPanels = function(self)
    for i = 1, #self.subPanels do
      self.subPanels[i]:Hide()
    end
  end,
  OpenFrame = function(self)
    -- move the frame to the front and enable input
    self:MakePopup()

    self.lblTitle:Show()

    -- start painting frame
    self.Paint = self.openPaint

    -- show parts
    for i = 1, #self.subPanels do
      self.subPanels[i].btn:Show()
    end

    self.chatbox:Open()

    self.isOpen = true

    -- set cursor position to center of screen
    timer.Simple(0, function() input.SetCursorPos(ScrW() / 2, ScrH() / 2) end)
  end,
  CloseFrame = function(self)
    -- stop the chatbox panel from drawing over other panels (like the game menu)
    self:MoveToBack()

    self.lblTitle:Hide()

    -- disable any input to the frame
    self:SetKeyBoardInputEnabled(false)
    self:SetMouseInputEnabled(false)

    -- stop painting the frame
    self.Paint = function() end

    -- hide parts
    for i = 1, #self.subPanels do
      local subPanel = self.subPanels[i]
      subPanel:Hide()
      subPanel.btn:Hide()
    end
    self.browser:Hide()

    self.chatbox:Close()

    -- update is typing status
    self.chatbox:CallJS("glua.isTyping(false)")

    self.isOpen = false
  end,
  OnRemove = function(self)
    -- cleanup
    self.browser:Remove()
  end
}

vgui.Register("BonChat_Frame", PANEL, "DFrame")