package.path = package.path .. ";spec/?.lua"

local dash = require "resty-bakery-dash"
local hls = require "resty-bakery-hls"
local helper = require "test-helper"

-- in order to add your manifests here please make sure they:
-- * have 4 renditions
-- * being the bandwidth for them 600000, 800000, 1500000, and 2000000
-- * save them at spec/manifests/<SOURCE_NAME>_<TYPE>.<EXTENSION>
--    * SOURCE_NAME refers to where the manifest where generated
--    * TYPE should be dash, master, and variant
--    * EXTENSION should be mpd, m3u8
local manifest_set = {
  {name="Dash :: FFmpeg", handler=dash, content=helper.content_from("spec/manifests/ffmpeg_dash.mpd")},
  {name="HLS :: FFmpeg", handler=hls, content=helper.content_from("spec/manifests/ffmpeg_master.m3u8")},
}

local bandwidth_tests = {
  {name="defines a minimum bitrate", context={min=1500000, max=math.huge}, absent_bitrate=800000, expected_renditions=2},
  {name="defines a maximum bitrate", context={min=0, max=1500000}, absent_bitrate=2000000, expected_renditions=3},
  {name="defines a minimum and maximum bitrate", context={min=1500000, max=1500000}, absent_bitrate=800000, expected_renditions=1},
  {name="defines a minimum bitrate", context={min=1500000, max=math.huge}, absent_bitrate=800000, expected_renditions=2},
  {name="returns all rendintions when they were all filtered", context={min=10, max=10}, expected_renditions=4},
  {name="returns all rendintions when no context is given", context={}, expected_renditions=4},
}

describe("Resty Bakery :: Bandwidth", function()
  for _, manifest in ipairs(manifest_set) do
    describe(manifest.name, function()
      for _, test in ipairs(bandwidth_tests) do
        it(test.name, function()
          local modified_manifest = manifest.handler.bandwidth(manifest.content, test.context)

          local rendition_count = #manifest.handler.video_renditions(modified_manifest)
          assert.is.equals(test.expected_renditions, rendition_count, "there should have " .. test.expected_renditions .. " renditions")

          -- for some tests we're not expecting to remove bitrates
          if test.absent_bitrate then
            local present = manifest.handler.has_bitrate(modified_manifest, test.absent_bitrate)
            assert.is_false(present, "the rendition " .. test.absent_bitrate .. " should be absent")
          end
        end)
      end
    end)
  end
end)
