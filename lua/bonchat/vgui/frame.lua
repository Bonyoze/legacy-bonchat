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

    self.settings = self:Add("BonChat_Settings")
    self.emojis = self:Add("BonChat_Emojis")

    self.btnSettings = self:Add("DButton")
    self.btnSettings:SetSize(20, 20)
    self.btnSettings:SetText("")
    self.btnSettings:SetPos(self:GetWide() - 24, 3)
    self.btnSettings:SetImage("icon16/cog.png")
    self.btnSettings.Paint = function() end
    self.btnSettings.DoClick = function()
      if self.settings:IsVisible() then return self.settings:Hide() end
      self.emojis:Hide()
      local x, y = self:LocalToScreen()
      self.settings:SetSize(ScrW() * 0.15, self:GetTall())
      self.settings:SetPos(x + self:GetWide() + 4, y)
      self.settings:Show()
      self.settings:MakePopup()
    end

    self.btnEmojis = self:Add("DButton")
    self.btnEmojis:SetSize(20, 20)
    self.btnEmojis:SetText("")
    self.btnEmojis:SetPos(self:GetWide() - 44, 3)
    self.btnEmojis:SetImage("icon16/emoticon_grin.png")
    self.btnEmojis.Paint = function() end
    self.btnEmojis.DoClick = function()
      if self.emojis:IsVisible() then return self.emojis:Hide() end
      self.settings:Hide()
      local x, y = self:LocalToScreen()
      self.emojis:SetSize(ScrW() * 0.15, self:GetTall())
      self.emojis:SetPos(x + self:GetWide() + 4, y)
      self.emojis:Show()
      self.emojis:MakePopup()
    end

    -- DHTML panel used for the actual chatbox
    self.chatbox = self:Add("BonChat_Chatbox")

    -- DFrame panel used for opening links in-game
    self.browser = vgui.Create("BonChat_Browser")

    -- fix scale of children on resize
    self.OnSizeChanged = function(self, w, h)
      self.settings:SetSize(ScrW() * 0.15, self:GetTall())
      self.emojis:SetSize(ScrW() * 0.15, self:GetTall())
    end

    hook.Add("Think", self, function()
      if not self:IsKeyboardInputEnabled() then return end

      -- update position of children

      self.btnSettings:SetPos(self:GetWide() - 24, 3)

      if self.settings:IsVisible() then
        self.settings:SetPos(self:GetX() + self:GetWide() + 4, self:GetY())
      end

      self.btnEmojis:SetPos(self:GetWide() - 44, 3)

      if self.emojis:IsVisible() then
        self.emojis:SetPos(self:GetX() + self:GetWide() + 4, self:GetY())
      end
    end)

    self:CloseFrame()
  end,
  OpenFrame = function(self)
    -- move the frame to the front and enable input
    self:MakePopup()

    -- start painting frame
    self.Paint = self.openPaint

    -- show parts
    self.btnSettings:Show()
    self.btnEmojis:Show()

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
    self.settings:Hide()
    self.btnSettings:Hide()
    self.emojis:Hide()
    self.btnEmojis:Hide()
    self.browser:Hide()

    self.chatbox:Close()
  end,
  OnRemove = function(self)
    -- cleanup
    self.browser:Remove()
  end
}

vgui.Register("BonChat_Frame", PANEL, "DFrame")