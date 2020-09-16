local hls = {}

local common = require "resty-bakery-common"

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

-- filter_out_hls_with_skip - filters out lines from an hls manifest based on a function
--  returns a table containing information
--    skip - should we skip or not
--    count - how many lines should we skip
--      (this is used mostly for removing the meta and the variation tag)
local filter_out_hls_with_skip = function(lines, ctx, filter_out_fn)
  local filtered_manifest = {}
  local filter_response = {skip=false, count=0}

  for _, line in ipairs(lines) do
    if filter_response.count <= 0 then
      filter_response = filter_out_fn(line, ctx)

      if not filter_response.skip then
        table.insert(filtered_manifest, line)
      end
    end

    filter_response.count = filter_response.count - 1
    if filter_response.count <= 0 then
      filter_response.skip = false
      filter_response.count = 0
    end
  end

  return filtered_manifest
end

-- has_bitrate - checks if the manifest has the bitrate
--  returns a boolean
hls.has_bitrate = function(manifest, bitrate)
  -- maybe we need to do bandwidth and BANDWIDTH
  return string.match(manifest, "BANDWIDTH=" .. bitrate) ~= nil
end

-- video_renditions - returns the tag/metadata information about the renditions for a given manifest
--  returns a table
hls.video_renditions = function(manifest)
  local video = {}
  -- this regex should capture each rendition hls text line
  -- skipping I-FRAME and others
  for w in string.gmatch(manifest, "#EXT%-X%-STREAM%-INF[%w:=,%-\"%.]*") do
    table.insert(video, w)
  end

  return video
end

-- _create_filter_function - builds a filter function based on
--   precondition - a function to validate the context
--   predicate - a function that given a line it decides to skip or not
hls._create_filter_function = function(precondition, predicate)
  return function(raw, ctx)
    if not precondition(raw, ctx) then
      return raw, nil
    end
    local manifest_lines = common.split(raw, "\n")
    local filtered_manifest = filter_out_hls_with_skip(manifest_lines, ctx, predicate)
    local raw_filtered_manifest = table.concat(filtered_manifest,"\n") .. "\n"

    -- all renditions were filtered so we act safe returning the passed manifest
    if #hls.video_renditions(raw_filtered_manifest) == 0 then
      return raw, nil
    end

    return raw_filtered_manifest, nil
  end
end

-- filters based on frame rate
-- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/frame-rate.md
hls.framerate = hls._create_filter_function(
  common.preconditions.framerate,
  -- Filter Out Predicate function
  --  a function that given the current line and the context
  --  it might skip and inform how many lines the filter should skip
  function(current_line, ctx)
    local response = {skip=false,count=0}
    current_line = string.lower(current_line)

    if string.find(current_line, "frame%-rate") then
      -- frame rate according to
      -- https://tools.ietf.org/html/draft-pantos-http-live-streaming-23
      local framerate_text = string.match(current_line, "frame%-rate=(%d+%.?%d*)")

      for _, fps in ipairs(ctx.fps) do
        if fps == framerate_text then
          response.skip = true
          response.count = 2 -- skip the next line (the rendition/variant) as well
          break
        end
      end
    end

    return response
  end
)
-- filters based on bandwidth
-- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
hls.bandwidth = hls._create_filter_function(
  common.preconditions.bandwidth,
  -- Filter Out Predicate function
  --  a function that given the current line and the context
  --  it might skip and inform how many lines the filter should skip
  function(current_line, ctx)
    local response = {skip=false,count=0}
    current_line = string.lower(current_line)

    -- make sure we're dealing only with rendition variant
    if string.find(current_line, "^#ext%-x%-stream%-inf") then
      local bandwidth_text = string.match(current_line, "bandwidth=(%d+)")

      if bandwidth_text then
        local bandwidth_number = tonumber(bandwidth_text)

        if bandwidth_number < ctx.min or bandwidth_number > ctx.max then
          response.skip = true
          skip_count = 2
        end
      end
    end

    return response
  end
)

-- a table containing all hls filters
--
-- do we need to care wether it's a variant or a master?
-- do we care about the order?
hls.filters = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  {name="bandwidth", filter=hls.bandwidth},
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/frame-rate.md
  {name="framerate", filter=hls.framerate},
}

return hls
