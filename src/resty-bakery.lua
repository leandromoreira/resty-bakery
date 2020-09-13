local hls = require "resty-bakery-hls"

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


-- filter - filters the body (an hls or dash manifest) given an uri
--  returns a string
--
-- it chains all filters, passing the filtered body to the next filter
bakery.filter = function(uri, body)
  local filters = {}
  if string.match(uri, ".m3u8") then
    filters = hls.filters
  end
  -- TOOD mpd

  for _, v in ipairs(filters) do
    local sub_uri = string.match(uri, v.match)
    if sub_uri then
      -- we're assuming no error at all
      -- and when an error happens the
      -- filters should return the unmodified body
      body = v.filter(body, bakery.set_default_context(v.context_args(sub_uri)))
    end
  end

  return body
end

return bakery
