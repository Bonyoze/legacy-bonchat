include(BonChat.DIR .. "convars.lua")
include(BonChat.DIR .. "message.lua")
include(BonChat.DIR .. "net_cl.lua")

include(BonChat.DIR .. "vgui/dhtml.lua")
include(BonChat.DIR .. "vgui/browser.lua")
include(BonChat.DIR .. "vgui/chatbox.lua")
include(BonChat.DIR .. "vgui/settings.lua")
include(BonChat.DIR .. "vgui/emojis.lua")
include(BonChat.DIR .. "vgui/attachments.lua")
include(BonChat.DIR .. "vgui/frame.lua")

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

function BonChat.SendInfoMessage(str)
  local msg = BonChat.Message()
  msg:SetDismissible()
  msg:SetCentered()
  msg:SetUnselectable()
  msg:AppendColor(color_white)
  msg:AppendMarkdown(str)
  BonChat.SendMessage(msg)
end

local color_log = Color(255, 75, 180)
local color_log2 = Color(200, 200, 200)
local color_log_err = Color(255, 90, 90)

function BonChat.Log(...)
  MsgC(color_log, "[BonChat] ", color_log2, ...)
  MsgN()
end

function BonChat.LogError(err, reason)
  BonChat.Log(color_log_err, "[ERR] ", color_log2, err .. (reason and " (" .. reason .. ")" or ""))
end

local sentBranchWarning

function BonChat.OpenChat(mode)
  chat.Open(mode)
  if not sentBranchWarning and BRANCH ~= "x86-64" then
    BonChat.SendInfoMessage(":i:error: **You are not using the x86-64 branch, so &ff0000&you may encounter bugs!**")
    BonChat.SendInfoMessage(":i:error: **If you prefer the default chatbox, you can type in console: &00ff00&bonchat_enable 0**")
    sentBranchWarning = true
  end
end

function BonChat.CloseChat()
  chat.Close()
end

function BonChat.ReloadChat()
  if IsValid(BonChat.frame) then BonChat.frame:Remove() end
  BonChat.frame = vgui.Create("BonChat_Frame")
end

function BonChat.ClearChat()
  if not IsValid(BonChat.frame) then return end
  -- empty chatbox html
  BonChat.frame.chatbox:CallJS("msgContainer.empty(); loadBtnWrapper.hide();")
  -- reset chatbox values
  BonChat.frame.chatbox.msgs = {}
  BonChat.frame.chatbox.msgsLookup = {}
  BonChat.frame.chatbox.msgIDNum = 0
  BonChat.frame.chatbox.newMsgs = 0
end

function BonChat.Say(text, mode)
  if BonChat.lastMsgTime and CurTime() - BonChat.lastMsgTime < BonChat.CVAR.GetMsgCooldown() then
    if not BonChat.sentWaitMsg then
      local wait = math.Round(BonChat.CVAR.GetMsgCooldown() - (CurTime() - BonChat.lastMsgTime), 3)
      BonChat.SendInfoMessage(":i:error: **You must wait " .. wait .. " second" .. (wait ~= 1 and "s" or "") .. " before sending another message!**")
      BonChat.sentWaitMsg = true
    end
    return
  end

  local attachments = BonChat.frame.attachments:GetAttachments()
  local totalAttachs = #attachments

  text = string.Left(text or "", BonChat.CVAR.GetMsgMaxLength())
  if #text == 0 then
    if totalAttachs > 0 then
      text = "(" .. totalAttachs .. " attachment" .. (totalAttachs > 1 and "s" or "") .. ")"
    else
      return
    end
  end

  net.Start("bonchat_say")
  net.WriteString(text)
  net.WriteBool(mode and mode ~= 1 or BonChat.chatMode ~= 1)
  net.WriteUInt(totalAttachs, 4)
  for i = 1, totalAttachs do
    local attach = attachments[i]
    net.WriteUInt(attach.type, 2)
    net.WriteString(attach.value)
  end
  BonChat.frame.attachments:ClearAttachments()
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
  BonChat.frame.chatbox:CallJSParams("entryInput.focus(); insertText('%s')", string.JavascriptSafe(text))
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

function BonChat.OpenPage(url, safe)
  if safe or BRANCH ~= "x86-64" then return BonChat.OpenURL(url) end
  BonChat.frame.browser:OpenPage(url)
end

