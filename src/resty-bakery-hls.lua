local hls = {}

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
hls.bandwidth = function(raw, context)
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


-- a table containing all hls filters
--
-- do we need to care wether it's a variant or a master?
-- do we care about the order?
hls.filters = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  {name="bandwidth", filter=hls.bandwidth},
}

return hls
