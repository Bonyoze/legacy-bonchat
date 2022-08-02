surface.CreateFont("BonChatSettings", {
	font = "Arial",
	extended = false,
	size = 18,
  weight = 600
})

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

    -- reload chatbox button
    self:AddButton("Reload Chatbox", function() RunConsoleCommand("bonchat_reload") end)
    -- clear chat button
    self:AddButton("Clear Chat", function() RunConsoleCommand("bonchat_clear") end)
    -- max msgs slider
    local cvarMaxMsgs = GetConVar(BonChat.CVAR.MAX_MSGS)
    self:AddSlider("Max Messages", BonChat.CVAR.MAX_MSGS, cvarMaxMsgs:GetInt(), cvarMaxMsgs:GetMin(), cvarMaxMsgs:GetMax(), 0)
    -- link length slider
    local cvarLinkLength = GetConVar(BonChat.CVAR.LINK_MAX_LENGTH)
    self:AddSlider("Max Link Length", BonChat.CVAR.LINK_MAX_LENGTH, cvarLinkLength:GetInt(), cvarLinkLength:GetMin(), cvarLinkLength:GetMax(), 0)
    -- chat tick toggle
    self:AddCheckbox("Play chat sound", BonChat.CVAR.CHAT_TICK, BonChat.CVAR.GetChatTick())
    -- auto dismiss toggle
    self:AddCheckbox("Auto dismiss messages", BonChat.CVAR.AUTO_DISMISS, BonChat.CVAR.GetAutoDismiss())
    -- image embeds toggle
    self:AddCheckbox("Show image attachments", BonChat.CVAR.SHOW_IMGS, BonChat.CVAR.GetShowImages())
    -- image height slider
    local cvarImageHeight = GetConVar(BonChat.CVAR.IMG_MAX_HEIGHT)
    self:AddSlider("Max Image Height", BonChat.CVAR.IMG_MAX_HEIGHT, cvarImageHeight:GetInt(), cvarImageHeight:GetMin(), cvarImageHeight:GetMax(), 0)
    -- skin tone emojis toggle
    self:AddCheckbox("Show results for skin tone emojis", BonChat.CVAR.SHOW_TONE_EMOJIS, BonChat.CVAR.GetShowToneEmojis())
  end,
  AddElement = function(self, class)
    local elem = self.panel:Add(class)
    elem:Dock(TOP)
    elem:DockMargin(5, 0, 5, 5)
    return elem
  end,
  AddButton = function(self, text, doClick)
    local btn = self:AddElement("DButton")
    btn:SetText(text)
    btn.DoClick = doClick
    return btn
  end,
  AddSlider = function(self, text, cvar, default, min, max, decimals)
    local slider = self:AddElement("DNumSlider")
    slider:SetText(text)
    slider:SetConVar(cvar)
    slider:SetDefaultValue(default)
    slider:SetMin(min)
    slider:SetMax(max)
    slider:SetDecimals(decimals)
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