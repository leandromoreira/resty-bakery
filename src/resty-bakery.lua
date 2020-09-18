local hls = require "resty-bakery-hls"
local dash = require "resty-bakery-dash"
local common = require "resty-bakery-common"

local bakery = {}

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

  for _, filter in ipairs(filters) do
    local sub_uri = string.match(uri, common.config[filter.name].match)
    if sub_uri then
      -- we're assuming no error at all
      -- and when an error happens the
      -- filters should return the unmodified body
      local context = common.config[filter.name].get_args(sub_uri)
      body = filter.filter(body, context)
    end
  end

  return body
end

return bakery
