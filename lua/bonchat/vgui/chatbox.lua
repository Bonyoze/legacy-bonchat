include("bonchat/vgui/dhtml.lua")

local PANEL = {
  Init = function(self)
    self:Dock(FILL)
    self:SetHTML(BonChat.GetResource("chatbox.html"))

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
    self:AddFunc("say", BonChat.Say)
    self:AddFunc("openPage", BonChat.OpenPage)
    self:AddFunc("openImage", BonChat.OpenImage)
    self:AddFunc("setClipboardText", SetClipboardText)
    
    -- create emoji lookup table and send to panel
    local emojiData, emojiLookup = util.JSONToTable(BonChat.GetResource("emoji_data.json")), {}

    for _, v in pairs(emojiData) do
      for i = 1, #v, 2 do
        emojiData[v[i]] = v[i + 1]
      end
    end

    self:CallJS("EMOJI_DATA = JSON.parse('%s')", util.TableToJSON(emojiData))
  end
}

vgui.Register("BonChat_Chatbox", PANEL, "BonChat_DHTML")