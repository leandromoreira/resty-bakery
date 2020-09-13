[![Build Status](https://travis-ci.org/leandromoreira/resty-bakery.svg?branch=master)](https://travis-ci.org/leandromoreira/resty-bakery) [![license](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)

# Resty-Bakery [WIP] strongly inspired by [Bakery](https://github.com/cbsinteractive/bakery)

An Nginx+Lua library to modify media manifests like HLS and MPEG Dash, acting like a proxy between (or in) the `frontend` and the `origin`, currently we're filtering:

* **Bandwidth** (/path/to/media/f/`b(min,max)`/manifes.m3u8) - filters based on uri path following the format `b(min bandwidth, max bandwidth)`.

# Run locally

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


