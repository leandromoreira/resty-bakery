package.path = package.path .. ";spec/?.lua"

local dash = require "resty-bakery-dash"

local content_from = function(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*a")
  f:close()
  return content
end

local ffmpeg_dash = content_from("spec/manifests/ffmpeg_dash.mpd")

local bandwidth_tests = {
  {
    name="defines a minimum bitrate from FFmpeg", filter=dash.bandwidth, manifest=ffmpeg_dash, context={min=1500000, max=math.huge},
    check=function(modified_manifest)
      local rendition_count = #dash.video_representations_tags(modified_manifest)
      local not_present = string.match(modified_manifest, "bandwidth=\"800000\"") == nil

      assert.is_true(not_present, "the rendition 800000 should not be present")
      assert.is.equals(2, rendition_count, "there should have only two renditions where bitrate >= 1500000")
    end,
  },
  {
    name="defines a maximum bitrate from FFmpeg", filter=dash.bandwidth, manifest=ffmpeg_dash, context={min=0, max=1500000},
    check=function(modified_manifest)
      local rendition_count = #dash.video_representations_tags(modified_manifest)
      local not_present = string.match(modified_manifest, "bandwidth=\"2000000\"") == nil

      assert.is_true(not_present, "the rendition 2000000 should not be present")
      assert.is.equals(3, rendition_count, "there should have only three renditions where bitrate <= 1500000")
    end,
  },
  {
    name="defines a minimum and maximum bitrate from FFmpeg", filter=dash.bandwidth, manifest=ffmpeg_dash, context={min=1500000, max=1500000},
    check=function(modified_manifest)
      local rendition_count = #dash.video_representations_tags(modified_manifest)
      local not_present = string.match(modified_manifest, "bandwidth=\"2000000\"") == nil

      assert.is_true(not_present, "the rendition 2000000 should not be present")
      assert.is.equals(1, rendition_count, "there should have only one rendition where bitrate = 1500000")
    end,
  },
  {
    name="returns all renditions when all renditions are filtered from FFmpeg", filter=dash.bandwidth, manifest=ffmpeg_dash, context={min=1500, max=1500},
    check=function(modified_manifest)
      local rendition_count = #dash.video_representations_tags(modified_manifest)

      assert.is.equals(4, rendition_count, "there should have all the renditions")
    end,
  },
  {
    name="returns all renditions when no context is passed from FFmpeg", filter=dash.bandwidth, manifest=ffmpeg_dash, context={},
    check=function(modified_manifest)
      local rendition_count = #dash.video_representations_tags(modified_manifest)

      assert.is.equals(4, rendition_count, "there should have all the renditions")
    end,
  },
}

describe("Resty Bakery", function()
  describe("Dash", function()

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
