# Team Fortress 2 in Docker

## Linux
[![](https://images.microbadger.com/badges/version/lacledeslan/gamesvr-tf2.svg)](https://microbadger.com/images/lacledeslan/gamesvr-tf2 "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/lacledeslan/gamesvr-tf2.svg)](https://microbadger.com/images/lacledeslan/gamesvr-tf2 "Get your own image badge on microbadger.com")

**Download**
```
docker pull lacledeslan/gamesvr-tf2
```

**Run self tests** NOT YET WORKING
```
docker run -it --rm lacledeslan/gamesvr-tf2 ./ll-tests/gamesvr-tf2.sh
```

**Run simple interactive server**
```
docker run -it --rm --net=host lacledeslan/gamesvr-tf2 ./srcds_run -game tf -console -usercon +randommap +sv_lan 1
```

## Build Triggers
Automated builds of this image can be triggered by the following sources:
* [Builds of llgameserverbot/tf2-watcher](https://hub.docker.com/r/llgameserverbot/tf2-watcher/)
* [Commits to GitHub repository](https://github.com/LacledesLAN/gamesvr-tf2)
