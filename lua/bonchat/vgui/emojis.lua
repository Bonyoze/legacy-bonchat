local steamActiveReqs, steamQueryCache, steamQueryTotals = 0, {}, {}
local steamReqCooldown, steamMaxReqs = 60, 10

local function parsePage(data, total, page)
  data = data or {}
  total = total or table.Count(data)
  page = page or 1

  local result = {}
  for i = (page - 1) * 100 + 1, page * 100 do -- take 100 items from the data
    if i > total then break end
    table.insert(result, data[i] or "")
  end

  return result
end

local PANEL = {
  Init = function(self)
    self:SetTitle("Emojis")

    self.Paint = function(self, w, h)
      self:DrawBlur(1, 1)
      surface.SetDrawColor(30, 30, 30)
      surface.DrawOutlinedRect(0, 0, w, h, 2)
      surface.DrawRect(0, 0, w, 25)
    end

    self.dhtml = self:Add("BonChat_DHTML")
    self.dhtml:Dock(FILL)

    self.dhtml:AddFunc("playSound", surface.PlaySound)
    --self.dhtml:AddFunc("setClipboardText", SetClipboardText)

    self.dhtml:AddFunc("showHoverLabel", BonChat.ShowHoverLabel)
    self.dhtml:AddFunc("hideHoverLabel", BonChat.HideHoverLabel)
    self.dhtml:AddFunc("insertText", BonChat.InsertText)

    self.dhtml:AddFunc("searchEmojis", function(query) self:SearchEmojis(query) end)
    self.dhtml:AddFunc("loadPage", function(id) self:LoadPage(id) end)

    self.dhtml:SetHTML(BonChat.GetResource("emojis.html"))

    self.categories = {}

    -- default (twemoji)
    do
      local emojiData = util.JSONToTable(BonChat.GetResource("emoji_data.json"))

      local function addDefaultCategory(name)
        return self:AddCategory(name, nil, "twemoji")
      end

      local categories = {
        { "People", emojiData.people },
        { "Nature", emojiData.nature} ,
        { "Food", emojiData.food },
        { "Activities", emojiData.activities },
        { "Travel", emojiData.travel },
        { "Objects", emojiData.objects },
        { "Symbols", emojiData.symbols },
        { "Flags", emojiData.flags }
      }

      for _, category in ipairs(categories) do
        local title, data = category[1], category[2]

        local names = {}
        for i = 1, #data, 2 do
          table.insert(names, data[i])
        end
        
        local lastQuery, queryResult
        local obj = addDefaultCategory(title)

        function obj:QuerySearch(query, page, callback)
          query = string.lower(query)
  
          -- search for emojis
          if query ~= lastQuery then
            queryResult = {}

            local seen, showTones = {}, BonChat.CVAR.GetShowToneEmojis()
            for k, v in ipairs(names) do
              if not showTones and string.match(v, "_tone%d?") then continue end
              if #query == 0 or string.find(v, query, 1, true) then -- include if query was empty or the name matches
                local surrogates = data[k * 2]
                local found = seen[surrogates]
                if not found then
                  seen[surrogates] = table.insert(queryResult, { v, surrogates })
                elseif #v < #queryResult[found][2] then
                  queryResult[found] = { v, surrogates }
                end
              end
            end
  
            lastQuery = query
            self:SetTitle(title .. " (" .. #queryResult ..  " results)")
          end
  
          callback(parsePage(queryResult, nil, page))
        end
      end
    end

    -- silkicon
    do
      local data, names = file.Find("materials/icon16/*.png", "MOD"), {}
      for k, v in ipairs(data) do
        table.insert(names, string.match(v, "(.-)%.png"))
      end

      local lastQuery, queryResult
      local silkicons = self:AddCategory("silkicon", "i")
      
      function silkicons:QuerySearch(query, page, callback)
        query = string.lower(query)

        -- search for emojis
        if query ~= lastQuery then
          queryResult = {}

          for _, v in ipairs(names) do
            if #query == 0 or string.find(v, query, 1, true) then -- include if query was empty or the name matches
              table.insert(queryResult, v)
            end
          end

          lastQuery = query
          self:SetTitle("Silkicon (" .. #queryResult ..  " results)")
        end

        callback(parsePage(queryResult, nil, page))
      end
    end

    -- steam
    do
      local steam = self:AddCategory("steam", "s")
      local baseUrl = "https://steamcommunity.com/market/search/render?norender=1&category_753_Game[]=any&category_753_item_class[]=tag_item_class_4&appid=753&sort_column=name&sort_dir=asc&count=100"

      local function httpUrlEncode(data)
        local ndata = string.gsub(data, "[^%w _~%.%-]", function(str)
          local nstr = string.format("%X", string.byte(str))
          return "%" .. (string.len(nstr) == 1 and "0" or "") .. nstr
        end)
        return string.gsub(ndata, " ", "+")
      end

      local function logFetchError(reason)
        BonChat.LogError("Failed to load Steam emojis", reason)
      end

      function steam:QuerySearch(query, page, callback)
        query = string.lower(query)

        coroutine.wrap(function()
          local co = coroutine.running()

          -- wait until we can do more requests
          while steamActiveReqs >= steamMaxReqs do
            timer.Simple(1, function() coroutine.resume(co) end)
            coroutine.yield()
          end
          
          local resultUpdated = false

          -- if data for the query doesn't exist or the page for the query doesn't exist
          if not steamQueryCache[query] or not steamQueryCache[query][page] then
            if not steamQueryCache[query] then -- setup for new query data
              steamQueryCache[query] = {}
              self:SetTitle("Steam")
            end

            local result, total, successful = {}, 0, false
            local url = baseUrl .. "&start=" .. httpUrlEncode((page - 1) * 100) .. "&query=" .. httpUrlEncode(query)

            http.Fetch(url, function(body, len, headers, code)
              local response = util.JSONToTable(body)
              if code == 200 then
                if response.success then
                  for i = 1, #response.results do
                    result[i] = string.match(response.results[i].name, ":(.-):")
                  end
                  total = response.total_count
                  successful = true
                else
                  logFetchError("Request was unsuccessful")
                end
              else
                if code == 429 then
                  logFetchError("Too many requests (wait a bit before retrying)")
                else
                  logFetchError(code)
                end
              end
              coroutine.resume(co)
            end, function(fail)
              logFetchError(fail)
              coroutine.resume(co)
            end)

            coroutine.yield() -- wait for http fetch to finish
            
            timer.Simple(steamReqCooldown, function() -- clear request slot after a minute
              steamActiveReqs = steamActiveReqs - 1
            end)
            steamActiveReqs = steamActiveReqs + 1

            if successful then
              steamQueryCache[query][page] = result -- update cached page result
              steamQueryTotals[query] = total
            end
          end

          self:SetTitle("Steam (" .. steamQueryTotals[query] ..  " results)")

          local pageData, queryResult = {}, steamQueryCache[query][page]
          for i = 1, #queryResult do
            pageData[i] = queryResult[i] or ""
          end

          callback(pageData)
        end)()
      end
    end
  end,
  AddCategory = function(self, id, source, parser)
    id = string.lower(id)

    local dhtml = self.dhtml

    local objCategory = {}
    objCategory.__index = objCategory
    objCategory.__tostring = function(self) return "BonChat Emoji Category '" .. self.id .. "'" end

    objCategory.pageNum = 0
    objCategory.lastSearch = CurTime()

    function objCategory.SetTitle(self, title)
      dhtml:CallJSParams("getCategoryByID('%s').setTitle('%s')", string.JavascriptSafe(self.id), string.JavascriptSafe(title))
    end

    function objCategory.AppendPage(self, data, last)
      dhtml:CallJSParams("getCategoryByID('%s').appendPage(JSON.parse('%s'), %d)", string.JavascriptSafe(self.id), string.JavascriptSafe(util.TableToJSON(data)), last and 1 or 0)
      self.pageNum = self.pageNum + 1
    end

    function objCategory.ClearPages(self)
      dhtml:CallJSParams("getCategoryByID('%s').clearPages()", string.JavascriptSafe(self.id))
    end

    function objCategory.QuerySearch()
    end

    function objCategory.LoadPage(self, clear)
      if not self.lastQuery then return end

      -- append loading label
      dhtml:CallJSParams("getCategoryByID('%s').appendLoadBtn(LOADING_LABEL_TEXT, 1).show()", self.id)
      
      local currSearch = self.lastSearch

      -- start search
      self:QuerySearch(string.gsub(self.lastQuery, "[%s:]", ""), self.pageNum + 1, function(result)
        if self.lastSearch ~= currSearch then return end
        if clear then self:ClearPages() end
        self:AppendPage(result, #result < 100)
      end)
    end

    -- add category
    dhtml:CallJSParams("new Category('%s', '%s', '%s')", string.JavascriptSafe(id), source and string.JavascriptSafe(source) or "", parser and string.JavascriptSafe(parser) or "")

    local obj = setmetatable({ id = id }, objCategory)

    self.categories[id] = obj

    return obj
  end,
  SearchEmojis = function(self, query)
    query = query or ""
    for k, v in pairs(self.categories) do
      v.lastQuery = query
      v.pageNum = 0
      v.lastSearch = CurTime()
      v:ClearPages()
      v:LoadPage(true)
    end
  end,
  LoadPage = function(self, id)
    local category = self.categories[string.lower(id)]
    if not category then return end
    category:LoadPage()
  end
}

vgui.Register("BonChat_Emojis", PANEL, "DFrame")