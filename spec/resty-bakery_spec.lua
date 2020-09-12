package.path = package.path .. ";spec/?.lua"

local bakery = require "resty-bakery"

local content_from = function(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*a")
  f:close()
  return content
end

-- add tests over variant shouldn't change
local ffmpeg_master = content_from("spec/manifests/ffmpeg_master.m3u8")

local bandwidth_tests = {
  {
    name="defines a minimum bitrate from FFmpeg", filter=bakery.hls.bandwidth, manifest=ffmpeg_master, context={min=1500000, max=math.huge},
    check=function(modified_manifest)
      local rendition_count = 0
      for w in string.gmatch(modified_manifest, "(BANDWIDTH=%d+)") do
        rendition_count = rendition_count + 1
      end
      local not_present = string.match(modified_manifest, "BANDWIDTH=800000") == nil

      assert.is_true(not_present, "the rendtion 800000 should not be present")
      assert.is.equals(2, rendition_count, "there should have only two renditions where bitrate >= 1500000")
    end,
  },
  {
    name="defines a maximum bitrate from FFmpeg", filter=bakery.hls.bandwidth, manifest=ffmpeg_master, context={min=0, max=1500000},
    check=function(modified_manifest)
      local rendition_count = 0
      for w in string.gmatch(modified_manifest, "(BANDWIDTH=%d+)") do
        rendition_count = rendition_count + 1
      end
      local not_present = string.match(modified_manifest, "BANDWIDTH=2000000") == nil

      assert.is_true(not_present, "the rendtion 2000000 should not be present")
      assert.is.equals(3, rendition_count, "there should have only three renditions where bitrate <= 1500000")
    end,
  },
  {
    name="defines a minimum and maximum bitrate from FFmpeg", filter=bakery.hls.bandwidth, manifest=ffmpeg_master, context={min=1500000, max=1500000},
    check=function(modified_manifest)
      local rendition_count = 0
      for w in string.gmatch(modified_manifest, "(BANDWIDTH=%d+)") do
        rendition_count = rendition_count + 1
      end
      local not_present = string.match(modified_manifest, "BANDWIDTH=2000000") == nil

      assert.is_true(not_present, "the rendtion 2000000 should not be present")
      assert.is.equals(1, rendition_count, "there should have only one rendition where bitrate = 1500000")
    end,
  },
  {
    name="returns all renditions when all renditions are filtered from FFmpeg", filter=bakery.hls.bandwidth, manifest=ffmpeg_master, context={min=1500, max=1500},
    check=function(modified_manifest)
      local rendition_count = 0
      for w in string.gmatch(modified_manifest, "(BANDWIDTH=%d+)") do
        rendition_count = rendition_count + 1
      end

      assert.is.equals(4, rendition_count, "there should have only one rendition where bitrate = 1500000")
    end,
  },
  {
    name="returns all renditions when no context is passed from FFmpeg", filter=bakery.hls.bandwidth, manifest=ffmpeg_master, context={},
    check=function(modified_manifest)
      local rendition_count = 0
      for w in string.gmatch(modified_manifest, "(BANDWIDTH=%d+)") do
        rendition_count = rendition_count + 1
      end

      assert.is.equals(4, rendition_count, "there should have only one rendition where bitrate = 1500000")
    end,
  },
}

describe("Resty Bakery", function()
  describe("HLS", function()

    -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
    describe("Bandwidth", function()
      for _, test in ipairs(bandwidth_tests) do
        it(test.name, function()
          local modified_manifest = test.filter(test.manifest, test.context)

          test.check(modified_manifest)
        end)
      end
    end)
  end)
end)
