local dash = {}

local common = require "resty-bakery-common"
local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"

-- has_bitrate - checks if the manifest has the bitrate
--  returns a boolean
dash.has_bitrate = function(manifest, bitrate)
  return string.match(manifest, "bandwidth=\"" .. bitrate ..  "\"") ~= nil
end

-- video_renditions - returns the tag/metadata information about the renditions for a given manifest
--  returns a table
dash.video_renditions = function(manifest)
  local tags = {}

  for w in string.gmatch(manifest, "<Representation[^\n]+") do
    if string.match(w,"video") then
      table.insert(tags, w)
    end
  end

  return tags
end

-- _create_filter_function - builds a filter function based on
--   precondition - a function to validate the context
--   iterator - an adaptation set video iterator for the actuall filtering
dash._create_filter_function = function(precondition, iterator)
  return function(raw, ctx)
    if not precondition(raw, ctx) then
      return raw, "did not meet the context precondition."
    end
    local parser = xml2lua.parser(handler)
    parser:parse(raw)

    for _, as in ipairs(handler.root.MPD.Period.AdaptationSet) do
      if as._attr.contentType == "video" then
        iterator(as, ctx)
      end
    end

    -- we need to attach some root fake node to parse
    -- the table to string
    local modified_mpd = xml2lua.toXml(handler.root, "XmlSSTartLua")

    -- if all renditions were filtered
    -- so we act safe returning the passed manifest
    if #dash.video_renditions(modified_mpd) == 0 then
      return raw, "all renditions would be filtered, some filter(s) hasnt been applied."
    end

  -- we then remove the fake node required to transform
  modified_mpd = string.gsub(modified_mpd, "<XmlSSTartLua>", "")
  modified_mpd = string.gsub(modified_mpd, "</XmlSSTartLua>", "")
  -- the way the lib transforms table to string xml adds double new lines
  -- we remove them
  modified_mpd = string.gsub(modified_mpd, "\n\n", "")
  -- becase we remove the fake node we also introduced an unecessary new line
  modified_mpd = string.gsub(modified_mpd, "\n", "", 1) -- removing the first (TODO: check if there's \n in the beginning)
  -- the toXml also don't carry the <?xml> tag, then we prepend it
  modified_mpd = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" .. modified_mpd -- TODO: get the first line from original?

    return modified_mpd, nil
  end
end

-- filters based on frame rate
-- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/frame-rate.md
dash.framerate = dash._create_filter_function(
  common.preconditions.framerate,
  -- a function that receives all the video adaptation set and the context
  -- so one can remove the unecessary nodes
  function(as, ctx)
    for idx, r in ipairs(as.Representation) do
      for _, fps in ipairs(ctx.fps) do
        if fps == r._attr.frameRate then
          as.Representation[idx] = nil
          break
        end
      end
    end
  end
)

-- filters based on bandwidth
-- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
dash.bandwidth = dash._create_filter_function(
  common.preconditions.bandwidth,
  -- a function that receives all the video adaptation set and the context
  -- so one can remove the unecessary nodes
  function(as, ctx)
    for idx, r in ipairs(as.Representation) do
      local bandwidth_number = tonumber(r._attr.bandwidth)
      if bandwidth_number < ctx.min or bandwidth_number > ctx.max then
        as.Representation[idx] = nil
      end
    end
  end
)

-- a table containing all dash filters
dash.filters = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  {name="bandwidth", filter=dash.bandwidth},
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/frame-rate.md
  {name="framerate", filter=dash.framerate},
}

return dash
