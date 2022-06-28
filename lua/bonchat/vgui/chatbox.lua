include("bonchat/vgui/dhtml.lua")

local function isTyping(bool)
  if LocalPlayer().bonchatIsTyping == bool then return end -- ignore if didn't change
  LocalPlayer().bonchatIsTyping = bool
  net.Start("bonchat_istyping")
    net.WriteBool(bool)
  net.SendToServer()
end

--[[local function toggleChatMode()
  BonChat.chatMode = BonChat.chatMode == 1 and 2 or 1
  BonChat.frame.chatbox:CallJS("applyChatMode(%d)", BonChat.chatMode)
end]]

local function onTabKey(text) -- tries to mimic the tab functionality in the default chatbox
  local tbl = string.Split(string.Trim(text), " ")
  local last = string.lower(tbl[#tbl])

  -- try to complete the player name
  if #last > 0 then
    for k, v in ipairs(player.GetAll()) do
      local name = v:Nick()
      local sub = string.lower(string.sub(name, 1, #last))
      if sub == last then
        tbl[#tbl] = name
      end
    end
  end

  -- trick for setting the entry text and moving the caret to the end
  BonChat.SetText("")
  BonChat.InsertText(table.concat(tbl, " "))
end

local function prependHidden(currTotal)
  BonChat.frame.chatbox:PrependHiddenMessages(currTotal)
end

local function showProfile(steamID)
  local ply = player.GetBySteamID(steamID)
  if ply then
    -- this function allows us to open the profile without having to ask first
    ply:ShowProfile()
  else
    -- fallback method if we can't get the player entity
    gui.OpenURL("https://steamcommunity.com/id/" .. util.SteamIDTo64(steamID))
  end
end

local imagePasteCache = {}

local function logFetchError(reason)
  BonChat.LogError("Failed to load image paste", reason)
end

local function pasteImage(data)
  local cachedLink = imagePasteCache[data]
  if cachedLink then -- check if we already requested this exact base64 data
    BonChat.InsertText(cachedLink .. " ")
  else -- upload the image to Imgur and receive a link for it
    HTTP({
      url = "https://api.imgur.com/3/image.json?client_id=546c25a59c58ad7",
      method = "post",
      type = "application/json",
      parameters = {
        image = data,
        type = "base64"
      },
      success = function(code, body)
        if code == 200 then
          local result = util.JSONToTable(body)
          if result.success then
            local link = result.data.link
            imagePasteCache[data] = link
            BonChat.InsertText(link .. " ")
          else
            logFetchError("Request was unsuccessful")
          end
        else
          logFetchError(code)
        end
      end,
      failed = function(reason)
        logFetchError(reason)
      end,
    })
  end
end

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

local function jsSetData(name, val)
  return string.format("msg.MSG_WRAPPER.data('%s', '%s')",
    string.JavascriptSafe(name),
    isstring(val) and string.JavascriptSafe(val) or val
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
    self:AddFunc("isTyping", isTyping)
    self:AddFunc("onTabKey", onTabKey)
    self:AddFunc("prependHidden", prependHidden)
    self:AddFunc("showProfile", showProfile)
    self:AddFunc("pasteImage", pasteImage)
    self:AddFunc("showHoverLabel", BonChat.ShowHoverLabel)
    self:AddFunc("hideHoverLabel", BonChat.HideHoverLabel)
    self:AddFunc("say", BonChat.Say)
    self:AddFunc("openPage", BonChat.OpenPage)
    self:AddFunc("openImage", BonChat.OpenImage)

    self:SetHTML(BonChat.GetResource("chatbox.html"))

    self.OnCursorExited = function(self) BonChat.HideHoverLabel() end
    
    -- create emoji lookup table and send to panel
    local emojiData, emojiLookup = util.JSONToTable(BonChat.GetResource("emoji_data.json")), {}

    for _, v in pairs(emojiData) do
      for i = 1, #v, 2 do
        emojiData[v[i]] = v[i + 1]
      end
    end

    self:CallJSParams("EMOJI_DATA = JSON.parse('%s')", util.TableToJSON(emojiData))

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
    local id = self.msgIDNum

    -- add message
    table.insert(self.msgs, { id = id, msg = msg })
    self.msgsLookup[id] = msg

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
  NewMessage = function(self, msg, id, prependHidden)
    self:ReadyJS()

    -- create a new message object
    self:AddJS("var msg = new Message()")

    -- set message id
    if isnumber(id) then
      self:AddJS(jsSetData("msgID", id))
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
        )
      elseif t == msgArgTypes.MARKDOWN then
        self:AddJS("msg.appendMarkdown('%s')", string.JavascriptSafe(arg.value))
      elseif t == msgArgTypes.PLAYER then
        self:AddJS("msg.appendPlayer('%s', '%s', '%s')",
          string.JavascriptSafe(arg.name),
          arg.color and parseColorStyle(arg.color) or "",
          string.JavascriptSafe(arg.steamID or "")
        )
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
      local data = self.msgs[i]
      self:NewMessage(data.msg, data.id)
    end

    self:CallJSParams("updateLoadBtn(%d)", #self.msgs)
  end,
  PrependHiddenMessages = function(self, currTotal)
    local start = #self.msgs - currTotal
    local last = math.max(start - 99, 1)

    for i = start, last, -1 do
      local data = self.msgs[i]
      self:NewMessage(data.msg, data.id, true)
    end

    self:CallJSParams("loadBtn.removeClass('loading'); updateLoadBtn(%d)", #self.msgs)
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