local sentMaxAttachLimit

local PANEL = {
  Init = function(self)
    self:SetTitle("Add Attachments")

    self.Paint = function(self, w, h)
      self:DrawBlur(1, 1)
      surface.SetDrawColor(30, 30, 30)
      surface.DrawOutlinedRect(0, 0, w, h, 2)
      surface.DrawRect(0, 0, w, 25)
    end

    self.dhtml = self:Add("BonChat_DHTML")
    self.dhtml:Dock(FILL)

    self.dhtml:AddFunc("playSound", surface.PlaySound)

    self.dhtml:AddFunc("showHoverLabel", BonChat.ShowHoverLabel)
    self.dhtml:AddFunc("hideHoverLabel", BonChat.HideHoverLabel)
    self.dhtml:AddFunc("openPage", BonChat.OpenPage)
    self.dhtml:AddFunc("openImage", BonChat.OpenImage)
    self.dhtml:AddFunc("pasteImage", BonChat.PasteImage)

    self.dhtml:AddFunc("addAttachment", function(str) self:AddAttachment(str) end)
    self.dhtml:AddFunc("removeAttachment", function(id) self:RemoveAttachment(id) end)

    self.dhtml:AddFunc("retryAttachment", function(attachID, src)
      local attachImg = string.format("getAttachmentByID(%d).find('img')", attachID)
      BonChat.LoadAttachment(src, function()
        self.dhtml:CallJS(attachImg .. ".trigger('load')")
      end, function(err)
        self.dhtml:CallJS(attachImg .. ".trigger('error')")
      end)
    end)
    self.dhtml:AddFunc("readyAttachment", function(attachID, str)
      self.attachs[attachID] = { type = BonChat.msgAttachTypes.IMAGE, value = str }
    end)

    self.dhtml:SetHTML(BonChat.GetResource("attachments.html"))

    self.attachs = {}
    self.attachIDNum = 0
  end,
  GetAttachments = function(self)
    local list = {}
    for _, v in pairs(self.attachs) do
      table.insert(list, v)
    end
    return list
  end,
  ClearAttachments = function(self)
    self.attachs = {}
    self.dhtml:CallJS("attachmentContainer.empty()");
    self.attachIDNum = 0
  end,
  AddAttachment = function(self, str)
    local max = BonChat.CVAR.GetMsgMaxAttachs()
    if table.Count(self.attachs) >= max then
      if not sentMaxAttachLimit then
        BonChat.SendInfoMessage("**:i:error: You hit the max attachments limit! (" .. max .. ")**")
        sentMaxAttachLimit = true
      end
      return
    end
    sentMaxAttachLimit = false

    str = string.Trim(str)
    if #str == 0 then return end

    self.dhtml:CallJS("attachmentContainer.find('.failed').remove()") -- cleanup attachments that failed to load
    self.dhtml:CallJSParams("new Attachment(%d, '%s')", self.attachIDNum, str)

    self.attachIDNum = self.attachIDNum + 1
  end,
  RemoveAttachment = function(self, id)
    self.attachs[id] = nil
    self.dhtml:CallJS("attachmentContainer.find('.failed').remove()") -- cleanup attachments that failed to load
    self.dhtml:CallJSParams("getAttachmentByID(%d).remove()", id);
  end
}

vgui.Register("BonChat_Attachments", PANEL, "DFrame")