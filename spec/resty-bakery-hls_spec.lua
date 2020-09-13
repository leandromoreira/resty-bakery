package.path = package.path .. ";spec/?.lua"

local hls = require "resty-bakery-hls"
local helper = require "test-helper"

local ffmpeg_master = helper.content_from("spec/manifests/ffmpeg_master.m3u8")

describe("Resty Bakery", function()
  describe("HLS", function()
    it("checks if it has a bitrate", function()
      assert.is_true(hls.has_bitrate(ffmpeg_master, 800000), "it should have 800000 bitrate")
      assert.is_false(hls.has_bitrate(ffmpeg_master, 850000), "it shouldn't have 850000 bitrate")
    end)

    it("returns the video renditions", function()
      local renditions = hls.video_renditions(ffmpeg_master)

      assert.is.equals(4, #renditions, "there should have 4 renditions")
    end)
  end)
end)
