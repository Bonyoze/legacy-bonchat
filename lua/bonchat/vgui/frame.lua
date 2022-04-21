include("bonchat/vgui/settings.lua")
include("bonchat/vgui/chatbox.lua")
include("bonchat/vgui/browser.lua")

local function jsAddClass(val)
  return string.format("msg.MSG_CONTAINER.addClass('%s')", string.JavascriptSafe(val))
end

local function jsSetData(name, val)
  return string.format("msg.MSG_CONTAINER.data('%s', '%s')",
    string.JavascriptSafe(name),
    string.JavascriptSafe(val)
  )
end

local optionRules = {
  CENTER_CONTENT    = jsAddClass("center-content"),
  CENTER_ATTACH     = jsAddClass("center-attachments"),
  NO_SELECT_CONTENT = jsAddClass("unselect-content"),
  NO_SELECT_ATTACH  = jsAddClass("unselect-attachments"),
  NO_TOUCH_CONTENT  = jsAddClass("untouch-content"),
  NO_TOUCH_ATTACH   = jsAddClass("untouch-attachments"),
  SHOW_TIMESTAMP    = jsAddClass("show-timestamp")
}

local msgArgTypes = BonChat.msgArgTypes

local PANEL = {
  Init = function(self)
    self:SetSize(ScrW() * 0.3, ScrH() * 0.435)
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

    self.btnSettings = self:Add("DButton")
    self.btnSettings:SetSize(20, 20)
    self.btnSettings:SetText("")
    self.btnSettings:SetPos(self:GetWide() - 24, 3)
    self.btnSettings:SetImage("icon16/cog.png")
    self.btnSettings.Paint = function() end
    self.btnSettings.DoClick = function() -- toggle settings panel visibility
      if self.settings:IsVisible() then return self.settings:Hide() end
      local x, y = self:LocalToScreen()
      self.settings:SetSize(ScrW() * 0.15, self:GetTall())
      self.settings:SetPos(x + self:GetWide() + 4, y)
      self.settings:Show()
      self.settings:MakePopup()
    end

    -- DHTML panel used for the actual chatbox
    self.chatbox = self:Add("BonChat_Chatbox")

    -- DFrame panel used for opening links in-game
    self.browser = vgui.Create("BonChat_Browser")

    -- fix scale of children on resize
    self.OnSizeChanged = function(self, w, h)
      self.settings:SetSize(ScrW() * 0.15, self:GetTall())
    end

    local lastEnter = false
    local lastEscape = false

    hook.Add("Think", self, function()
      if not self:IsKeyboardInputEnabled() then return end

      -- update position of children

      self.btnSettings:SetPos(self:GetWide() - 24, 3)

      if self.settings:IsVisible() then
        self.settings:SetPos(self:GetX() + self:GetWide() + 4, self:GetY())
      end

      -- listen for enter and escape key

      local enter = input.IsKeyDown(KEY_ENTER)
      local escape = input.IsKeyDown(KEY_ESCAPE)

      if not lastEnter and enter then -- on enter press, submit message and close chatbox
        -- we can't directly get the value, so we call a function with a lua callback
        self:CallJS("glua.say(entry.text())")
        BonChat.CloseChat()
      elseif not lastEscape and escape then -- on escape press, close the chatbox
        BonChat.CloseChat()
      end

      lastEnter = enter
      lastEscape = escape
    end)

    self:CloseFrame()
  end,
  CallJS = function(self, str, ...)
    self.chatbox:Call("(function() {" .. string.format(str, ...) .. "})()")
  end,
  tempJS = "",
  ReadyJS = function(self)
    tempJS = ""
  end,
  AddJS = function(self, str, ...)
    str = string.Trim(str)
    if str[#str] ~= ";" then
      str = str .. ";"
    end
    tempJS = tempJS .. string.format(str, ...)
  end,
  RunJS = function(self)
    self:CallJS(tempJS)
    self:ReadyJS()
  end,
  SendMessage = function(self, msg)
    self:ReadyJS()

    -- create a new message object
    self:AddJS("var msg = new Message()")

    -- set sender of message
    if IsValid(msg.sender) and msg.sender:IsPlayer() then
      local steamID = options.sender:SteamID()
      if steamID ~= "NULL" then -- can be 'NULL' if not authenticated with Steam
        self:AddJS(jsSetData("sender", steamID))
      end
    end
    
    -- apply options
    local opts = msg:GetOptions()
    for i = 1, #opts do
      local opt = opts[i]
      local rule = optionRules[opt]
      if rule then self:AddJS(rule) end
    end

    -- add the arguments
    local args = msg:GetArgs()
    for i = 1, #args do
      local arg = args[i]
      local t = arg.type

      if t == msgArgTypes.TEXT then
        self:AddJS("msg.appendText('%s')", string.JavascriptSafe(arg.value))
      elseif t == msgArgTypes.COLOR then
        self:AddJS("msg.setTextColor('rgb(%d,%d,%d)')",
          isnumber(arg.r) and arg.r % 256 or 255,
          isnumber(arg.g) and arg.g % 256 or 255,
          isnumber(arg.b) and arg.b % 256 or 255
        );
      elseif t == msgArgTypes.ENTITY then
        local ent = arg.value
        if ent == NULL then
          self:AddJS("msg.appendText('NULL')")
        elseif ent:IsPlayer() then
          local clr = hook.Run("GetTeamColor", ent)
          self:AddJS("msg.appendPlayer('%s', '%s', '%s')",
            string.JavascriptSafe(ent:Nick()),
            "rgb(" .. clr.r .. "," .. clr.g .. "," .. clr.b .. ")",
            string.JavascriptSafe(ent:SteamID())
          )
        else
          self:AddJS("msg.appendText('%s')", string.JavascriptSafe(ent:GetClass()))
        end
      elseif t == msgArgTypes.MARKDOWN then
        self:AddJS("msg.appendMarkdown('%s')", string.JavascriptSafe(arg.value))
      elseif t == msgArgTypes.PLAYER then
        local clr = arg.color
        if clr then -- correct any color values
          clr = Color(
            isnumber(clr.r) and clr.r % 256 or 255,
            isnumber(clr.g) and clr.g % 256 or 255,
            isnumber(clr.b) and clr.b % 256 or 255
          )
        end

        self:AddJS("msg.appendPlayer('%s', '%s', '%s')",
          string.JavascriptSafe(arg.name),
          clr and "rgb(" .. clr.r .. "," .. clr.g .. "," .. clr.b .. ")" or "",
          string.JavascriptSafe(arg.steamID or "NULL")
        )
      end
    end

    -- send the message element to the chatbox
    self:AddJS("msg.send()")

    self:RunJS()
  end,
  OpenFrame = function(self)
    -- move the frame to the front and enable input
    self:MakePopup()

    -- start painting frame
    self.Paint = self.openPaint

    -- show parts
    self.btnSettings:Show()

    -- need to request focus so the client can type in it
    self.chatbox:RequestFocus()

    self:CallJS("CHATBOX_PANEL_OPEN()")
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
    self.browser:Hide()

    self:CallJS("CHATBOX_PANEL_CLOSE()")
  end,
  OnRemove = function(self)
    -- cleanup
    self.browser:Remove()
  end
}

vgui.Register("BonChat_Frame", PANEL, "DFrame")