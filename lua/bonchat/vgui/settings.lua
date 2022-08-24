local PANEL = {
  Init = function(self)
    self:SetTitle("Chat Settings")

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

    -- add elements

    self:AddButton("Reload Panel", function() RunConsoleCommand("bonchat_reload") end)
    self:AddButton("Clear Chat", function() RunConsoleCommand("bonchat_clear") end)

    self:AddLabel("Messages")
    self:AddCheckbox("Play chat sound", BonChat.CVAR.CHAT_TICK, BonChat.CVAR.GetChatTick())
    self:AddCheckbox("Auto dismiss messages", BonChat.CVAR.AUTO_DISMISS, BonChat.CVAR.GetAutoDismiss())
    local cvarMaxMsgs = GetConVar(BonChat.CVAR.MAX_MSGS)
    self:AddSlider("Max messages", BonChat.CVAR.MAX_MSGS, cvarMaxMsgs:GetInt(), cvarMaxMsgs:GetMin(), cvarMaxMsgs:GetMax())
    local cvarLinkLength = GetConVar(BonChat.CVAR.LINK_MAX_LENGTH)
    self:AddSlider("Link max length", BonChat.CVAR.LINK_MAX_LENGTH, cvarLinkLength:GetInt(), cvarLinkLength:GetMin(), cvarLinkLength:GetMax())

    self:AddLabel("Attachments")
    self:AddCheckbox("Load attachments", BonChat.CVAR.LOAD_ATTACHMENTS, BonChat.CVAR.GetLoadAttachments())
    self:AddCheckbox("Autoplay attachments", BonChat.CVAR.ATTACH_AUTOPLAY, BonChat.CVAR.GetAttachAutoplay())
    local cvarAttachHeight = GetConVar(BonChat.CVAR.ATTACH_MAX_HEIGHT)
    self:AddSlider("Attachment max height", BonChat.CVAR.ATTACH_MAX_HEIGHT, cvarAttachHeight:GetInt(), cvarAttachHeight:GetMin(), cvarAttachHeight:GetMax())
    local cvarAttachVolume = GetConVar(BonChat.CVAR.ATTACH_VOLUME)
    self:AddSlider("Attachment volume", BonChat.CVAR.ATTACH_VOLUME, cvarAttachVolume:GetFloat(), cvarAttachVolume:GetMin(), cvarAttachVolume:GetMax(), 2)

    self:AddLabel("Misc")
    self:AddCheckbox("Show results for skin tone emojis", BonChat.CVAR.SHOW_TONE_EMOJIS, BonChat.CVAR.GetShowToneEmojis())
  end,
  AddElement = function(self, class)
    local elem = self.panel:Add(class)
    elem:Dock(TOP)
    elem:DockMargin(6, 0, 6, 4)
    return elem
  end,
  AddLabel = function(self, text)
    local lbl = self:AddElement("DLabel")
    lbl:DockMargin(0, 8, 0, 4)
    lbl:SetText(text)
    lbl:SetFont("ChatFont")
    return lbl
  end,
  AddButton = function(self, text, doClick)
    local btn = self:AddElement("DButton")
    btn:SetText(text)
    btn.DoClick = doClick
    return btn
  end,
  AddSlider = function(self, text, cvar, default, min, max, decimals)
    local slider = self:AddElement("DNumSlider")
    slider:DockMargin(4, -8, 4, 0)
    slider:SetText(text)
    slider:SetConVar(cvar)
    slider:SetDefaultValue(default)
    slider:SetMin(min)
    slider:SetMax(max)
    slider:SetDecimals(decimals or 0)
    return slider
  end,
  AddCheckbox = function(self, text, cvar, default)
    local checkbox = self:AddElement("DCheckBoxLabel")
    checkbox:SetText(text)
    checkbox:SetConVar(cvar)
    checkbox:SetValue(default)
    return checkbox
  end
}

vgui.Register("BonChat_Settings", PANEL, "DFrame")