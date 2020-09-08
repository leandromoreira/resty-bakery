local bakery = {}

bakery.split = function(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

-- A filter is a function that filters a media manifest
-- it receives the raw manifest, a context, and it returns the raw modified manifest and a possible error
-- The context has the fields
--   min - minimum inclusive bitrate (default to the higher available number)
--   max - maximum inclusive bitrate (default to zero)

--
-- HLS
--

bakery.hls = {}
bakery.hls.filters = {
  {name="bandwidth", order=0},
}

bakery.set_default_context = function(context)
  if not context.max then context.max = math.huge end
  if not context.min then context.min = 0 end

  return context
end

-- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
bakery.hls.bandwidth = function(raw, context)
  context = bakery.set_default_context(context)
  local filtered_manifest = {}
  local manifest_lines = bakery.split(raw, "\n")
  local filtered = false
  local skip_count = 0

  for _, v in ipairs(manifest_lines) do
    local current_line = string.lower(v)

    if string.find(current_line, "bandwidth") then
      local bandwidth_text = string.match(current_line, "bandwidth=(%d+),")

      if bandwidth_text then
        local bandwidth_number = tonumber(bandwidth_text)

        if bandwidth_number < context.min or bandwidth_number > context.max then
          filtered = true
          skip_count = 2
        end
      end
    end

    if not filtered then
      table.insert(filtered_manifest, v)
    end

    skip_count = skip_count - 1
    if skip_count <= 0 then
      skip_count = 0
      filtered = false
    end
  end

  -- all renditions were filtered
  -- so we act safe returning the passed manifest
  if #filtered_manifest <= 3 then
    return raw, nil
  end

  local raw_filtered_manifest = table.concat(filtered_manifest,"\n") .. "\n"
  return raw_filtered_manifest, nil
end

return bakery
