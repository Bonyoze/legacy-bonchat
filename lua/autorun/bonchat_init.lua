BonChat = BonChat or {}

BonChat.DIR = "bonchat/"
BonChat.RESOURCE_DIR = BonChat.DIR .. "resources/"

BonChat.DEFAULT_URL_WHITELIST = {
  // Facepunch
  "files.facepunch.com",
  // Dropbox
  "dropbox.com",
  "dl.dropboxusercontent.com",
  // Imgur
  "i.imgur.com",
  // Tenor
  "tenor.com",
  // Discord
  "cdn.discordapp.com",
  "media.discordapp.net",
  // Steam
  "cdn.akamai.steamstatic.com",
  // Youtube
  "youtube.com",
  "youtu.be",
  // Github
  "user-images.githubusercontent.com",
  // Reddit
  "i.redd.it",
  "preview.redd.it",
  // Twitter
  "pbs.twimg.com",
  "video.twimg.com"
}

local plyMeta = FindMetaTable("Player")

BonChat.oldPlyIsTyping = BonChat.oldPlyIsTyping or plyMeta.IsTyping
function plyMeta:IsTyping()
  return BonChat.oldPlyIsTyping(self) or self.bonchatIsTyping
end

if SERVER then
  include("bonchat/base_sv.lua")
  AddCSLuaFile("bonchat/base_cl.lua")
else
  include("bonchat/base_cl.lua")
end