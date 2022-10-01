# Optional SteamCMD Cache

This folder can be used to cache SteamCMD downloads prior to executing `docker build`. While this speeds up builds on a
slow Internet connections. Builds on fast internet connections will *likely be slower* due to context loading. Your
mileage will vary.

## Disabling SteamCMD Downloads

If you anticipate having to do emergency builds when Internet bandwidth is at a premium disabling SteamCMD downloads and
 relying on an already-built cache *could* by a real lifesaver. Just provide the argument of
 `--build-arg SKIP_STEAMCMD=true` when building the image.

## Build the Cache

To populate the cache install the relevant game server data into this directory using
[SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD). If you are using [VSCode](https://code.visualstudio.com/)
a task is already defined otherwise you can use [Laclede's LAN SteamCMD Docker](https://github.com/LacledesLAN/SteamCMD)
image:

```shell
./build-cache.sh
```
