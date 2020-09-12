local bakery = {}

-- split - splits a string by a separator
--  returns a table
local split = function(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

bakery.hls = {}

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

-- filter_out_hls - filters out lines from an hls manifest based on a function
--  returns a table
local filter_out_hls = function(lines, filter_out_fn)
  local filtered_manifest = {}

  for _, line in ipairs(lines) do
    if not filter_out_fn(line) then
      table.insert(filtered_manifest, line)
    end
  end

  return filtered_manifest
end

-- filters based on bandwidth
-- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
bakery.hls.bandwidth = function(raw, context)
  if not context.max or not context.min then
    return raw, "no max or min were informed"
  end

  local manifest_lines = split(raw, "\n")
  local filter_out = false
  local skip_count = 0

  local filtered_manifest = filter_out_hls(manifest_lines, function(current_line)
    current_line = string.lower(current_line)

    -- we keep a skip counter so we can skip the bandwidth and its variant (rendition)
    skip_count = skip_count - 1
    if skip_count <= 0 then
      skip_count = 0
      filter_out = false
    end

    if string.find(current_line, "bandwidth") then
      local bandwidth_text = string.match(current_line, "bandwidth=(%d+),")

      if bandwidth_text then
        local bandwidth_number = tonumber(bandwidth_text)

        if bandwidth_number < context.min or bandwidth_number > context.max then
          filter_out = true
          skip_count = 2
        end
      end
    end


    return filter_out
  end)

  -- all renditions were filtered
  -- so we act safe returning the passed manifest
  if #filtered_manifest <= 3 then
    return raw, nil
  end

  local raw_filtered_manifest = table.concat(filtered_manifest,"\n") .. "\n"
  return raw_filtered_manifest, nil
end


-- filter - filters the body (an hls or dash manifest) given an uri
--  returns a string
--
-- it chains all filters, passing the filtered body to the next filter
bakery.filter = function(uri, body)
  local filters = {}
  if string.match(uri, ".m3u8") then
    filters = bakery.hls.filters
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

-- hls_bandwidth_args - given a sub uri (the respective part for bandwidth b(x,y)) it returns the context
--  returns key/value tabel
local hls_bandwidth_args = function(sub_uri)
  local min, max = string.match(sub_uri, "(%d+),?(%d*)")
  local context = {}
  if min then context.min = tonumber(min) end
  if max then context.max = tonumber(max) end
  return context
end

-- a table containing all hls filters
--
-- do we need to care wether it's a variant or a master?
-- do we care about the order?
bakery.hls.filters = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  {name="bandwidth", filter=bakery.hls.bandwidth, match="b%(%d+,?%d*%)", context_args=hls_bandwidth_args},
}

return bakery
