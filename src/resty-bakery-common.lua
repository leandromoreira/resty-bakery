local common = {}

common.preconditions = {
  -- a framerate filter only works when there's fps to filter
  framerate=function(_, ctx)
    return ctx.fps and #ctx.fps > 0
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


return common
