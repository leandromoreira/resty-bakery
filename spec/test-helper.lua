local helper = {}

helper.content_from = function(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*a")
  f:close()
  return content
end


return helper
