# Resty-Bakery [WIP] strongly inspired by https://github.com/cbsinteractive/bakery

A Nginx+Lua library to modify media manifests like HLS and MPEG Dash, filtering:

* Bandwidth

# Running locally

```bash
make run

# open another tab

# unmodified manifest
curl -v "http://localhost:8080/media/ffmpeg_master.m3u8"

# filters out renditions with bandwidth < 1500000
curl -v "http://localhost:8080/media/b(1500000)/ffmpeg_master.m3u8"

# filters out renditions with bandwidth > 1500000
curl -v "http://localhost:8080/media/b(0,1500000)/ffmpeg_master.m3u8"

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


