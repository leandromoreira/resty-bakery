local common = {}

common.preconditions = {
  -- a framerate filter only works when there's fps to filter
  framerate=function(_, ctx)
    return ctx.fps and #ctx.fps > 0
  end,
  -- min and max must be present
  bandwidth=function(_, ctx)
    return ctx.max and ctx.min
  end,
}

-- split - splits a string by a separator
--  returns a table
common.split = function(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
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

common.config = {
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
  bandwidth={match="b%(%d+,?%d*%)", get_args=bandwidth_args},
  -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/frame-rate.md
  framerate={match="fps%(([%d.:,]+)%)", get_args=framerate_args},
}

return common