function BonChat.OpenImage(title, url, w, h, minW, minH, safe)
  if safe or BRANCH ~= "x86-64" then return BonChat.OpenURL(url) end
  BonChat.frame.browser:OpenImage(title, url, w, h, minW, minH)
end

function BonChat.OpenVideo(title, url, w, h, minW, minH, safe)
  if safe or BRANCH ~= "x86-64" then return BonChat.OpenURL(url) end
  BonChat.frame.browser:OpenVideo(title, url, w, h, minW, minH)
end

function BonChat.OpenAudio(title, url, w, h, minW, minH, safe)
  if safe or BRANCH ~= "x86-64" then return BonChat.OpenURL(url) end
  BonChat.frame.browser:OpenAudio(title, url, w, h, minW, minH)
end

local imagePasteCache = {}

function BonChat.PasteImage(data)
  if not BonChat.frame.attachments:IsVisible() then
    BonChat.frame:HideAllSubPanels()
    BonChat.frame.attachments.btn.DoClick()
  end

  local function logFetchError(reason)
    BonChat.LogError("Failed to load image paste", reason)
  end

  local link = imagePasteCache[data]
  if link then -- check if we already requested for this
    BonChat.AddAttachment(link)
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
            BonChat.AddAttachment(link)
          else
            logFetchError("Request was unsuccessful")
          end
        else
          logFetchError(code)
        end
      end,
      failed = function(reason)
        logFetchError(reason)
      end
    })
  end
end

function BonChat.GetResource(name)
  local data = BonChat.resources[name]
  return data and util.Decompress(data)
end

local attachmentLoadCache = {}

function BonChat.LoadAttachment(url, success, fail)
  success = success or function() end
  fail = fail or function() end

  local data = attachmentLoadCache[url]
  if data then -- check if we already requested for this
    success(data)
  else -- attempt to fetch the data
    HTTP({
      url = url,
      method = "get",
      success = function(code, body, headers)
        if code == 200 then
          local mime = string.Split(headers["Content-Type"], ";")[1]

          -- parse data for attachment
          if string.match(mime, "^text/html") then
            local metas = {}
            for tag in string.gmatch(body, "<meta (.-)>") do
              local attrs = {}
              for name, val in string.gmatch(tag, "([^%s]-)=\"(.-)\"") do
                attrs[name] = val
              end
              table.insert(metas, attrs)
            end
            attachmentLoadCache[url] = {
              type = "EMBED",
              metas = metas
            }
          elseif string.match(mime, "^image/") then
            attachmentLoadCache[url] = {
              type = "IMAGE",
              base64 = "data:" .. mime .. ";base64, " .. util.Base64Encode(body, true)
            }
          elseif string.match(mime, "^video/") then
            attachmentLoadCache[url] = { type = "VIDEO" }
          elseif string.match(mime, "^audio/") then
            attachmentLoadCache[url] = { type = "AUDIO" }
          end

          if attachmentLoadCache[url] then
            success(attachmentLoadCache[url])
          else
            fail(2, mime) -- received unsupported mime type
          end

          return
        end
        fail(1, code) -- received bad code
      end,
      failed = function()
        fail(0) -- request failed
      end
    })
  end
end

function BonChat.AddAttachment(str)
  BonChat.frame.attachments:AddAttachment(str)
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

  BonChat.SendInfoMessage(":i:tick: **BonChat has successfully loaded**")

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

function BonChat.GetLastPlayerChat()
  return BonChat.lastPlayerChat or {}
end

-- concommands

concommand.Add("bonchat_say", function(_, _, _, argStr) BonChat.Say(argStr, 1) end)

concommand.Add("bonchat_say_team", function(_, _, _, argStr) BonChat.Say(argStr, 2) end)

concommand.Add("bonchat_reload", function()
  BonChat.CloseChat()
  BonChat.ReloadChat()

  BonChat.SendInfoMessage(":i:cog: **Chatbox was reloaded**")

  if BonChat.enabled then
    BonChat.EnableChat()
  else
    BonChat.DisableChat()
  end
end)

concommand.Add("bonchat_clear", function()
  BonChat.ClearChat()
  BonChat.SendInfoMessage(":i:bin: **Chatbox was cleared**")
end)

-- initializing

hook.Add("InitPostEntity", "BonChat_InitResources", function()
  net.Start("bonchat_resources")
  net.SendToServer()
  BonChat.resources = {}
end)

--[[hook.Add("OnGamemodeLoaded", "BonChat_Init", function()
  BonChat.InitChat()
end)]]

include("bonchat/custom_chat.lua")