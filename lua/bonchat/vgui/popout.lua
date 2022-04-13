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
    self:SetTitle("")
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

    self.dhtml = self:Add("DHTML")
    self.dhtml:Dock(FILL)
    self.dhtml:SetHTML(BonChat.GetResource("popout.html"))

    self.dhtml:AddFunction("glua", "openURL", BonChat.OpenURL)

    self:Hide()
  end,
  ShowImage = function(self, url, w, h, minW, minH)
    w, h = fixDimensions(w, h)
    minW, minH = fixDimensions(minW, minH)

    self:SetTitle(url)
    self:SetSize(w, h)
    self:SetPos(ScrW() / 2 - w / 2, ScrH() / 2 - h / 2)
    self:SetMinWidth(minW)
    self:SetMinHeight(minH)

    -- set image html
    self.dhtml:Call(string.format([[
      $("body").html($("<img>").attr("src", "%s"));
    ]], url))

    self:Show()
    self:MakePopup()
  end,
  OnFocusChanged = function(self, gained)
    if not gained then self:Hide() end
  end
}

vgui.Register("BonChat_Popout", PANEL, "DFrame")