package.path = package.path .. ";spec/?.lua"

local bakery = require "resty-bakery"

local variant_header =[[#EXTM3U
#EXT-X-VERSION:4
#EXT-X-MEDIA:TYPE=CLOSED-CAPTIONS,GROUP-ID="CC",NAME="ENGLISH",DEFAULT=NO,LANGUAGE="ENG"
]]
-- luacheck: ignore
local variant_avc1_4000kbs_29fps =[[#EXT-X-STREAM-INF:PROGRAM-ID=0,BANDWIDTH=4000,AVERAGE-BANDWIDTH=4000,CODECS="ac-3,avc",RESOLUTION=1920x1080,FRAME-RATE=29.97
http://existing.base/uri/link_1.m3u8
]]
local variant_avc1_2000kbs_29fps =[[#EXT-X-STREAM-INF:PROGRAM-ID=0,BANDWIDTH=2000,AVERAGE-BANDWIDTH=2000,CODECS="ac-3,avc",RESOLUTION=1280x720,FRAME-RATE=29.97
http://existing.base/uri/link_2.m3u8
]]
local variant_avc1_1000kbs_29fps =[[#EXT-X-STREAM-INF:PROGRAM-ID=0,BANDWIDTH=1000,AVERAGE-BANDWIDTH=1000,CODECS="ac-3,avc",RESOLUTION=640x360,FRAME-RATE=29.97
http://existing.base/uri/link_3.m3u8
]]
local variant = variant_header .. variant_avc1_4000kbs_29fps .. variant_avc1_2000kbs_29fps .. variant_avc1_1000kbs_29fps

describe("Resty Bakery", function()
  describe("HLS", function()

    -- https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md
    describe("Bandwidth", function()
      it("defines a minimum bitrate", function()
        local modified_variant, err = bakery.hls.bandwidth(variant, {min=2000})
        local expected_variant = variant_header .. variant_avc1_4000kbs_29fps .. variant_avc1_2000kbs_29fps

        assert.is_nil(err)
        assert.same(expected_variant, modified_variant)
      end)

      it("defines a maximum bitrate", function()
        local modified_variant, err = bakery.hls.bandwidth(variant, {max=2000})
        local expected_variant = variant_header .. variant_avc1_2000kbs_29fps .. variant_avc1_1000kbs_29fps

        assert.is_nil(err)
        assert.same(expected_variant, modified_variant)
      end)

      it("defines a minimum and maximum bitrate", function()
        local modified_variant, err = bakery.hls.bandwidth(variant, {min=2000, max=2000})
        local expected_variant = variant_header .. variant_avc1_2000kbs_29fps

        assert.is_nil(err)
        assert.same(expected_variant, modified_variant)
      end)

      it("returns all renditions when all renditions are filtered", function()
        local modified_variant, err = bakery.hls.bandwidth(variant, {min=2500, max=2500})

        assert.is_nil(err)
        assert.same(variant, modified_variant)
      end)
      it("returns all rendition when there is no max and min constraint", function()
        local modified_variant, err = bakery.hls.bandwidth(variant, {})

        assert.is_nil(err)
        assert.same(variant, modified_variant)
      end)
    end)

  end)
end)
