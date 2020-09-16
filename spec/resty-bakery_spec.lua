package.path = package.path .. ";spec/?.lua"

local bakery = require "resty-bakery"
local hls = require "resty-bakery-hls"
local dash = require "resty-bakery-dash"

describe("Acceptance Resty Bakery", function()
  describe("HLS", function()
    it("filters an manifest for an uri", function()
      local uri = "/path/to/my/fps(60)b(800000)/playlist.m3u8"
      local manifest = [[#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=600000,RESOLUTION=384x216,FRAME-RATE=30,CODECS="avc1.640016,mp4a.40.2"
variant_0.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=768x432,FRAME-RATE=30,CODECS="avc1.64001f,mp4a.40.2"
variant_1.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720,FRAME-RATE=60,CODECS="avc1.640020,mp4a.40.2"
variant_2.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1920x1080,FRAME-RATE=60,CODECS="avc1.64002a,mp4a.40.2"
variant_3.m3u8
]]
      local modified_manifest = bakery.filter(uri, manifest)

      assert.is.equals(1, #hls.video_renditions(modified_manifest), "manifest should contain a single rendition")
    end)
  end)

  describe("MPEG-DASH", function()
    it("filters an manifest for an uri", function()
      local uri = "/path/to/my/b(1500000,1500000)/index.mpd"
      local manifest = [[<?xml version="1.0" encoding="utf-8"?>
<MPD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns="urn:mpeg:dash:schema:mpd:2011"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xsi:schemaLocation="urn:mpeg:DASH:schema:MPD:2011 http://standards.iso.org/ittf/PubliclyAvailableStandards/MPEG-DASH_schema_files/DASH-MPD.xsd"
	profiles="urn:mpeg:dash:profile:isoff-live:2011"
	type="dynamic"
	minimumUpdatePeriod="PT5S"
	suggestedPresentationDelay="PT5S"
	availabilityStartTime="2020-09-13T11:57:28Z"
	publishTime="2020-09-13T11:58:18Z"
	timeShiftBufferDepth="PT20M50.0S"
	minBufferTime="PT10.0S">
	<ProgramInformation></ProgramInformation>
	<Period id="0" start="PT0.0S">
		<AdaptationSet id="0" contentType="video" segmentAlignment="true" bitstreamSwitching="true">
			<Representation id="1" mimeType="video/mp4" codecs="avc1.42c01e" bandwidth="600000" width="384" height="216" frameRate="30/1">
				<SegmentTemplate timescale="15360" initialization="init-stream$RepresentationID$.m4s" media="chunk-stream$RepresentationID$-$Number%05d$.m4s" startNumber="1">
					<SegmentTimeline>
						<S t="0" d="76800" r="9" />
					</SegmentTimeline>
				</SegmentTemplate>
			</Representation>
			<Representation id="2" mimeType="video/mp4" codecs="avc1.42c01e" bandwidth="800000" width="768" height="432" frameRate="30/1">
				<SegmentTemplate timescale="15360" initialization="init-stream$RepresentationID$.m4s" media="chunk-stream$RepresentationID$-$Number%05d$.m4s" startNumber="1">
					<SegmentTimeline>
						<S t="0" d="76800" r="9" />
					</SegmentTimeline>
				</SegmentTemplate>
			</Representation>
			<Representation id="3" mimeType="video/mp4" codecs="avc1.42c01f" bandwidth="1500000" width="1280" height="720" frameRate="30/1">
				<SegmentTemplate timescale="15360" initialization="init-stream$RepresentationID$.m4s" media="chunk-stream$RepresentationID$-$Number%05d$.m4s" startNumber="1">
					<SegmentTimeline>
						<S t="0" d="76800" r="9" />
					</SegmentTimeline>
				</SegmentTemplate>
			</Representation>
			<Representation id="4" mimeType="video/mp4" codecs="avc1.42c01f" bandwidth="2000000" width="1920" height="1080" frameRate="30/1">
				<SegmentTemplate timescale="15360" initialization="init-stream$RepresentationID$.m4s" media="chunk-stream$RepresentationID$-$Number%05d$.m4s" startNumber="1">
					<SegmentTimeline>
						<S t="0" d="76800" r="9" />
					</SegmentTimeline>
				</SegmentTemplate>
			</Representation>
		</AdaptationSet>
		<AdaptationSet id="5" contentType="audio" segmentAlignment="true" bitstreamSwitching="true">
			<Representation id="5" mimeType="audio/mp4" codecs="mp4a.40.2" bandwidth="64000" audioSamplingRate="48000">
				<AudioChannelConfiguration schemeIdUri="urn:mpeg:dash:23003:3:audio_channel_configuration:2011" value="1" />
				<SegmentTemplate timescale="48000" initialization="init-stream$RepresentationID$.m4s" media="chunk-stream$RepresentationID$-$Number%05d$.m4s" startNumber="1">
					<SegmentTimeline>
						<S t="0" d="240640" />
						<S d="239616" />
						<S d="240640" />
						<S d="239616" r="1" />
						<S d="240640" />
						<S d="239616" r="1" />
						<S d="240640" />
						<S d="239616" />
					</SegmentTimeline>
				</SegmentTemplate>
			</Representation>
		</AdaptationSet>
	</Period>
	<UTCTiming schemeIdUri="urn:mpeg:dash:utc:http-xsdate:2014" value="https://time.akamai.com/?iso"/>
</MPD>
]]
      local modified_manifest = bakery.filter(uri, manifest)

      assert.is.equals(1, #dash.video_renditions(modified_manifest), "manifest should contain a single rendition")
    end)
  end)
end)

describe("Filter config", function()
  local config = {
    -- bitrate
    {name="build a config for a minimum bitrate", filter="bandwidth", uri="/a/b(1000)/b/", expected={min=1000}},
    {name="build a config for a min/max bitrate", filter="bandwidth", uri="/a/b(1000,2000)/b/", expected={min=1000,max=2000}},
    {name="build an empty config for an empty bitrate", filter="bandwidth", uri="/a/b()/b/", expected={}},
    -- framerate
    {name="build a config for a single fps", filter="framerate", uri="/a/fps(30)/b/", expected={fps={"30"}}},
    {name="build a config for a single float fps", filter="framerate", uri="/a/fps(29.970)/b/", expected={fps={"29.970"}}},
    {name="build a config for a single fps in X/Y form", filter="framerate", uri="/a/fps(30000:1001)/b/", expected={fps={"30000/1001"}}},
    {name="build a config for a multi fps", filter="framerate", uri="/a/fps(30,30000:1001,29.970)/b/", expected={fps={"30","30000/1001","29.970"}}},
    {name="build an empty config for an empty fps", filter="framerate", uri="/a/fps()/b/", expected={fps={}}},
  }

  for _, test in ipairs(config) do
    it(test.filter .. " :: " .. test.name, function()
      -- we're similuating the main loop
      -- TODO: create a function for it?
      local sub_uri = string.match(test.uri, bakery.filters_config[test.filter].match)
      local context = bakery.filters_config[test.filter].context_args(sub_uri)

      assert.are.same(test.expected, context)
    end)
  end
end)
