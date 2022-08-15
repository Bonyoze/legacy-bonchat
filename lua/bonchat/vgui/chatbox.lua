
--[[local function toggleChatMode()
  BonChat.chatMode = BonChat.chatMode == 1 and 2 or 1
  BonChat.frame.chatbox:CallJS("applyChatMode(%d)", BonChat.chatMode)
end]]

local function parseColorStyle(clr)
  return "rgb("
    .. (isnumber(clr.r) and clr.r % 256 or 255)
    .. ","
    .. (isnumber(clr.g) and clr.g % 256 or 255)
    .. ","
    .. (isnumber(clr.b) and clr.b % 256 or 255)
    .. ")"
end

local function jsAddClass(val)
  return string.format("msg.MSG_WRAPPER.addClass('%s')",
    string.JavascriptSafe(val)
  )
end

local function jsSetDataAttr(name, val)
  return string.format("msg.MSG_WRAPPER.attr('data-%s', '%s')",
    string.JavascriptSafe(name),
    isstring(val) and string.JavascriptSafe(val) or val
  )
end

local optionRules = {
  DISMISSIBLE       = jsAddClass("dismissible"),
  CENTER_CONTENT    = jsAddClass("center-content"),
  CENTER_ATTACH     = jsAddClass("center-attachments"),
  NO_SELECT_CONTENT = jsAddClass("unselect-content"),
  NO_SELECT_ATTACH  = jsAddClass("unselect-attachments"),
  NO_TOUCH_CONTENT  = jsAddClass("untouch-content"),
  NO_TOUCH_ATTACH   = jsAddClass("untouch-attachments"),
  SHOW_TIMESTAMP    = jsAddClass("show-timestamp")
}

