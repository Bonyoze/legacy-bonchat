include("bonchat/vgui/frame.lua")

function BonChat.Log(...)
  MsgC(Color(255, 0, 105), "[BonChat] ", color_white, ...)
  MsgN()
end

function BonChat.OpenChat(mode)
  if not IsValid(BonChat.frame) then BonChat.ReloadChat() end
  BonChat.frame:OpenChat(mode);
end

function BonChat.CloseChat()
  if not IsValid(BonChat.frame) then BonChat.ReloadChat() end
  BonChat.frame:CloseChat()
end

function BonChat.ReloadChat()
  if BonChat.frame ~= nil and BonChat.frame:IsValid() then BonChat.frame:Remove() end
  BonChat.frame = vgui.Create("BonChat_Frame")
  chat.AddText(color_white, "BonChat has successfully loaded!")
end

function BonChat.ClearChat()
  BonChat.frame:CallJS("chatbox.html('')")
end

function BonChat.PrepareHTML()
  if BonChat.html then return hook.Call("BonChat_PrepareHTML") end

  http.Fetch("https://raw.githubusercontent.com/Bonyoze/gmod-bonchat/main/resources/chatbox.html",
    function(body, len, headers, code)
      if code == 200 then
        BonChat.html = body
        hook.Call("BonChat_PrepareHTML")
      else
        error("Failed to load HTML (response code " .. code .. ")")
      end
    end,
    function(err)
      error("Failed to load HTML (" .. err .. ")")
    end
  )
end


-- override to redirect to new chatbox
BonChat.oldAddText = BonChat.oldAddText or chat.AddText
function chat.AddText(...)
  if BonChat.frame ~= nil and BonChat.frame:IsValid() then
    BonChat.frame:AppendMessage(nil, ...)
  end
  BonChat.oldAddText(...)
end

hook.Add("HUDShouldDraw", "BonChat_HideDefaultChat", function(name)
  if name == "CHudChat" then
    return false
  end
end)

hook.Add("PlayerBindPress", "BonChat_OpenChat", function(_, bind, pressed)
  if not pressed then return end
  
  if bind == "messagemode" then
    BonChat.OpenChat(1)
  elseif bind == "messagemode2" then
    BonChat.OpenChat(2)
  end
end)

BonChat.PrepareHTML()

-- initialize the panel
hook.Add("BonChat_PrepareHTML", "", function()
  BonChat.ReloadChat()
end)

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