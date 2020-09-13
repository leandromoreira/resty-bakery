local hls = require "resty-bakery-hls"
local dash = require "resty-bakery-dash"

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
  local min, max = string.match(sub_uri, "(%d+),?(%d*)")
  local context = {}
  if min then context.min = tonumber(min) end
  if max then context.max = tonumber(max) end
  return context
end

local filters_config = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  bandwidth={match="b%(%d+,?%d*%)", context_args=bandwidth_args},
}


-- filter - filters the body (an hls or dash manifest) given an uri
--  returns a string
--
-- it chains all filters, passing the filtered body to the next filter
bakery.filter = function(uri, body)
  local filters = {}
  if string.match(uri, ".m3u8") then
    filters = hls.filters
  elseif string.match(uri, ".mpd") then
    filters = dash.filters
  end

  for _, v in ipairs(filters) do
    local sub_uri = string.match(uri, filters_config[v.name].match)
    if sub_uri then
      -- we're assuming no error at all
      -- and when an error happens the
      -- filters should return the unmodified body
      local context = bakery.set_default_context(filters_config[v.name].context_args(sub_uri))
      body = v.filter(body, context)
    end
  end

  return body
end

return bakery
