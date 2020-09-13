package.path = package.path .. ";spec/?.lua"

local bakery = require "resty-bakery"

describe("Functional Resty Bakery", function()
  describe("HLS", function()
    it("filters an manifest for an uri", function()
      local uri = "/path/to/my/b(1500000,1500000)/playlist.m3u8"
      local manifest = [[#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=600000,RESOLUTION=384x216,CODECS="avc1.640016,mp4a.40.2"
variant_0.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=768x432,CODECS="avc1.64001f,mp4a.40.2"
variant_1.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720,CODECS="avc1.640020,mp4a.40.2"
variant_2.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1920x1080,CODECS="avc1.64002a,mp4a.40.2"
variant_3.m3u8
]]
      local expected_manifest = [[#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720,CODECS="avc1.640020,mp4a.40.2"
variant_2.m3u8
]]
      local modified_manifest = bakery.filter(uri, manifest)

      assert.is.equals(expected_manifest, modified_manifest, "manifest should contain a single rendition")
    end)
  end)
end)

