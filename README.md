# gmod-bonchat
#### (WIP) A chatbox for Garry's Mod with markdown support, emoji support, ability to show images/videos, and some other stuff
Should work on any branch, but intended for usage on `x86-64` [Read this](https://github.com/Bonyoze/gmod-bonchat/issues/1)

![](https://user-images.githubusercontent.com/59924045/169673128-443d5b49-9913-499d-a5bf-3fdb157df680.png "Showcase of markdown support and emoji catalog")

### Custom event messages:

![](https://user-images.githubusercontent.com/59924045/164572492-b4132cf9-31b7-4132-9ac2-0aa88af5090b.png "Custom event message examples")

### Emoji searching:

![](https://user-images.githubusercontent.com/59924045/169673135-03259537-84a4-4ba0-a42e-7e3936c3994e.png "Results for searching 'face'")

---

### How to Install:

~~You can subscribe to the addon on the Garry's Mod Steam workshop~~ (will be available after the addon is released)

OR

1. Download the zip and place it in your addons folder `Steam\steamapps\common\GarrysMod\garrysmod\addons`
2. Extract the zip in the folder and make sure the addon's lua path is `addons\gmod-bonchat\lua`
3. **RECOMMENDED** Make sure you are on the x86-64 branch of Garry's Mod (you can change this by right clicking the game in your library, going to `Properties...` -> `BETAS` -> select `x86-64 - Chromium + 64-bit binaries`)
4. **OPTIONAL** Install the [GModCEFCodecFix](https://github.com/solsticegamestudios/GModCEFCodecFix) in order for things like videos to work (a guide can be found in the repository's README) (you should only have to install the codecs once and whenever GMod has an update, you change branches or verify integrity of game files)

---

### To Do:
`✅Finished` `➖Working on` `❌Not started`
- ➖ derma panels
  - ✅ frame
  - ✅ chatbox
  - ✅ browser
  - ➖ settings panel
    - ➖ url whitelist editing
    - ✅ hiding attachments
    - ❌ hiding duplicate message (antispam)
  - ✅ emojis panel
    - ✅ emoji searching
    - ✅ Twemoji
    - ✅ Silkicon
    - ✅ Steam
  - ➖ attachments panel
    - ✅ attachments
    - ❌ game asset attachments
  - ❌ chat room panel
    - ❌ room creating/joining/leaving
    - ❌ room private messaging
  - ❌ context popup
    - ❌ message context
    - ❌ attachment context
    - ❌ link context
    - ❌ emoji context
- ➖ message sending
  - ✅ inline markdown support
  - ✅ emoji support
    - ✅ Twemoji
    - ✅ Silkicon
    - ✅ Steam
    - ✅ Discord
  - ➖ attachments
    - ➖ embed
    - ✅ image
    - ➖ video
    - ➖ audio
  - ❌ game asset attachments
    - ❌ model
    - ❌ texture
    - ❌ sound

---

### Sending A Custom Message in GLua:

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

#### Output:

![](https://user-images.githubusercontent.com/59924045/164576612-83366b09-875f-4f06-b2b9-64f7f73025df.png "Output message")

👉 See the [wiki](https://github.com/Bonyoze/gmod-bonchat/wiki) for more information

---

### Acknowledgements
- [Khan/simple-markdown](https://github.com/Khan/simple-markdown) *(code for parsing markdown to HTML)*
- [amethyst-studio/discord-emoji](https://github.com/amethyst-studio/discord_emoji) *(emoji shortcode data)*
- [twitter/twemoji](https://github.com/twitter/twemoji) *(code for parsing twemojis)*
- [Twemoji](https://twemoji.twitter.com) *(emoji api)*
- [Steam](https://store.steampowered.com) *(emoji api)*
- [Discord](https://discord.com) *(emoji api)*
- [Imgur](https://imgur.com) *(api for image pasting functionality)*
