local totalResources, resourcesReceived, kbTotal, startTime

-- get total resources that will be sent
net.Receive("bonchat_resources", function()
  totalResources = net.ReadUInt(8)
  resourcesReceived = 0
  kbTotal = 0
  startTime = SysTime()
  BonChat.Log("Fetching resources...")
end)

-- get resource file data
net.Receive("bonchat_resources_data", function()
  local path = net.ReadString()
  local len = net.ReadUInt(16)
  local data = net.ReadData(len)
  BonChat.resources[path] = data

  resourcesReceived = resourcesReceived + 1
  kbTotal = kbTotal + math.Round(len / 1000, 2)
  BonChat.Log("Received " .. resourcesReceived .. "/" .. totalResources .. " files (" .. kbTotal .. " KB)")
end)

-- after all resources are sent
net.Receive("bonchat_resources_ready", function()
  BonChat.resourcesReady = true
  BonChat.Log("All resources received (took " .. math.Round(SysTime() - startTime, 1) .. " secs)")
  BonChat.InitChat()
end)

-- player sent a message through the chatbox
net.Receive("bonchat_say", function()
  local ply = net.ReadEntity()
  local text = net.ReadString()
  local teamChat = net.ReadBool()
  local isDead = net.ReadBool()
  local totalAttachs = net.ReadUInt(4)
  local attachments = {}
  for i = 1, totalAttachs do
    local type, value = net.ReadUInt(2), net.ReadString()
    table.insert(attachments, { type = type, value = value })
  end

  BonChat.lastPlayerChat = { ply = ply, text = text, teamChat = teamChat, isDead = isDead, attachments = attachments }
  hook.Run("OnPlayerChat", ply, text, teamChat, isDead)
  BonChat.lastPlayerChat = {}
end)

-- player is typing in the chatbox
net.Receive("bonchat_istyping", function()
  local ply, typing = net.ReadEntity(), net.ReadBool()
  ply.bonchatIsTyping = typing
end)