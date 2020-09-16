[![Build Status](https://travis-ci.org/leandromoreira/resty-bakery.svg?branch=master)](https://travis-ci.org/leandromoreira/resty-bakery) [![license](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)

# Resty-Bakery [WIP]

It's a Nginx+Lua library, strongly inspired by [the CBS Bakery](https://github.com/cbsinteractive/bakery), to modify media manifests on-the-fly, like [HLS](https://tools.ietf.org/html/draft-pantos-hls-rfc8216bis-07) and [MPEG Dash](https://en.wikipedia.org/wiki/Dynamic_Adaptive_Streaming_over_HTTP). It acts as a proxy between (or in) the `frontend` and your `origin`.

This is very useful due to the fact that some [devices can't play with a higher bitrate, multiple codecs, multiple frame rate](https://github.com/leandromoreira/http-video-streaming-troubleshooting), and so on.

# Filters

* [**Bandwidth**](https://github.com/cbsinteractive/bakery/blob/master/docs/filters/bandwidth.md) (/path/to/media/f/`b(min,max)`/manifes.m3u8) - filters based on uri path following the format `b(min bandwidth, max bandwidth)`.
* [**Framerate**](https://github.com/cbsinteractive/bakery/blob/master/docs/filters/frame-rate.md) (/path/to/media/f/`fps(30,30000:1001)`/manifes.m3u8) - filters out based on uri path following the format `b(list of frame rates)`.

# Nginx usage example


```nginx
# Let's suppose our origin hosts media at /media/<manifest>.<extension>
# So what we need to do is to set up a location to act like a proxy
# Also, let's say we're going to use /media/<filters>/<manifest>.<extension> to pass the filters
#  ex: /media/b(1500000)/playlist.m3u8
    location /media {
        proxy_pass http://origin;

        # we need to keep the original uri with its state, since we're going to rewrite
        # from /media/<filters>/<manifest>.<extension> to /media/<manifest>.<extension>
        set_by_lua_block $original_uri { return ngx.var.uri }

        # when the Lua code may change the length of the response body,
        # then it is required to always clear out the Content-Length
        header_filter_by_lua_block { ngx.header.content_length = nil }

        # rewriting to the proper origin uri, effectively removing the filters
        rewrite_by_lua_block {
          local uri = ngx.re.sub(ngx.var.uri, "^/media/(.*)/(.*)$", "/media/$2")
          ngx.req.set_uri(uri)
        }

        # applying the filters (after the proxy/upstream has replied)
        # this is where the magic happens
        body_filter_by_lua_block {
          local modified_manifest = bakery.filter(ngx.var.original_uri, ngx.arg[1])
          ngx.arg[1] = modified_manifest
          ngx.arg[2] = true
        }
    }
```

# Test locally

```bash
make run

# open another tab

# unmodified manifest
curl -v "http://localhost:8080/media/ffmpeg_master.m3u8"
curl -v "http://localhost:8080/media/ffmpeg_dash.mpd"

# filters out renditions with bandwidth < 1500000
curl -v "http://localhost:8080/media/b(1500000)/ffmpeg_master.m3u8"
curl -v "http://localhost:8080/media/b(1500000)/ffmpeg_dash.mpd"

# filters out renditions with bandwidth > 1500000
curl -v "http://localhost:8080/media/b(0,1500000)/ffmpeg_master.m3u8"
curl -v "http://localhost:8080/media/b(0,1500000)/ffmpeg_dash.mpd"

# filters bandwidth > 800000 and excludes frame rate 60
curl "http://localhost:8080/media/b(800000)fps(60)/generic_master.m3u8"
curl "http://localhost:8080/media/b(800000)fps(60,60:1)/generic_dash.mpd"


# PS: there is an mmedia location just to provide manifests without
# data transfer them in chunked encoding mechanism
# this example was done due some CTV that can't handle chunked transfer encoding
```

# Tests

```bash
make test
```

# Lint

```bash
make lint
```


