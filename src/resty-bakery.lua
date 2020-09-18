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
    local sub_uri = string.match(uri, common.config[v.name].match)
    if sub_uri then
      -- we're assuming no error at all
      -- and when an error happens the
      -- filters should return the unmodified body
      local context = bakery.set_default_context(common.config[v.name].get_args(sub_uri))
      body = v.filter(body, context)
    end
  end

  return body
end

return bakery
