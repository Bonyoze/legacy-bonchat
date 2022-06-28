include("bonchat/message.lua")
include("bonchat/vgui/frame.lua")

-- cvars
cvars.AddChangeCallback(BonChat.CVAR.ENABLED, function(_, _, new)
  local num = tonumber(new)
  if not num then return RunConsoleCommand(BonChat.CVAR.ENABLED, 1) end

  local enabled = num ~= 0
  if BonChat.enabled == enabled then return end
  
  if enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end

  BonChat.enabled = enabled
end)

BonChat.enabled = BonChat.CVAR.GetEnabled()

function BonChat.UpdateJSConVar(name, val)
  if not IsValid(BonChat.frame) or not IsValid(BonChat.frame.chatbox) then return end
  BonChat.frame.chatbox:UpdateConVar(name, val)
end

local jsConVars = {}

function BonChat.UpdateAllJSConVars()
  for cvar, _ in pairs(jsConVars) do
    BonChat.UpdateJSConVar(cvar, GetConVar(cvar):GetString())
  end
end

local function addJSConVar(cvar)
  jsConVars[cvar] = true
  BonChat.AddConvarCallback(cvar, function(name, _, val) BonChat.UpdateJSConVar(name, val) end)
end

-- js convars
addJSConVar(BonChat.CVAR.MSG_MAX_LEN)
addJSConVar(BonChat.CVAR.LINK_MAX_LEN)
addJSConVar(BonChat.CVAR.SHOW_IMGS)

local function sendInfoMessage(str)
  local msg = BonChat.Message()
  msg:SetCentered()
  msg:SetUnselectable()
  msg:SetUntouchable()
  msg:AppendColor(color_white)
  msg:AppendMarkdown(str)
  BonChat.SendMessage(msg)
end

function BonChat.Log(...)
  MsgC(Color(255, 0, 105), "[BonChat] ", color_white, ...)
  MsgN()
end

function BonChat.LogError(err, reason)
  BonChat.Log(err, Color(180, 180, 180), reason and (" (" .. reason .. ")") or "")
end

function BonChat.OpenChat(mode)
  chat.Open(mode)
end

function BonChat.CloseChat()
  chat.Close()
end

function BonChat.ReloadChat()
  if IsValid(BonChat.frame) then BonChat.frame:Remove() end
  BonChat.frame = vgui.Create("BonChat_Frame")
  BonChat.UpdateAllJSConVars() -- initialize convar values in the chatbox
end

function BonChat.ClearChat()
  if not IsValid(BonChat.frame) then return end
  BonChat.frame.chatbox:CallJS("msgContainer.empty(); loadBtnWrapper.hide();")
  BonChat.frame.chatbox.msgs = {}
end

function BonChat.Say(text, mode)
  if BonChat.lastMsgTime and CurTime() - BonChat.lastMsgTime < BonChat.CVAR.GetMsgCooldown() then
    if not BonChat.sentWaitMsg then
      local wait = math.Round(BonChat.CVAR.GetMsgCooldown() - (CurTime() - BonChat.lastMsgTime), 3)
      sendInfoMessage(":i:error: **You must wait " .. wait .. " second" .. (wait ~= 1 and "s" or "") .. " before sending another message!**")
      BonChat.sentWaitMsg = true
    end
    return
  end

  text = string.Left(text or "", BonChat.CVAR.GetMsgMaxLen())
  if #text == 0 then return end

  net.Start("bonchat_say")
    net.WriteString(text)
    net.WriteBool(mode and mode ~= 1 or BonChat.chatMode ~= 1)
  net.SendToServer()

  BonChat.lastMsgTime = CurTime()
  BonChat.sentWaitMsg = false
end

function BonChat.ShowHoverLabel(text)
  BonChat.frame:SetHoverLabel(text)
end

function BonChat.HideHoverLabel()
  BonChat.frame:SetHoverLabel(nil)
end

function BonChat.SetText(text)
  BonChat.frame.chatbox:CallJSParams("entryInput.text('%s')", string.JavascriptSafe(text))
end

function BonChat.InsertText(text)
  BonChat.frame.chatbox:CallJSParams("entryInput.focus(); insertText('%s');", string.JavascriptSafe(text))
end

function BonChat.OpenURL(url)
  if not url or #url == 0 then return end

  if not string.match(url, "^https?://") then
    return BonChat.LogError("Cannot open a URL unless it's using the protocol 'https' or 'http'!")
  end
  if #url > 512 then
    return BonChat.LogError("Cannot open a URL more than 512 characters long!", "https://github.com/Facepunch/garrysmod-issues/issues/4663")
  end

  BonChat.CloseChat()
  gui.OpenURL(url)
