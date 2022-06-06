include("bonchat/vgui/dhtml.lua")

local function fixDimensions(w, h)
  -- consider frame space
  w = w + 10
  h = h + 34

  -- make sure it fits on screen
  if w > ScrW() or h > ScrH() then
    if w > h then
      h = h * ScrW() / w
      w = ScrW()
    else
      w = w * ScrH() / h
      h = ScrH()
    end
  end

  return w, h
end

local PANEL = {
  Init = function(self)
    self:SetSizable(true)
    self:SetScreenLock(true)
    self:SetDeleteOnClose(false)
    self.btnMinim:Hide()
    self.btnMaxim:Hide()

    self.Paint = function(self, w, h)
      self:DrawBlur(1, 1)
      surface.SetDrawColor(30, 30, 30)
      surface.DrawOutlinedRect(0, 0, w, h, 2)
      surface.DrawRect(0, 0, w, 25)
    end

    self.dhtml = self:Add("BonChat_DHTML")
    self.dhtml:Dock(FILL)

    self.dhtml.ConsoleMessage = function() end
    self.dhtml.OnFocusChanged = function(self, gained)
      if not gained then
        self.OnDocumentReady = function() end
        self:SetHTML("")
        self:GetParent():Hide()
      end
    end

    self:Hide()
  end,
  OpenPage = function(self, url)
    self:SetTitle(url)
    self:SetSize(ScrW() * 0.9, ScrH() * 0.9)
    self:SetPos(ScrW() * 0.5 - self:GetWide() * 0.5, ScrH() * 0.5 - self:GetTall() * 0.5)
    self:SetMinWidth(ScrW() * 0.1)
    self:SetMinHeight(ScrH() * 0.1)

    self.dhtml:OpenURL(url)

    self:Show()
    self:MakePopup()
    self.dhtml:RequestFocus()
    self.dhtml:SetKeyboardInputEnabled(true)
    self.dhtml:SetMouseInputEnabled(true)
  end,
  OpenImage = function(self, url, w, h, minW, minH)
    w, h = fixDimensions(w, h)
    minW, minH = fixDimensions(minW, minH)

    self:SetTitle(url)
    self:SetSize(w, h)
    self:SetPos(ScrW() / 2 - w / 2, ScrH() / 2 - h / 2)
    self:SetMinWidth(minW)
    self:SetMinHeight(minH)

    self.dhtml:SetHTML(BonChat.GetResource("browser_image.html"))

    self.dhtml.OnDocumentReady = function(self)
      self:CallJS("loadImage('%s')", string.JavascriptSafe(url))
    end

    self:Show()
    self:MakePopup()
    self.dhtml:RequestFocus()
  end
}

vgui.Register("BonChat_Browser", PANEL, "DFrame")