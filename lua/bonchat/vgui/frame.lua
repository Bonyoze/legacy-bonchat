include("bonchat/vgui/chatbox.lua")
include("bonchat/vgui/settings.lua")

local PANEL = {
  Init = function(self)
    self:SetSize(ScrW() * 0.25, ScrH() * 0.5)
    self:SetPos(ScrW() * 0.02, (ScrH() - self:GetTall()) - ScrH() * 0.115)
    self:SetMinWidth(self:GetWide())
    self:SetMinHeight(self:GetTall())
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetSizable(true)
    self:SetScreenLock(true)

    self.Paint = function(self, w, h)
      self:DrawBlur(1, 1)
      surface.SetDrawColor(30, 30, 30)
      surface.DrawOutlinedRect(0, 0, w, h, 2)
      surface.DrawRect(0, 0, w, 25)
    end

    self.settings = self:Add("BonChat_Settings")
    self.settings:Hide()

    self.btnSettings = self:Add("DButton")
    self.btnSettings:SetSize(20, 20)
    self.btnSettings:SetText("")
    self.btnSettings:SetPos(self:GetWide() - 24, 3)
    self.btnSettings:SetImage("icon16/cog.png")
    self.btnSettings.Paint = function() end
    self.btnSettings.DoClick = function() -- toggle settings panel visibility
      if self.settings:IsVisible() then return self.settings:Hide() end
      local x, y = self:LocalToScreen()
      self.settings:SetSize(ScrW() * 0.15, self:GetTall() * 0.5)
      self.settings:SetPos(x + self:GetWide() + 4, y)
      self.settings:Show()
      self.settings:MakePopup()
    end

    self.chatbox = self:Add("BonChat_Chatbox")

    // fix scale of children on resize
    self.OnSizeChanged = function(self, w, h)
      self.settings:SetSize(ScrW() * 0.15, self:GetTall() * 0.5)
    end

    local lastEnter = false
    local lastEscape = false

    hook.Add("Think", self, function()
      if not self:IsVisible() then return end

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
        self:CloseChat()
      elseif not lastEscape and escape then -- on escape press, close the chatbox
        self:CloseChat()
      end

      lastEnter = enter
      lastEscape = escape
    end)

    hook.Add("ChatText", self, function(_, _, _, text, type)
      self:AppendMessage(nil, text)
    end)

    self:Hide()
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
  AppendMessage = function(self, options, ...)
    self:ReadyJS()

    -- create a new message object
    self:AddJS("var msg = new Message()")

    -- add the message components
    for _, v in ipairs({...}) do
      if isstring(v) then
        self:AddJS("msg.appendText('%s')", string.JavascriptSafe(v))
      elseif istable(v) then
        -- set the current text color
        self:AddJS("msg.setTextColor('rgb(%d,%d,%d)')",
          isnumber(v.r) and v.r % 256 or 255,
          isnumber(v.g) and v.g % 256 or 255,
          isnumber(v.b) and v.b % 256 or 255
        );
      elseif isentity(v) then
        if v == NULL then
          self:AddJS("msg.appendText('NULL')")
        elseif v:IsPlayer() then
          -- chat.AddText handles the coloring for player entities by ignoring the current text color and using team color
          -- so here we set the text color to the team color and then revert it back to not affect anything after
          local clr = hook.Run("GetTeamColor", v)
          self:AddJS("var clr = msg.textColor")
          self:AddJS("msg.setTextColor('rgb(%d,%d,%d)')", clr.r, clr.g, clr.b)
          self:AddJS("msg.appendText('%s')", "**" .. string.JavascriptSafe(v:Nick()) .. "**")
          self:AddJS("msg.setTextColor(clr)")
        else
          self:AddJS("msg.appendText('%s')", string.JavascriptSafe(v:GetClass()))
        end
      end
    end

    -- send the message element to the chatbox
    self:AddJS("msg.send()")

    self:RunJS()
  end,
  OpenChat = function(self, mode)
    chat.Open(mode)
    self:Show()
    self:MakePopup()
    self.chatbox:RequestFocus() -- need to request focus so the client can type in it
    self:CallJS("entry.focus()")
  end,
  CloseChat = function(self)
    chat.Close()
    self:Hide()

    -- clear the entry where the client inputs the message
    -- then scroll to bottom of chatbox
    self:CallJS([[
      entry.text("");
      scrollToBottom();
    ]])
  end
}

vgui.Register("BonChat_Frame", PANEL, "DFrame")