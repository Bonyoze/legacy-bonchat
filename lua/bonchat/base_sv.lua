-- shared scripts
AddCSLuaFile("bonchat/convars.lua")

-- client scripts
AddCSLuaFile(BonChat.DIR .. "message.lua")
AddCSLuaFile(BonChat.DIR .. "custom_chat.lua")
AddCSLuaFile(BonChat.DIR .. "net_cl.lua")

-- vgui panels
AddCSLuaFile(BonChat.DIR .. "vgui/dhtml.lua")
AddCSLuaFile(BonChat.DIR .. "vgui/browser.lua")
AddCSLuaFile(BonChat.DIR .. "vgui/chatbox.lua")
AddCSLuaFile(BonChat.DIR .. "vgui/settings.lua")
AddCSLuaFile(BonChat.DIR .. "vgui/emojis.lua")
AddCSLuaFile(BonChat.DIR .. "vgui/attachments.lua")
AddCSLuaFile(BonChat.DIR .. "vgui/frame.lua")

include(BonChat.DIR .. "convars.lua")
include(BonChat.DIR .. "custom_chat.lua")
include(BonChat.DIR .. "net_sv.lua")

function BonChat.GetResourcePaths(dir)
  dir = dir or ""
  local tbl = {}

  local files, dirs = file.Find(BonChat.RESOURCE_DIR .. dir .. "*", "LUA")

  for _, v in ipairs(files) do
    local name = string.StartWith(dir, "bonchat/") and string.gsub(v, "%.lua$", "") or v -- workshop doesn't allow addons to package files with .html, .js, .css, etc. so .lua is appended to the end
    table.insert(tbl, dir .. name)
  end

  for _, v in ipairs(dirs) do
    table.Add(tbl, BonChat.GetResourcePaths(dir .. v .. "/"))
  end

  return tbl
end

BonChat.resourcePaths = BonChat.GetResourcePaths()