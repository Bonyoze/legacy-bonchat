local PANEL = {
  Init = function(self)
    self.jsStr = ""
  end,
  CallJS = function(self, str) -- call javascript wrapped in a closure
    self:RunJavascript("(function() {" .. str .. "})()")
  end,
  CallJSParams = function(self, str, ...) -- CallJS but accepts string formatting
    self:RunJavascript("(function() {" .. string.format(str, ...) .. "})()")
  end,
  ReadyJS = function(self) -- clears the js string
    self.jsStr = ""
  end,
  AddJS = function(self, str, ...) -- appends js to the string
    str = string.Trim(str)
    if str[#str] ~= ";" then
      str = str .. ";"
    end
    self.jsStr = self.jsStr .. string.format(str, ...)
  end,
  RunJS = function(self) -- executes the string (string doesn't get cleared, must call ReadyJS)
    self:CallJS(self.jsStr)
  end,
  AddFunc = function(self, name, func)
    self:AddFunction("glua", name, func)
  end,
  PreProcess = function(self, str, limit, ...) -- preprocess a string with embedded lua
    limit = limit or 1000
  
    local finds = {}
  
    -- find indicators
    for k, v in ipairs({ "PRELUA:", "POSTLUA:", ":ENDLUA" }) do
      local findPos = 1
      while 1 do
        local currPos = findPos
        local pos1, pos2, find = string.find(str, v, findPos)
        if pos1 then
          table.insert(finds, { pos1 = pos1, pos2 = pos2, type = k })
          findPos = pos2 + 1
        end
        if findPos == currPos then break end
      end
    end
  
    table.sort(finds, function(a, b) return a.pos1 < b.pos1 end) -- order ascending
  
    local executions = {}
  
    -- parse executions
    for k, v in ipairs(finds) do
      if v.type == 3 then continue end

      local next = finds[k + 1]

      local startPos, endPos = v.pos2 + 1
      local outerStartPos, outerEndPos = v.pos1

      if not next or next.type ~= 3 then -- interpret as single-line
        local eol = string.find(str, "\n", startPos)
        if eol then
          endPos = eol - 1
          outerEndPos = eol
        else -- no newline, must be at end of string
          endPos = #str
          outerEndPos = endPos
        end
      else -- interpret as multi-line
        endPos = next.pos1 - 1
        outerEndPos = next.pos2
      end

      table.insert(executions, {
        type = v.type,
        pos1 = outerStartPos,
        pos2 = outerEndPos,
        fn = CompileString("local self = ... local args = {select(2, ...)} " .. string.Trim(string.sub(str, startPos, endPos)))
      })
    end

    local replacements, post = {}, {}
    local preTotal = 0

    -- get replacements
    for _, v in ipairs(executions) do
      preTotal = preTotal + 1
      if preTotal > limit then error("hit preprocess limit") end

      local str = ""

      if v.type == 1 then -- run pre executions
        local childPost, childTotal
        str, childPost, childTotal = self:PreProcess(
          tostring(v.fn(self, ...) or ""),
          limit - preTotal,
          ...
        )
        
        -- add post executions to beginning
        table.Add(childPost, post)
        post = childPost
        -- add total of executions the child preprocess ran
        preTotal = preTotal + childTotal
      else
        table.insert(post, v.fn)
      end

      table.insert(replacements, { pos1 = v.pos1, pos2 = v.pos2, str = str })
    end
  
    -- update string with replacements
    for i = #replacements, 1, -1 do
      local replacement = replacements[i]
      str = string.sub(str, 1, replacement.pos1 - 1) .. replacement.str .. string.sub(str, replacement.pos2 + 1)
    end
  
    return str, post, preTotal
  end,
  PostProcess = function(self, post, ...)
    for _, v in ipairs(post) do
      v(self, ...)
    end
  end,
  SetContent = function(self, str, cb, ...)
    local args = { ... }

    coroutine.wrap(function()
      local html, post = self:PreProcess(str, nil, unpack(args))

      self:SetHTML(html)

      -- wait for DOM content to load then run post executions
      local co = coroutine.running()
      self:AddFunc("_postprocess", function()
        self:PostProcess(post, unpack(args))
        self:CallJS("document.dispatchEvent(new Event('postprocess'))")
        coroutine.resume(co)
      end)
      self:CallJS("document.addEventListener('DOMContentLoaded', function() { glua._postprocess() })")
      
      coroutine.yield()
      
      if (cb) then cb() end
    end)()
  end
}

vgui.Register("BonChat_DHTML", PANEL, "DHTML")