local dash = {}

local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"

dash.video_representations_tags = function(manifest)
  local tags = {}

  for w in string.gmatch(manifest, "<Representation[^\n]+") do
    if string.match(w,"video") then
      table.insert(tags, w)
    end
  end

  return tags
end

-- filters based on bandwidth
-- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
dash.bandwidth = function(raw, context)
  if not context.max or not context.min then
    return raw, "no max or min were informed"
  end
  local parser = xml2lua.parser(handler)
  parser:parse(raw)

  for _, as in ipairs(handler.root.MPD.Period.AdaptationSet) do
    if as._attr.contentType == "video" then
      for idx, r in ipairs(as.Representation) do
        local bandwidth_number = tonumber(r._attr.bandwidth)
        if bandwidth_number < context.min or bandwidth_number > context.max then
          as.Representation[idx] = nil
        end
      end
    end
  end


  local modified_mpd = xml2lua.toXml(handler.root, "XmlSSTartLua")

  -- if all renditions were filtered
  -- so we act safe returning the passed manifest
  if #dash.video_representations_tags(modified_mpd) == 0 then
    return raw, nil
  end

  modified_mpd = string.gsub(modified_mpd, "<XmlSSTartLua>", "")
  modified_mpd = string.gsub(modified_mpd, "</XmlSSTartLua>", "")
  modified_mpd = string.gsub(modified_mpd, "\n\n", "")
  modified_mpd = string.gsub(modified_mpd, "\n", "", 1) -- removing the first (TODO: check if there's \n in the beginning)
  modified_mpd = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" .. modified_mpd -- get the first line from original?

  return modified_mpd, nil
end


-- a table containing all dash filters
dash.filters = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  {name="bandwidth", filter=dash.bandwidth},
}

return dash