end

function BonChat.OpenPage(url)
  if BRANCH == "unknown" then return BonChat.OpenURL(url) end
  BonChat.frame.browser:OpenPage(url)
end

function BonChat.OpenImage(url, w, h, minW, minH)
  BonChat.frame.browser:OpenImage(url, w, h, minW, minH)
end

function BonChat.GetResource(name)
  return include("bonchat/resources/" .. name .. ".lua")
end

local function hideDefaultChat(name)
  if name == "CHudChat" then
    return false
  end
end

local function openChat(_, bind, pressed)
  if not pressed then return end
  
  if bind == "messagemode" then
    BonChat.OpenChat(1)
  elseif bind == "messagemode2" then
    BonChat.OpenChat(2)
  end
end

local function chatTick(ply)
  if BonChat.CVAR.GetChatTick() and ply ~= LocalPlayer() then
    chat.PlaySound()
  end
end

function BonChat.EnableChat()
  hook.Add("HUDShouldDraw", "BonChat_HideDefaultChat", hideDefaultChat)
  hook.Add("PlayerBindPress", "BonChat_OpenChat", openChat)
  hook.Add("OnPlayerChat", "BonChat_ChatTick", chatTick)
  BonChat.frame.chatbox:Show()
end

function BonChat.DisableChat()
  hook.Remove("HUDShouldDraw", "BonChat_HideDefaultChat")
  hook.Remove("PlayerBindPress", "BonChat_OpenChat")
  hook.Remove("OnPlayerChat", "BonChat_ChatTick")
  BonChat.frame.chatbox:Hide()
end

function BonChat.InitChat()
  BonChat.ReloadChat()

  sendInfoMessage(":i:tick: **BonChat has successfully loaded**")

  if BonChat.enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end
end

local suppressDefault = false

function BonChat.SuppressDefaultMsg()
  suppressDefault = true
  timer.Simple(0, function() suppressDefault = false end)
end

-- override chat functions to use the new chatbox

BonChat.oldChatAddText = BonChat.oldChatAddText or chat.AddText
function chat.AddText(...)
  if not suppressDefault then
    local msg = BonChat.Message()
    msg:AppendArgs(...)
    BonChat.SendMessage(msg)
  else
    suppressDefault = false
  end
  BonChat.oldChatAddText(...)
end

BonChat.oldChatOpen = BonChat.oldChatOpen or chat.Open
function chat.Open(mode, ...)
  if BonChat.enabled and IsValid(BonChat.frame) and not BonChat.frame.isOpen then
    BonChat.chatMode = mode
    BonChat.frame:OpenFrame()
  end
  BonChat.oldChatOpen(mode, ...)
end

BonChat.oldChatClose = BonChat.oldChatClose or chat.Close
function chat.Close(...)
  if BonChat.enabled and IsValid(BonChat.frame) and BonChat.frame.isOpen then BonChat.frame:CloseFrame() end
  BonChat.oldChatClose(...)
end

-- custom panel functions

local panelMeta = FindMetaTable("Panel")
local blur = Material("pp/blurscreen")

panelMeta.DrawBlur = function(self, layers, density, alpha)
  surface.SetDrawColor(255, 255, 255, alpha)
  surface.SetMaterial(blur)

  for i = 1, 3 do
    blur:SetFloat("$blur", i / layers * density)
    blur:Recompute()
    render.UpdateScreenEffectTexture()
    surface.DrawTexturedRect(-self:GetX(), -self:GetY(), ScrW(), ScrH())
  end
end

-- concommands

concommand.Add("bonchat_reload", function()
  BonChat.CloseChat()
  BonChat.ReloadChat()

  sendInfoMessage(":i:cog: **Chatbox was reloaded**")

  if BonChat.enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end
end)

concommand.Add("bonchat_clear", function()
  BonChat.frame.chatbox.messageQueue = {}
  BonChat.ClearChat()
  sendInfoMessage(":i:bin: **Chatbox was cleared**")
end)

-- player sent a message through the chatbox
net.Receive("bonchat_say", function()
  local ply = net.ReadEntity()
  local text = net.ReadString()
  local teamChat = net.ReadBool()
  local isDead = net.ReadBool()

  hook.Run("OnPlayerChat", ply, text, teamChat, isDead)
end)

-- player is typing in the chatbox
net.Receive("bonchat_istyping", function()
  local ply, typing = net.ReadEntity(), net.ReadBool()
  ply.bonchatIsTyping = typing
end)

-- initializing

hook.Add("OnGamemodeLoaded", "BonChat_Initialize", BonChat.InitChat)

if GAMEMODE then
  BonChat.InitChat()
end

include("bonchat/custom_chat.lua")