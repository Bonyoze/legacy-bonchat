# gmod-bonchat
#### A chatbox for Garry's Mod with markdown support, emoji support, ability to show images/videos, and some other stuff (WIP)

![](https://user-images.githubusercontent.com/59924045/164146558-dd6eb913-d43e-4692-b10e-e16ee80a10ba.png "BonChat feature showcase")
![](https://user-images.githubusercontent.com/59924045/164572492-b4132cf9-31b7-4132-9ac2-0aa88af5090b.png "Custom message examples")

*Should work on any branch, but intended for usage on `x86-64`*

---

### To Do:
`✅Finished` `➖Started on` `❌Not started`
- ➖ derma panels
  - ✅ frame
  - ✅ chatbox
  - ✅ browser
  - ➖ settings
    - ❌ URL whitelist editing
    - ❌ max message render height
    - ❌ hiding images/videos
    - ❌ hiding duplicate message (antispam)
  - ❌ emoji catalog
  - ❌ message context popup
- ➖ message sending
  - ✅ inline markdown support
  - ✅ emoji support
    - ✅ Twemoji
    - ✅ Steam
    - ✅ Discord
    - ❓ Twitch (might not be implemented)
  - ➖ attachment embedding
    - ✅ images
    - ➖ videos
    - ➖ audio
    - ❌ links
  - ❌ chatbox input markdown
- ➖ api stuff

---

### For Developers

# ConVars/ConCommands

|Realm|Name|Description
|-|-|-
|SERVER|bonchat_msg_max_len|Message character limit when sent from the chatbox
|SERVER|bonchat_msg_cooldown|Message send cooldown in seconds
|CLIENT|bonchat_enable|Enable (1) or disable (0) BonChat
|CLIENT|bonchat_reload|Reloads the chatbox
|CLIENT|bonchat_clear|Empties the chatbox of any messages

### Functions

|Function|Description
|-|-
|`BonChat.GetEnabled()`|Returns bool if BonChat is enabled
|`BonChat.GetMsgMaxLen()`|Returns the max message length on the server
|`BonChat.GetMsgCooldown()`|Returns the message cooldown on the server
|`BonChat.OpenChat(number mode)`|Equivalent to **chat.Open()**
|`BonChat.CloseChat()`|Equivalent to **chat.Close()**
|`BonChat.EnableChat()`|Enables the chatbox panel<br>*(used by `bonchat_enable`)*
|`BonChat.DisableChat()`|Disables the chatbox panel<br>*(used by `bonchat_enable`)*
|`BonChat.ReloadChat()`|Reloads the chatbox panel<br>*(used by `bonchat_reload`)*
|`BonChat.ClearChat()`|Empties the chatbox of any messages<br>*(used by `bonchat_clear`)*
|`BonChat.Say(string text [, number mode] )`|Sends a chat message<br>*(equivalent to `say` or `say_team` but uses the value of `bonchat_msg_max_len`)*
|`BonChat.OpenURL(string url)`|Tries to open a url<br>*(essentially equivalent to `gui.OpenURL()`)*
|`BonChat.OpenPage(string url)`|Opens a url in the BonChat browser panel
|`BonChat.OpenImage(string url, number w, number h, number minW, number minH)`|Opens an image in the BonChat browser panel
|`BonChat.Message()`|Returns a Message object
|`BonChat.SendMessage(Message msg)`|Sends a message to the chatbox
|`BonChat.SendDefaultMsg(Message msg)`|Sends a message to the default chatbox<br>*(Note: may not look correct with `MARKDOWN` or `PLAYER` type)*
|`BonChat.SuppressDefaultMsg()`|Makes it so the next time `chat.AddText()` is called later that tick, the message won't be sent to the BonChat chatbox

## Message Methods

|Method|Description
|-|-
|`Message:SetPlayer(Player ply)`|Sets the player that the message is sent by
|`Message:SetOptions(string...)`|Set options in the message
|`Message:SetCentered()`|Makes the message appear horizontally centered
|`Message:SetUnselectable()`|Makes the message unable to be highlighted
|`Message:SetUntouchable()`|Makes any mouse interactions on the message non-functional
|`Message:ShowTimestamp()`|Adds a timestamp to the beginning of the message
|`Message:RemoveOptions(string...)`|Unsets options in the message
|`Message:GetArgs()`|Returns a table of arguments in the message
|`Message:GetOptions()`|Returns a table of options in the message
|`Message:GetPlayer()`|Returns the set player for the message
|`Message:AppendText(string str)`|Adds text to the message
|`Message:AppendColor(Color clr)`|Sets the color of following text in the message
|`Message:AppendEntity(entity ent)`|Adds any entity to the message<br>*(for null entities, just "NULL" will be added)*<br>*(for players, the name in their team color will be added)*<br>*(for other entities, just the class name will be added)*
|`Message:AppendType(any value)`|Attempts to add the value as text, a color, or an entity
|`Message:AppendMarkdown(string str)`|Adds text with markdown support
|`Message:AppendPlayer(string name [, Color clr] [, string steamID] )`|Adds text that gets parsed in the style of a player entity
|`Message:AppendArgs(any...)`|Equivalent to AppendType but multiple arguments are allowed

|Argument Type Enums|Info
|-|-
|TEXT|
|COLOR|
|ENTITY|
|MARKDOWN|Text but with markdown support
|PLAYER|Mimics the styling for a player, but the name, color, and steam id can be specified

|Option Enums|Info
|-|-
|CENTER_CONTENT|Horizontally center text content
|CENTER_ATTACH|Horizontally center attachments
|NO_SELECT_CONTENT|Make text content not able to be highlighted
|NO_SELECT_ATTACH|Make attachments not able to be highlighted
|NO_TOUCH_CONTENT|Prevent mouse interaction on text content
|NO_TOUCH_ATTACH|Prevent mouse interaction on attachments
|SHOW_TIMESTAMP|Add a timestamp to the start of the text content


Sending a message in BonChat:

```lua
local msg = BonChat.Message()
  msg:ShowTimestamp()
  msg:AppendEntity(LocalPlayer())
  msg:AppendText(": **some text** ")
  msg:AppendColor(color_white)
  msg:AppendEntity(game.GetWorld())
  msg:AppendMarkdown(" **some text** ")
  msg:AppendPlayer("Fake Player", Color(0, 255, 0))
BonChat.SendMessage(msg)
```

Output:

![](https://user-images.githubusercontent.com/59924045/164576612-83366b09-875f-4f06-b2b9-64f7f73025df.png "Output message")

---

### Acknowledgements
- [Khan/simple-markdown](https://github.com/Khan/simple-markdown) *(code for parsing markdown to HTML)*
- [amethyst-studio/discord-emoji](https://github.com/amethyst-studio/discord_emoji) *(emoji shortcode data)*
- [twitter/twemoji](https://github.com/twitter/twemoji) *(code for parsing twemojis)*
- [Twemoji](https://twemoji.twitter.com) *(emoji api)*
- [Steam](https://store.steampowered.com) *(emoji api)*
- [Discord](https://discord.com) *(emoji api)*
