include("bonchat/vgui/chatbox.lua")
include("bonchat/vgui/emojis.lua")
include("bonchat/vgui/browser.lua")
include("bonchat/vgui/settings.lua")

local PANEL = {
  Init = function(self)
    self:SetSize(ScrW() * 0.3, ScrH() * 0.35)
    self:SetPos(ScrW() * 0.02, ScrH() * 0.8 - self:GetTall())
    self:SetMinWidth(self:GetWide())
    self:SetMinHeight(self:GetTall())
    self:SetTitle("")
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
    self:AddSubPanel("BonChat_Settings", "cog")
    self:AddSubPanel("BonChat_Emojis", "emoticon_grin")

    local function updateSubPanels()
      local scrW, w, h, x, y = ScrW(), self:GetWide(), self:GetTall(), self:GetX(), self:GetY()

      for i = 1, #self.subPanels do
        local subPanel = self.subPanels[i]
        subPanel.btn:SetPos(w - i * 20 - 4, 3)
        subPanel.pnl:SetSize(scrW * 0.15, h)
        subPanel.pnl:SetPos(x + w + 4, y)
      end
    end

    self.OnSizeChanged = updateSubPanels
    hook.Add("Think", self, updateSubPanels)

    self:CloseFrame()
  end,
  AddSubPanel = function(self, class, icon)
    local pnl, btn = self:Add(class), self:Add("DButton")
    local index = table.insert(self.subPanels, { pnl = pnl, btn = btn })

    pnl:ShowCloseButton(false)
    pnl:SetDraggable(false)

    btn:SetSize(20, 20)
    btn:SetText("")
    btn:SetPos(self:GetWide() - index * 20 - 4, 3)
    btn:SetImage("icon16/" .. icon .. ".png")

    btn.Paint = function() end
    btn.DoClick = function()
      if pnl:IsVisible() then return pnl:Hide() end
      self:HideAllSubPanels()
      pnl:Show()
      pnl:MakePopup()
    end
  end,
  HideAllSubPanels = function(self)
    for i = 1, #self.subPanels do
      self.subPanels[i].pnl:Hide()
    end
  end,
  OpenFrame = function(self)
    -- move the frame to the front and enable input
    self:MakePopup()

    -- start painting frame
    self.Paint = self.openPaint

    -- show parts
    for i = 1, #self.subPanels do
      self.subPanels[i].btn:Show()
    end

    self.chatbox:Open()
  end,
  CloseFrame = function(self)
    -- stop the chatbox panel from drawing over other panels (like the game menu)
    self:MoveToBack()

    -- disable any input to the frame
    self:SetKeyBoardInputEnabled(false)
    self:SetMouseInputEnabled(false)

    -- stop painting the frame
    self.Paint = function() end

    -- hide parts
    for i = 1, #self.subPanels do
      local subPanel = self.subPanels[i]
      subPanel.pnl:Hide()
      subPanel.btn:Hide()
    end
    self.browser:Hide()

    self.chatbox:Close()
  end,
  OnRemove = function(self)
    -- cleanup
    self.browser:Remove()
  end
}

vgui.Register("BonChat_Frame", PANEL, "DFrame")