local hls = require "resty-bakery-hls"
local dash = require "resty-bakery-dash"
local common = require "resty-bakery-common"

local bakery = {}

-- set_default_context sets the default parameters
--  returns a key/value table
--
--   min - minimum inclusive bitrate (default to the higher available number)
--   max - maximum inclusive bitrate (default to zero)
bakery.set_default_context = function(context)
  if not context.max then context.max = math.huge end
  if not context.min then context.min = 0 end

  return context
end

local bandwidth_args= function(sub_uri)
  local context = {}
  if not sub_uri then
    return context
  end
  local min, max = string.match(sub_uri, "(%d+),?(%d*)")
  if min then context.min = tonumber(min) end
  if max then context.max = tonumber(max) end
  return context
end

local framerate_args= function(sub_uri)
  local context = {fps={}}
  if sub_uri == nil then
    return context
  end
  local framerates = common.split(sub_uri, ",")

  for _, fps in ipairs(framerates) do
    -- we transfor uri X:Y (uri compatible) to X/Y (dash compatible)
    fps, _ = string.gsub(fps, ":", "/")
    table.insert(context.fps, fps)
  end

  return context
end

bakery.filters_config = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  bandwidth={match="b%(%d+,?%d*%)", context_args=bandwidth_args},
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/frame-rate.md
  framerate={match="fps%(([%d.:,]+)%)", context_args=framerate_args},
}

bakery.filters_by = function(uri)
  if string.match(uri, ".m3u8") then
    return hls.filters
  elseif string.match(uri, ".mpd") then
    return dash.filters
  end
  return {}
end


-- filter - filters the body (an hls or dash manifest) given an uri
--  returns a string
--
-- it chains all filters, passing the filtered body to the next filter
bakery.filter = function(uri, body)
  local filters = bakery.filters_by(uri)

  for _, v in ipairs(filters) do
    local sub_uri = string.match(uri, bakery.filters_config[v.name].match)
    if sub_uri then
      -- we're assuming no error at all
      -- and when an error happens the
      -- filters should return the unmodified body
      local context = bakery.set_default_context(bakery.filters_config[v.name].context_args(sub_uri))
      body = v.filter(body, context)
    end
  end

  return body
end

return bakery
