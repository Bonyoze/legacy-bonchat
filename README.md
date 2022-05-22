# gmod-bonchat
#### (WIP) A chatbox for Garry's Mod with markdown support, emoji support, ability to show images/videos, and some other stuff
Should work on any branch, but intended for usage on `x86-64`

![](https://user-images.githubusercontent.com/59924045/169673128-443d5b49-9913-499d-a5bf-3fdb157df680.png "Showcase of markdown support and emoji catalog")

### Custom event messages:

![](https://user-images.githubusercontent.com/59924045/164572492-b4132cf9-31b7-4132-9ac2-0aa88af5090b.png "Custom event message examples")

### Emoji searching:

![](https://user-images.githubusercontent.com/59924045/169673135-03259537-84a4-4ba0-a42e-7e3936c3994e.png "Results for searching 'face'")

---

### To Do:
`✅Finished` `➖Started on` `❌Not started`
- ➖ derma panels
  - ✅ frame
  - ✅ chatbox
  - ✅ browser
  - ➖ settings
    - ➖ URL whitelist editing
    - ❌ max message render height
    - ❌ hiding images/videos
    - ❌ hiding duplicate message (antispam)
  - ✅ emoji catalog
  - ❌ message context popup
- ➖ message sending
  - ✅ inline markdown support
  - ✅ emoji support
    - ✅ Twemoji
    - ✅ Silkicon
    - ✅ Steam
    - ✅ Discord
  - ➖ attachment embedding
    - ✅ images
    - ➖ videos
    - ➖ audio
    - ❌ links
  - ❌ game attachments (some might not be implemented due to complexity)
    - ❌ model
    - ❌ texture
    - ❌ sound file
  - ❌ chatbox input markdown

---

### Sending A Message:

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
