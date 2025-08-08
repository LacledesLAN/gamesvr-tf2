# Team Fortress 2 Dedicated Server in Docker

Team Fortress 2 (TF2) is a team-based multiplayer first-person shooter and the sequel to the 1996 mod Team Fortress for
Quake and its 1999 remake, Team Fortress Classic. Players join one of two teams comprising nine character classes,
battling in a variety of game modes including capture the flag and king of the hill. Valve continues to release new
content, including maps, items, and game modes, as well as community-made updates and contributed content.

![Team Fortress 2 Screenshot](https://raw.githubusercontent.com/LacledesLAN/gamesvr-tf2/master/Documentation/images/artwork01.jpg "Team
 Fortress 2 Screenshot")

This repository is maintained by [Laclede's LAN](https://lacledeslan.com). Its contents are intended to be bare-bones
and used as a stock server. For examples of building a customized server from this Docker image browse its related
child-projects [gamesvr-tf2-blindfrag](https://github.com/LacledesLAN/gamesvr-tf2-blindfrag) and
[gamesvr-tf2-freeplay](https://github.com/LacledesLAN/gamesvr-tf2-freeplay). If any documentation is unclear or it has
any issues please see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Linux x64 (64-bit)

### Run simple interactive server

```shell
docker run -it --rm --net=host lacledeslan/gamesvr-tf2 ./srcds_run_64 -game tf +randommap +sv_lan 1;
```

## Linux x86 (32-bit)

### Run simple interactive server

```shell
docker run -it --rm --net=host lacledeslan/gamesvr-tf2:32-bit ./srcds_run -game tf +randommap +sv_lan 1;
```

## Getting Started with Game Servers in Docker

[Docker](https://docs.docker.com/) is an open-source project that bundles applications into lightweight, portable,
self-sufficient containers. For a crash course on running Dockerized game servers check out [Using Docker for Game
Servers](https://github.com/LacledesLAN/README.1ST/blob/master/GameServers/DockerAndGameServers.md). For tips, tricks,
and recommended tools for working with Laclede's LAN Dockerized game server repos see the guide for [Working with our
Game Server Repos](https://github.com/LacledesLAN/README.1ST/blob/master/GameServers/WorkingWithOurRepos.md). You can
also browse all of our other Dockerized game servers: [Laclede's LAN Game Servers
Directory](https://github.com/LacledesLAN/README.1ST/tree/master/GameServers).
