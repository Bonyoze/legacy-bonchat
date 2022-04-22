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

Output:

![](https://user-images.githubusercontent.com/59924045/164576612-83366b09-875f-4f06-b2b9-64f7f73025df.png "Output message")

See the [wiki](https://github.com/Bonyoze/gmod-bonchat/wiki) for more information

---

### Acknowledgements
- [Khan/simple-markdown](https://github.com/Khan/simple-markdown) *(code for parsing markdown to HTML)*
- [amethyst-studio/discord-emoji](https://github.com/amethyst-studio/discord_emoji) *(emoji shortcode data)*
- [twitter/twemoji](https://github.com/twitter/twemoji) *(code for parsing twemojis)*
- [Twemoji](https://twemoji.twitter.com) *(emoji api)*
- [Steam](https://store.steampowered.com) *(emoji api)*
- [Discord](https://discord.com) *(emoji api)*
