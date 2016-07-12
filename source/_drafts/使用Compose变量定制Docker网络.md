title: 【译文】使用Compose变量定制Docker网络 
date: 2016-01-10 00:50:23
toc: true
category: 翻译
---


我们能使用[Docker 多节点网络](http://blog.docker.com/2015/11/docker-multi-host-networking-ga/)来创建虚拟网络，把容器接入虚拟网络，能实现应用中所需要的网络拓扑。具体来说，Bridge网络能用来创建单节点网络，Overlay网络能创建多节点网络。通过这样给应用定制专用网络，能使为容器提供绝对的隔离性。

Docker Compose的目标是实现单节点网络，通过用<code>--x-networking</code> 来创建一个应用程序独有的桥接网络，如果应用程序需要多节点部署，可以使用Docker Swarm集群来创建一个overlay网络。[《单节点网络》](http://blog.arungupta.me/docker-multi-host-networking-couchbase-wildfly/)和[《多节点网络》](http://blog.arungupta.me/docker-machine-swarm-compose-couchbase-wildfly/)这两篇文章有更详细的介绍。

那如果一个桥接网络或overlay网络已经存在，而你想要把这个网络分配给运行中的容器呢？

![Docker 中的网络](http://7xnyt8.com1.z0.glb.clouddn.com/201512-2002598.png)

Docker 1.9 引入了变量替换的特性，我们可以利用这特性实现把容器关联到一个预创建的网络上。
## 创建Docker桥接网络

1. 创建网络:

```sh
docker network create -d bridge mynet
47d6225ffe56ddd1a8bc0d6abb0ffd8f8ac3eec2090ff243f8cd6f77c170751b=
```
2. 列出网络:
```sh
docker network ls
NETWORK ID          NAME                DRIVER
feb6e9567439        bridge              bridge              
29563a59abe8        none                null                
25ab737cd665        host                host                
47d6225ffe56        mynet               bridge
``` 

Docker会为每个节点自动创建三个网络：
| 网络名称 | 作用  |
| :-------- | :-- |
| bridge |  容器默认连接的网络，是所有Docker安装时都默认安装的docker0网络   |
| none     |   容器定制的网络栈 |
| host     |   在宿主网络栈上添加一个容器，容器中的网络配置会与宿主的一样|

上边看到，我刚创建的mynet网络也在列表中。

使用<code>docker inspect</code>命令查看mynet网络的详细信息：
```json
[
    {
        "Name": "mynet",
        "Id": "47d6225ffe56ddd1a8bc0d6abb0ffd8f8ac3eec2090ff243f8cd6f77c170751b",
        "Scope": "local",
        "Driver": "bridge",
        "IPAM": {
            "Driver": "default",
            "Config": [
                {}
            ]
        },
        "Containers": {},
        "Options": {}
    }
]
```
从Containers这节可以看到，目前还没有容器关联上去。

## Docker Compose 与 网络
1. 上面新建的网络能在新的容器中使用，只要在运行时使用<code>docker run --net=<NETWORK></code>命令。不过本文会用Compose文件实现：

```json
mycouchbase:
  container_name: "db"
  image: couchbase/server
  ports:
    - 8091:8091
    - 8092:8092 
    - 8093:8093 
    - 11210:11210
  net: ${NETWORK}
mywildfly:
  image: arungupta/wildfly-admin
  environment:
    - COUCHBASE_URI=db
  ports:
    - 8080:8080
    - 9990:9990
  net: ${NETWORK}
```
 注意这里<code>net</code>已经指定使用一个自定义网络。这个Compose文件在github上能下载: [github.com/arun-gupta/docker-images/blob/master/wildfly-couchbase-javaee7-network/docker-compose.yml](https://github.com/arun-gupta/docker-images/blob/master/wildfly-couchbase-javaee7-network/docker-compose.yml).

2. 使用新创建的网络来启动应用：
```sh
NETWORK=mynet docker-compose up -d
```
再查看网络详细信息：
```json

docker network inspect mynet
[
    {
        "Name": "mynet",
        "Id": "47d6225ffe56ddd1a8bc0d6abb0ffd8f8ac3eec2090ff243f8cd6f77c170751b",
        "Scope": "local",
        "Driver": "bridge",
        "IPAM": {
            "Driver": "default",
            "Config": [
                {}
            ]
        },
        "Containers": {
            "300bebe6c3e0350ebf9b9d3746eb3a7b49444e14c00314770627a9f101442639": {
                "EndpointID": "82a3e2d7cd4f1bb03c9ef52bb6abf284942d7e9fcac89fe3700b0e0c4ed2654f",
                "MacAddress": "02:42:ac:14:00:03",
                "IPv4Address": "172.20.0.3/16",
                "IPv6Address": ""
            },
            "4fdae4eb919f0934422513227fe541255557dd9e8b3317374685927e7f427249": {
                "EndpointID": "937605d716d144b55288d70817d611da5fb0f87e3aedd6b5074fca07f82c3953",
                "MacAddress": "02:42:ac:14:00:02",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {}
    }
]
```
可以看到现在已经有两个容器关联到这个网络上了。

使用<code>docker ps</code>查看容器ID：

```sh
# docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                                                                               NAMES
300bebe6c3e0        couchbase/server          "/entrypoint.sh couch"   2 minutes ago       Up 2 minutes        0.0.0.0:8091-8093->8091-8093/tcp, 11207/tcp, 11211/tcp, 0.0.0.0:11210->11210/tcp, 18091-18092/tcp   db
4fdae4eb919f        arungupta/wildfly-admin   "/opt/jboss/wildfly/b"   2 minutes ago       Up 2 minutes        0.0.0.0:8080->8080/tcp, 0.0.0.0:9990->9990/tcp                                                      wildflycouchbasejavaee7network_mywildfly_1
```

查看其中一个容器的网络设置:
```sh
docker inspect -f '{{ .HostConfig.NetworkMode }}' 300
mynet
```
 
查看这个容器的详细网络信息：
```sh
docker inspect -f '{{ .NetworkSettings.Networks.mynet }}' 300
{82a3e2d7cd4f1bb03c9ef52bb6abf284942d7e9fcac89fe3700b0e0c4ed2654f 172.20.0.1 172.20.0.3 16   0 02:42:ac:14:00:03}
```

这个容器的更多细节能用<code>docker inspect</code>看到，相关的部分在这里：

```json
"Networks": {
    "mynet": {
        "EndpointID": "82a3e2d7cd4f1bb03c9ef52bb6abf284942d7e9fcac89fe3700b0e0c4ed2654f",
        "Gateway": "172.20.0.1",
        "IPAddress": "172.20.0.3",
        "IPPrefixLen": 16,
        "IPv6Gateway": "",
        "GlobalIPv6Address": "",
        "GlobalIPv6PrefixLen": 0,
        "MacAddress": "02:42:ac:14:00:03"
    }
}
```
 
## 创建新的Docker Overlay网络
创建Overlay网络需要预先搭建好一个键值对服务和一个Docker Swarm集群，[《多节点网络和多容器服务》](http://blog.arungupta.me/docker-machine-swarm-compose-couchbase-wildfly/)这篇文章有更详细的介绍。


