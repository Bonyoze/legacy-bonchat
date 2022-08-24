local maxW, maxH = ScrW() / 2, ScrH() / 2

local function fixDimensions(w, h)
  -- consider frame space
  w = w + 10
  h = h + 34

  -- make sure it fits on screen
  if w > maxW or h > maxH then
    if w > h then
      h = h * maxW / w
      w = maxW
    else
      w = w * maxH / h
      h = maxH
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
    self:SetSize(ScrW() / 2, ScrH() / 2)
    self:SetPos(ScrW() / 4, ScrH() / 4)
    self:SetMinWidth(ScrW() / 8)
    self:SetMinHeight(ScrH() / 8)

    self.dhtml:OpenURL(url)

    self:Show()
    self:MakePopup()
    self.dhtml:RequestFocus()
    self.dhtml:SetKeyboardInputEnabled(true)
    self.dhtml:SetMouseInputEnabled(true)
  end,
  OpenMedia = function(self, resource, title, url, w, h, minW, minH, callback)
    minW, minH = fixDimensions(minW or w, minH or h)
    w, h = fixDimensions(w, h)

    self:SetTitle(title)
    self:SetSize(w, h)
    self:SetPos(ScrW() / 2 - w / 2, ScrH() / 2 - h / 2)
    self:SetMinWidth(minW)
    self:SetMinHeight(minH)

    self.dhtml:SetHTML(BonChat.GetResource(resource))

    self.dhtml.OnDocumentReady = function(self)
      self:CallJSParams("loadElem('%s')", string.JavascriptSafe(url))
      if callback then callback() end
    end

    self:Show()
    self:MakePopup()
    self.dhtml:RequestFocus()
  end,
  OpenImage = function(self, title, url, w, h, minW, minH)
    self:OpenMedia("browser_image.html", title, url, w, h, minW, minH)
  end,
  OpenVideo = function(self, title, url, w, h, minW, minH)
    self:OpenMedia("browser_video.html", title, url, w, h, minW, minH, function()
      self.dhtml:CallJSParams("elem.prop('volume', %f)", BonChat.CVAR.GetAttachVolume())
    end)
  end,
  OpenAudio = function(self, title, url, w, h, minW, minH)
    self:OpenMedia("browser_audio.html", title, url, w, h, minW, minH, function()
      self.dhtml:CallJSParams("elem.prop('volume', %f)", BonChat.CVAR.GetAttachVolume())
    end)
  end
}

vgui.Register("BonChat_Browser", PANEL, "DFrame")