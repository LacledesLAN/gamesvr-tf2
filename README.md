# Team Fortress 2 in Docker

## Linux
[![](https://images.microbadger.com/badges/version/lacledeslan/gamesvr-tf2.svg)](https://microbadger.com/images/lacledeslan/gamesvr-tf2 "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/lacledeslan/gamesvr-tf2.svg)](https://microbadger.com/images/lacledeslan/gamesvr-tf2 "Get your own image badge on microbadger.com")

**Download**
```
docker pull lacledeslan/gamesvr-tf2
```

**Run self tests**
```
not yet implemented
```

**Run simple interactive server**
```
docker run -it --rm --net=host lacledeslan/gamesvr-tf2 ./srcds_run -game tf +mapcyclefile mapcycle_LL_all.txt -console -usercon +randommap +sv_lan 1
```

## Build Triggers
Automated builds of this image can be triggered by the following sources:
* [Builds of llgameserverbot/tf2-watcher](https://hub.docker.com/r/llgameserverbot/tf2-watcher/)
* [Commits to GitHub repository](https://github.com/LacledesLAN/gamesvr-tf2)
