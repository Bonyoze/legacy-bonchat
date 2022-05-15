include("bonchat/message.lua")
include("bonchat/vgui/frame.lua")

function BonChat.Log(...)
  MsgC(Color(255, 0, 105), "[BonChat] ", color_white, ...)
  MsgN()
end

function BonChat.OpenChat(mode)
  chat.Open(mode)
end

function BonChat.CloseChat()
  chat.Close()
end

function BonChat.ReloadChat()
  if IsValid(BonChat.frame) then
    BonChat.CloseChat()
    BonChat.frame:Remove()
  end
  BonChat.frame = vgui.Create("BonChat_Frame")
end

function BonChat.ClearChat()
  BonChat.frame:CallJS("chatbox.html('')")
end

function BonChat.Say(text, mode)
  if not text or #text == 0 then return end

  net.Start("BonChat_say")
    net.WriteString(string.Left(text, BonChat.GetMsgMaxLen()))
    net.WriteBool(mode and mode ~= 1 or BonChat.chatMode ~= 1)
  net.SendToServer()
end

function BonChat.OpenURL(url)
  if not url or #url == 0 then return end

  if not (string.StartWith(url, "https://") or string.StartWith(url, "http://")) then
    return BonChat.Log("Cannot open a URL unless it's using the protocol 'https' or 'http'!")
  end
  if #url > 512 then
    return BonChat.Log("Cannot open a URL more than 512 characters long!", Color(180, 180, 180), " (https://github.com/Facepunch/garrysmod-issues/issues/4663)")
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

local function sendInfoMessage(str)
  local msg = BonChat.Message()
  msg:SetCentered()
  msg:SetUnselectable()
  msg:SetUntouchable()
  msg:AppendColor(color_white)
  msg:AppendMarkdown(str)
  BonChat.SendMessage(msg)
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

function BonChat.InitChat()
  BonChat.ReloadChat()

  sendInfoMessage(":i:tick: **BonChat has successfully loaded**")

  if BonChat.enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end
end

function BonChat.EnableChat()
  hook.Add("HUDShouldDraw", "BonChat_HideDefaultChat", hideDefaultChat)
  hook.Add("PlayerBindPress", "BonChat_OpenChat", openChat)
  BonChat.frame.chatbox:Show()
end

function BonChat.DisableChat()
  hook.Remove("HUDShouldDraw", "BonChat_HideDefaultChat")
  hook.Remove("PlayerBindPress", "BonChat_OpenChat")
  BonChat.frame.chatbox:Hide()
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
  if BonChat.enabled and IsValid(BonChat.frame) then
    BonChat.chatMode = mode
    BonChat.frame:OpenFrame()
  end
  BonChat.oldChatOpen(mode, ...)
end

BonChat.oldChatClose = BonChat.oldChatClose or chat.Close
function chat.Close(...)
  if BonChat.enabled and IsValid(BonChat.frame) then BonChat.frame:CloseFrame() end
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

-- receive player messages sent using the chatbox
net.Receive("BonChat_Say", function()
  local ply = net.ReadEntity()
  local text = net.ReadString()
  local team = net.ReadBool()
  hook.Run("OnPlayerChat",
    ply,
    text,
    team,
    IsValid(ply) and not ply:Alive() or false
  )
end)

-- concommands

concommand.Add("bonchat_reload", function()
  BonChat.CloseChat()
  BonChat.ReloadChat()
  if BonChat.enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end
  sendInfoMessage(":i:cog: **Chatbox was reloaded**")
end)

concommand.Add("bonchat_clear", function()
  BonChat.ClearChat()
  sendInfoMessage(":i:bin: **Chatbox was cleared**")
end)

-- initializing

hook.Add("Initialize", "BonChat_Initialize", BonChat.InitChat)

if GAMEMODE then
  BonChat.InitChat()
end

include("bonchat/custom_chat.lua")