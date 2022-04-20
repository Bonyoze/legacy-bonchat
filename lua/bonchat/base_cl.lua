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
  if IsValid(BonChat.frame) then BonChat.frame:Remove() end
  BonChat.frame = vgui.Create("BonChat_Frame")
end

function BonChat.AppendMessage(options, ...)
  BonChat.frame:AppendMessage(options or {}, ...)
end

function BonChat.ClearChat()
  BonChat.frame:CallJS("chatbox.html('')")
end

function BonChat.Say(text)
  if not text or #text == 0 then return end

  net.Start("BonChat_say")
    net.WriteString(string.Left(text, BonChat.GetMsgMaxLen()))
    net.WriteBool(BonChat.chatMode ~= 1)
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
  if BRANCH == "unknown" then return BonChat.OpenURL(url) end
  BonChat.frame.browser:OpenImage(url, w, h, minW, minH)
end

function BonChat.GetResource(name)
  return include("bonchat/resources/" .. name .. ".lua")
end

-- override chat functions to use the new chatbox

BonChat.oldChatAddText = BonChat.oldChatAddText or chat.AddText
function chat.AddText(...)
  BonChat:AppendMessage({}, ...)
  BonChat.oldChatAddText(...)
end

BonChat.oldChatOpen = BonChat.oldChatOpen or chat.Open
function chat.Open(mode, ...)
  if BonChat.enabled then
    BonChat.chatMode = mode
    BonChat.frame:OpenFrame()
  end
  BonChat.oldChatOpen(mode, ...)
end

BonChat.oldChatClose = BonChat.oldChatClose or chat.Close
function chat.Close(...)
  if BonChat.enabled then BonChat.frame:CloseFrame() end
  BonChat.oldChatClose(...)
end

local panelMeta = FindMetaTable("Panel")
local blur = Material("pp/blurscreen")

-- custom panel functions

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

-- receive player messages sent using the chatbox
net.Receive("BonChat_say", function()
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

-- initializing

function BonChat.InitChatbox()
  BonChat.ReloadChat()
  BonChat.AppendMessage(
    {
      contentCentered = true,
      contentUnselectable = true,
      attachmentsCentered = true,
      attachmentsUnselectable = true,
      attachmentsUntouchable = true
    },
    color_white,
    ":icon:accept: **BonChat has successfully loaded** https://media.discordapp.net/attachments/292328649711943680/883812645105446922/25.gif"
  )
  if BonChat.enabled then
    BonChat.EnableChatbox()
  else
    BonChat.DisableChatbox()
  end
end

function BonChat.EnableChatbox()
  hook.Add("HUDShouldDraw", "BonChat_HideDefaultChat", hideDefaultChat)
  hook.Add("PlayerBindPress", "BonChat_OpenChat", openChat)
  BonChat.frame.chatbox:Show()
end

function BonChat.DisableChatbox()
  hook.Remove("HUDShouldDraw", "BonChat_HideDefaultChat")
  hook.Remove("PlayerBindPress", "BonChat_OpenChat")
  BonChat.frame.chatbox:Hide()
end

hook.Add("Initialize", "BonChat_Initialize", BonChat.InitChatbox)

if GAMEMODE then
  BonChat.InitChatbox()
end