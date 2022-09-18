util.AddNetworkString("bonchat_resources")
util.AddNetworkString("bonchat_resources_data")
util.AddNetworkString("bonchat_resources_ready")
util.AddNetworkString("bonchat_say")
util.AddNetworkString("bonchat_istyping")

net.Receive("bonchat_resources", function(_, ply)
  if ply.bonchatInitResources then return end

  coroutine.wrap(function()
    local co = coroutine.running()

    net.Start("bonchat_resources")
    net.WriteUInt(#BonChat.resourcePaths, 8)
    net.Send(ply)

    for _, v in ipairs(BonChat.resourcePaths) do
      net.Start("bonchat_resources_data")
      net.WriteString(v)
      local data = util.Compress(file.Read(BonChat.RESOURCE_DIR .. v .. (string.StartWith(v, "bonchat/") and ".lua" or ""), "LUA") or "")
      net.WriteUInt(#data, 16)
      net.WriteData(data)
      net.Send(ply)

      timer.Simple(0.1, function() coroutine.resume(co) end)
      coroutine.yield()
    end

    net.Start("bonchat_resources_ready")
    net.Send(ply)
  end)()

  ply.bonchatInitResources = true
end)

net.Receive("bonchat_say", function(_, ply)
  if ply.bonchatLastMsgTime and CurTime() - ply.bonchatLastMsgTime < BonChat.CVAR.GetMsgCooldown() then return end

  local text = string.Left(net.ReadString(), BonChat.CVAR.GetMsgMaxLength())
  local teamChat = net.ReadBool()

  if not IsValid(ply) and teamChat then return end
  
  text = hook.Run("PlayerSay", ply, text, teamChat)
  if #text == 0 then return end

  local totalAttachs = net.ReadUInt(4)
  local attachments = {}
  for i = 1, totalAttachs do
    local type, value = net.ReadUInt(2), net.ReadString()
    table.insert(attachments, { type = type, value = value })
  end

  MsgN("[" .. os.date("%H:%M:%S") .. "] " .. ply:Nick() .. ": " .. text)

  local newData = util.Compress(text)

  net.Start("bonchat_say")
    net.WriteEntity(ply)
    net.WriteString(text)
    net.WriteBool(teamChat)
    net.WriteBool(not ply:Alive())

    net.WriteUInt(totalAttachs, 4)
    for i = 1, totalAttachs do
      local attachment = attachments[i]
      net.WriteUInt(attachment.type, 2)
      net.WriteString(attachment.value)
    end
  if teamChat then
    net.Send(team.GetPlayers(ply:Team()))
  else
    net.Broadcast()
  end
  
  ply.bonchatLastMsgTime = CurTime()
end)

net.Receive("bonchat_istyping", function(_, ply)
  local typing = net.ReadBool()
  ply.bonchatIsTyping = typing

  net.Start("bonchat_istyping")
    net.WriteEntity(ply)
    net.WriteBool(typing)
  net.SendOmit(ply)
end)