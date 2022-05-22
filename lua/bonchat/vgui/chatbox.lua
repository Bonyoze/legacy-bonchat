include("bonchat/vgui/dhtml.lua")

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
    self:Dock(FILL)

    self:AddFunc("showProfile", function(steamID)
      local ply = player.GetBySteamID(steamID)
      if ply then
        -- this function allows us to open the profile without having to ask first
        ply:ShowProfile()
      else
        -- fallback method if we can't get the player entity
        gui.OpenURL("https://steamcommunity.com/id/" .. util.SteamIDTo64(steamID))
      end
    end)
    self:AddFunc("toggleChatMode", function()
      BonChat.chatMode = BonChat.chatMode == 1 and 2 or 1
      self:CallJS("entryInput.attr('placeholder', 'typing in %s chat...')", BonChat.chatMode == 1 and "public" or "team")
    end)
    self:AddFunc("say", BonChat.Say)
    self:AddFunc("openPage", BonChat.OpenPage)
    self:AddFunc("openImage", BonChat.OpenImage)

    self:SetHTML(BonChat.GetResource("chatbox.html"))
    
    -- create emoji lookup table and send to panel
    local emojiData, emojiLookup = util.JSONToTable(BonChat.GetResource("emoji_data.json")), {}

    for _, v in pairs(emojiData) do
      for i = 1, #v, 2 do
        emojiData[v[i]] = v[i + 1]
      end
    end

    self:CallJS("EMOJI_DATA = JSON.parse('%s')", util.TableToJSON(emojiData))

    -- listen for enter and escape key

    local lastEnter = false
    local lastEscape = false

    hook.Add("Think", self, function()
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
    end)
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
          self:AddJS("msg.appendPlayer('%s', '%s', '%s')",
            string.JavascriptSafe(ent:Nick()),
            parseColorStyle(hook.Run("GetTeamColor", ent)),
            string.JavascriptSafe(ent:SteamID())
          )
        else
          self:AddJS("msg.appendText('%s')", string.JavascriptSafe(ent:GetClass()))
        end
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
    self:AddJS("msg.send()")

    self:RunJS()
  end,
  Open = function(self)
    -- need to request focus so the client can type
    self:RequestFocus()
    self:CallJS("PANEL_OPEN(%d)", BonChat.chatMode)
  end,
  Close = function(self)
    self:CallJS("PANEL_CLOSE()")
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "BonChat_DHTML")