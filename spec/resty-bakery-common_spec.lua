package.path = package.path .. ";spec/?.lua"

local common = require "resty-bakery-common"

describe("Filter config", function()
  local config = {
    -- bitrate
    {name="build a config for a minimum bitrate", filter="bandwidth", uri="/a/b(1000)/b/", expected={min=1000}},
    {name="build a config for a min/max bitrate", filter="bandwidth", uri="/a/b(1000,2000)/b/", expected={min=1000,max=2000}},
    {name="build an empty config for an empty bitrate", filter="bandwidth", uri="/a/b()/b/", expected={}},
    {name="build a config for a min/max bitrate with multiple filters", filter="bandwidth", uri="/a/b(1000,2000)fps(60)/b/", expected={min=1000,max=2000}},
    -- framerate
    {name="build a config for a single fps", filter="framerate", uri="/a/fps(30)/b/", expected={fps={"30"}}},
    {name="build a config for a single float fps", filter="framerate", uri="/a/fps(29.970)/b/", expected={fps={"29.970"}}},
    {name="build a config for a single fps in X/Y form", filter="framerate", uri="/a/fps(30000:1001)/b/", expected={fps={"30000/1001"}}},
    {name="build a config for a multi fps", filter="framerate", uri="/a/fps(30,30000:1001,29.970)/b/", expected={fps={"30","30000/1001","29.970"}}},
    {name="build an empty config for an empty fps", filter="framerate", uri="/a/fps()/b/", expected={fps={}}},
    {name="build a config with multiple filters", filter="framerate", uri="/a/fps(30)b(1000)/b/", expected={fps={"30"}}},
  }

  for _, test in ipairs(config) do
    it(test.filter .. " :: " .. test.name, function()
      local sub_uri = string.match(test.uri, common.config[test.filter].match)
      local context = common.config[test.filter].get_args(sub_uri)

      assert.are.same(test.expected, context)
    end)
  end
end)