BonChat.AddConvarCallback(BonChat.CVAR.MAX_MSGS, function(_, _, maxMsgs)
  maxMsgs = tonumber(maxMsgs)
  local chatbox = BonChat.frame.chatbox
  if #chatbox.msgs > maxMsgs then
    for i = 1, #chatbox.msgs - maxMsgs do
      table.remove(chatbox.msgs, 1)
    end
  end
  chatbox:CallJSParams("resetLoadBtn(%d)", #chatbox.msgs)
end)

local PANEL = {
  Init = function(self)
    self:Dock(FILL)

    self:AddFunc("playSound", surface.PlaySound)
    --self.dhtml:AddFunc("setClipboardText", SetClipboardText)

    self:AddFunc("showHoverLabel", BonChat.ShowHoverLabel)
    self:AddFunc("hideHoverLabel", BonChat.HideHoverLabel)
    self:AddFunc("say", BonChat.Say)
    self:AddFunc("openPage", BonChat.OpenPage)
    self:AddFunc("openImage", BonChat.OpenImage)
    self:AddFunc("pasteImage", BonChat.PasteImage)

    self:AddFunc("prependHiddenMessages", function(currTotal) self:PrependHiddenMessages(currTotal) end)
    self:AddFunc("dismissMessage", function(id) self:DismissMessage(id) end)

    self:AddFunc("isTyping", function(bool)
      if LocalPlayer().bonchatIsTyping == bool then return end -- ignore if didn't change
      LocalPlayer().bonchatIsTyping = bool
      net.Start("bonchat_istyping")
        net.WriteBool(bool)
      net.SendToServer()
    end)
    self:AddFunc("onTabKey", function(text) -- implement same tab functionality used in the default chatbox
      -- trick for setting the entry text and moving the caret to the end
      BonChat.SetText("")
      BonChat.InsertText(hook.Run("OnChatTab", text))
    end)
    self:AddFunc("showProfile", function(steamID)
      local ply = player.GetBySteamID(steamID)
      if ply then
        -- this function allows us to open the profile without having to ask first
        ply:ShowProfile()
      else
        -- fallback method if we can't get the player entity
        gui.OpenURL("https://steamcommunity.com/profiles/" .. util.SteamIDTo64(steamID))
      end
    end)
    self:AddFunc("retryAttachment", function(msgID, attachID, src)
      local attachImg = string.format("getAttachmentByID(%d, getMessageByID(%d)).find('img')", attachID, msgID)
      BonChat.LoadAttachment(src, function(newSrc)
        self:CallJSParams(attachImg .. ".attr('src', '%s')", newSrc)
      end, function()
        self:CallJS(attachImg .. ".trigger('error')")
      end)
    end)

    self:SetHTML(BonChat.GetResource("chatbox.html"))

    self.OnCursorExited = function(self) BonChat.HideHoverLabel() end
    
    -- create emoji lookup table and send to panel
    local emojiData, emojiLookup = util.JSONToTable(BonChat.GetResource("emoji_data.json")), {}

    for _, v in pairs(emojiData) do
      for i = 1, #v, 2 do
        emojiLookup[v[i]] = v[i + 1]
      end
    end

    self:CallJSParams("EMOJI_DATA = JSON.parse('%s')", util.TableToJSON(emojiLookup))

    local lastEnter = false
    local lastEscape = false

    local lastCheckTime = 0

    hook.Add("Think", self, function()
      -- listen for enter and escape key

      local enter = input.IsKeyDown(KEY_ENTER)
      local escape = input.IsKeyDown(KEY_ESCAPE)

      if not lastEnter and enter then -- on enter press, submit message and close it
        if not self:HasFocus() then return end
        self:CallJS("glua.say(getText())")
        BonChat.CloseChat()
      elseif not lastEscape and escape then -- on escape press, close it
        BonChat.CloseChat()
      end

      lastEnter = enter
      lastEscape = escape

      -- check if any new messages came in
      self:AppendNewMessages()
    end)

    self.msgs = {}
    self.msgsLookup = {}
    self.msgIDNum = 0
    self.newMsgs = 0
  end,
  SendMessage = function(self, msg)
    -- add message
    msg:SetID(self.msgIDNum)
    table.insert(self.msgs, msg)
    self.msgsLookup[self.msgIDNum] = msg

    -- increment vars
    self.msgIDNum = self.msgIDNum + 1
    self.newMsgs = self.newMsgs + 1

    -- remove oldest message if total exceeds the cvar
    local maxMsgs = BonChat.CVAR.GetMaxMsgs()
    if #self.msgs > maxMsgs then
      for i = 1, #self.msgs - maxMsgs do
        table.remove(self.msgs, 1)
      end
    end
  end,
  NewMessage = function(self, msg, prependHidden)
    self:ReadyJS()

    -- create a new message object
    local id = msg:GetID()
    if id then
      self:AddJS("var msg = new Message(%d)", id)
    else
      self:AddJS("var msg = new Message()")
    end

    -- apply options
    local opts = msg:GetOptions()
    for i = 1, #opts do
      local opt = opts[i]
      local rule = optionRules[opt]
      if rule then self:AddJS(rule) end
    end

    -- add arguments
    local args = msg:GetArgs()
    for i = 1, #args do
      local arg = args[i]
      local t, v = arg.type, arg.value

      if t == BonChat.msgArgTypes.TEXT then
        self:AddJS("msg.appendText('%s')", string.JavascriptSafe(v))
      elseif t == BonChat.msgArgTypes.COLOR then
        self:AddJS("msg.setTextColor('rgb(%d,%d,%d)')",
          isnumber(v.r) and v.r % 256 or 255,
          isnumber(v.g) and v.g % 256 or 255,
          isnumber(v.b) and v.b % 256 or 255
        )
      elseif t == BonChat.msgArgTypes.MARKDOWN then
        self:AddJS("msg.appendMarkdown('%s')", string.JavascriptSafe(v))
      elseif t == BonChat.msgArgTypes.PLAYER then
        self:AddJS("msg.appendPlayer('%s', '%s', '%s')",
          string.JavascriptSafe(v.name),
          v.color and parseColorStyle(v.color) or "",
          string.JavascriptSafe(v.steamID or "")
        )
      end
    end

    -- add attachments
    local attachments = msg:GetAttachments()
    for i = 1, #attachments do
      local attachment = attachments[i]
      local t, v = attachment.type, attachment.value

      if t == BonChat.msgAttachTypes.IMAGE then
        self:AddJS("msg.appendImage('%s')", string.JavascriptSafe(v))
      elseif t == BonChat.msgAttachTypes.VIDEO then
        self:AddJS("msg.appendVideo('%s')", string.JavascriptSafe(v))
      end
    end

    -- send the message element
    self:AddJS("msg.send(%d)", prependHidden and 1 or 0)

    self:RunJS()
  end,
  AppendNewMessages = function(self)
    if self.newMsgs == 0 then return end
    local amt = self.newMsgs
    self.newMsgs = 0

    local last = #self.msgs
    local start = last - math.min(amt, 100) + 1

    for i = start, last do -- append up to 100 of the new messages to the chatbox
      self:NewMessage(self.msgs[i])
    end

    self:CallJSParams("updateLoadBtn(%d)", #self.msgs)
  end,
  PrependHiddenMessages = function(self, currTotal)
    local start = #self.msgs - currTotal
    local last = math.max(start - 99, 1)

    for i = start, last, -1 do
      self:NewMessage(self.msgs[i], true)
    end

    self:CallJSParams("loadBtn.removeClass('loading'); updateLoadBtn(%d)", #self.msgs)
  end,
  DismissMessage = function(self, id)
    local msg = self.msgsLookup[id]
    if not msg then return end
    local key = table.KeyFromValue(self.msgs, msg)
    if not key then return end

    table.remove(self.msgs, key)
    self.msgsLookup[id] = nil
    self:CallJSParams("getMessageByID(%d).remove()", id) -- try to find and remove the message
  end,
  Open = function(self)
    -- need to request focus so the client can type
    self:RequestFocus()
    self:CallJSParams("PANEL_OPEN(%d)", BonChat.chatMode)
  end,
  Close = function(self)
    self:CallJSParams("PANEL_CLOSE(%d)", #self.msgs)
  end,
  UpdateConVar = function(self, name, val)
    self:CallJSParams("updateConVar('%s', '%s')", string.JavascriptSafe(name), string.JavascriptSafe(val))
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "BonChat_DHTML")