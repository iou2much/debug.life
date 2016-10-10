title: 【debug.life构建手记】 ( 三 ) Docker化本站
date: 2016-02-01 02:48:39
tags: 
 - Openresty
 - Docker
description: 本文介绍如何安装配置一个安装了Nginx的Docker容器，为本站提供服务
toc: true
category: Tools
---

## 背景

### Docker

Docker是一种虚拟化技术，说到虚拟化，可能很多人都用过各种VM产品，VirtualBox、VMware、Xen、KVM等等。

那它和传统的虚拟化技术有什么不同呢？参考[Docker —— 从入门到实践](http://dockerpool.com/static/books/docker_practice/index.html)中的一个表格：

|特性	|容器	|虚拟机|
|:------|:-----:|:----:|
|启动	|秒级	|分钟级|
|硬盘使用|	一般为 MB	|一般为 GB|
|性能	|接近原生	|弱于|
|系统支持量	|单机支持上千个容器	|一般几十个|


除了超级轻量这个特点，Docker在这两年火得一塌糊涂，很大原因是它直击了IT行业的几个痛点：
- 在开发测试阶段，它在开发工作流程优化上的影响力是其他工具难以企及的。
- 在架构设计方面，它和微服务等思想的出现和推广，使分布式应用设计更加普及了。
- 降低云环境的搭建门槛(技术上和资金上)，成为云环境的技术标准，使云技术应用遍地开花，以致于连它发源公司的Paas平台dotCloud也宣布了破产并将于本月底关闭。

以上几点是个人浅见，另外关于Docker的介绍实在太多了，随处可见，我在此就不再多说。如果还有同学不知道Docker为何物，可以看一下这几篇文章了解一下它的吸引力何在：[《Docker五大优势：持续集成、版本控制、可移植性、隔离性和安全性》](http://dockone.io/article/389) 、[《八个Docker的真实应用场景》](http://dockone.io/article/126)。


### Docker与本站

前面说过，我之所以购置阿里云ECS不止是开一个小博客，更是因为想在云上开展一些小实验，而这些实验应用我是打算在Docker容器中跑的，而Docker容器又需要一个编排系统来有序管理。所以我选用了Openshift，它集成了Google的kubernetes的强大，又有一套可视化界面来管理。

> OpenShift 是由红帽公司推出的 PaaS 云计算平台，供用户创建网络应用（App、网站）。

> 由 [OpenShift Origin](https://github.com/openshift/origin)管理，支持github，开发者可以使用Git来发布自己的web应用程序到平台上。 —— [Wikipedia](https://zh.wikipedia.org/wiki/OpenShift)

前两天在ECS上用Openshift Origin的时候，发现总是有些容器运行的时候报<code>Command not found</code>的错误,Google了一轮之后还是无解，我猜可能是Docker版本过低造成的，因为我最初选ECS的系统盘时，选了CentOS 6.5 , 而CentOS 6支持的最高Docker版本是1.7.1，而最新的Docker都到1.9.x了。


于是，我就痛下决心把系统也换了，升级到CentOS 7试试看。还好阿里云换个系统还是挺方便，官方文档有[详细介绍](https://help.aliyun.com/knowledge_detail/5974444.html?pos=1)，而且刚好他们1月16号有邮件通知说免费升级系统盘，现在默认最小容量是40G了（我之前刚买的时候只有20G）。哈哈，这等巧事也让我遇上了。

在做好了必要的备份后，我换系统的过程花了10分钟不到。接下来我想，干脆就趁着这机会把ECS上全部服务都容器化好了，之后把自建的镜像push到DockerHub上，以后再怎么迁移更换系统也是分钟级能完成的事。

而服务器上最基础的服务是为这个博客的HTTP服务：Openresty(Nginx)，第一个要重新部署的非它莫属了。于是，便有了本篇笔记，讲述本站点的HTTP服务容器化过程。

## 准备工作

### 安装Docker

换好系统之后啥都没管，第一件事就是把Docker装上看看，按照Docker[官方安装文档](https://docs.docker.com/engine/installation/centos/)配好yum源，<code>yum install docker-engine</code>之后，看了看docker的版本，果然已经是1.9.1了（经过一番测试，之前的<code>Command not found</code>错误也消失了。

安装过程很简单，按上边的官方文档链接来即可。

### 配置阿里仓库下载加速器

在国内玩过Docker的人肯定都会被国内的网络恶心过，pull一个镜像可能网络中断好几次才艰难地完成。还好在ECS上玩有阿里云提供的[容器Hub服务](https://help.aliyun.com/knowledge_detail/5974865.html)，还有[加速器](http://console.d.aliyun.com/index2.html/?spm=0.0.0.0.Xx1dX0#/docker/booster)。我使用了以下命令设置了阿里的仓库：

```sh
sudo cp -n /lib/systemd/system/docker.service /etc/systemd/system/docker.service
sudo sed -i "s|ExecStart=/usr/bin/docker daemon|ExecStart=/usr/bin/docker daemon --registry-mirror=https://nn5nu75o.mirror.aliyuncs.com|g" /etc/systemd/system/docker.service
sudo systemctl daemon-reload
sudo service docker restart
```

设好了之后镜像下载速度咻咻地上去了，大部分常用的镜像像是在内网下载的感觉。

### 选择镜像

由于时间有限，我这次没从基础镜像自行编译Openresty，而是直接在DockerHub上找了一个已经装好Openresty 1.9.3的镜像[ficusio/openresty](https://hub.docker.com/r/ficusio/openresty/)。

```sh
docker pull ficusio/openresty
```

## 配置Nginx

现在镜像已经拉取到ECS上了，现在需要把原来在[基础设施搭建](https://debug.life/2016/01/16/build-my-site-1/#u5B89_u88C5Openresty)中配置好的Nginx conf文件和证书文件都复制出来，专门给之后要启的容器使用。

```sh
[userx@localhost blog]$ pwd
/home/userx/blog
[userx@localhost blog]$ ls
conf  contents  logs  start.sh

# conf下的直接是原Nginx配置文件
[userx@localhost blog]$ ls conf/
conf.d                fastcgi_params.default  mime.types.default  scgi_params.default   win-utf
fastcgi.conf          koi-utf                 nginx.conf          ssl
fastcgi.conf.default  koi-win                 nginx.conf.default  uwsgi_params
fastcgi_params        mime.types              scgi_params         uwsgi_params.default

# Hexo生成的文件
[userx@localhost blog]$ ls contents/
Linux-ops  atom.xml    fancybox     fonts.bak   js          sitemap.xml
404    about      categories  favicon.ico  images      playground  subscribe
CNAME  archives   css         fonts        index.html  ppt         tags
```

其中<code>conf</code>是原来nginx中的<code>conf</code>，<code>conf/ssl</code>中包含了配置https须使用的<code>key</code>和<code>crt</code>文件，contents下是网站的静态文件，logs是将要挂载到容器中的目录。

下边看一下<code>start.sh</code>文件，它是启动容器的脚本：
```sh
#!/usr/bin/env bash

docker run -d \
  --name blog \
  -p 80:80 \
  -p 443:443 \
  -v "$(pwd)/conf":/opt/openresty/nginx/conf \
  -v "$(pwd)/contents":/home/userx/debug.life \
  -v "$(pwd)/logs":/opt/openresty/nginx/logs \
  ficusio/openresty "$@"

```

这里用到了docker run的几个参数，在官方文档都能看到。
这里大概描述一下几个主要参数的作用：
- <code>-d</code> 是 <code>detach</code>的缩写，使用它会以后台运行的方式启动容器；另外Docker还有<code>attach</code>命令，是把命令行窗口重新关联到容器。类比一下执行普通长进程时，按了<code>Ctrl+z</code>就是<code>detach</code>，输入<code>fg</code>相当于<code>attach</code>。
- <code>-p</code>是端口映射，<code>-p 宿主机端口:容器端口</code>这样就能把容器的端口映射到宿主机上。
- <code>-v</code>是挂载文件卷，<code>-v 宿主机路径:容器路径</code>这样可以把宿主机的一个路径挂到容器中，相当于共享盘。

这个命令传这些参数都是特定的，因为在<code>ficusio/openresty</code>镜像中，Openresty安装在<code>/opt/openresty</code>下，所以把当前目录的<code>conf</code>目录挂载到<code>/opt/openresty/nginx/conf</code>，这样启动容器时nginx就能读到我的配置；

而<code>contents</code>目录挂载到<code>/home/userx/debug.life</code>是因为我在一开始配置nginx的时候，站点的root就指向了<code>/home/userx/debug.life</code>，我这里完全没有更改旧的nginx配置，所以直接挂载就好；

而<code>logs</code>同理。


### 启动容器
上边的脚本名称那么明显，分明就是用来启动的嘛~所以这样执行一下即可:

```sh
[userx@localhost blog]$ ./start.sh
```

查看容器是否已经启动

```sh

[userx@localhost ~]# docker ps
CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS                                      NAMES
a69791da83fd        ficusio/openresty             "nginx -g 'daemon off"   2 hours ago         Up About an hour    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   blog

```

顺道看一下系统中的状态：

```sh

# 可以看到80和443端口正在监听，关联的进程叫docker-proxy
[userx@localhost ~]# netstat -anp|grep 443|grep proxy
tcp        0      0 192.168.0.1:35667       192.168.0.4:443         ESTABLISHED 11805/docker-proxy
tcp6       0      0 :::443                  :::*                    LISTEN      11805/docker-proxy
tcp6       0      0 139.196.11.160:443      42.88.73.13:12541       ESTABLISHED 11805/docker-proxy

[userx@localhost ~]# netstat -anp|grep 80|grep proxy
tcp        0      0 192.168.0.1:35671       192.168.0.4:443         ESTABLISHED 11805/docker-proxy
tcp6       0      0 :::443                  :::*                    LISTEN      11805/docker-proxy
tcp6       0      0 :::80                   :::*                    LISTEN      11814/docker-proxy
tcp6       0      0 139.196.11.160:443      42.88.73.13:12558       ESTABLISHED 11805/docker-proxy
unix  2      [ ]         DGRAM                    1420960  11805/docker-proxy

# 是的，这样在宿主机能看到docker容器中的进程
[userx@localhost ~]# ps aux|grep nginx
userx     11820  0.0  0.2  22172  3960 ?        Ss   18:45   0:00 nginx: master process nginx -g daemon off; error_log /dev/stderr info;
65534    11826  0.0  0.1  22956  3396 ?        S    18:45   0:00 nginx: worker process
userx     17433  0.0  0.0 112616   736 pts/0    S+   20:08   0:00 grep --color=auto nginx

```

### 重启nginx

nginx正在跑了，网站也能正常访问了，那如果之后需要修改nginx的配置，要怎么操作呢？

很简单，前边说到，在<code>conf</code>中的任何更改都会体现到容器中，所以在宿主机上直接修改即可。

但是重启nginx就不能像普通那样用<code>nginx -s reload</code>了，因为你无法直接操作到容器中的文件，需要把整个容器重启：

```sh
docker restart blog
```

这样重启容器就相当于是重启“机器”了，这里最后一个参数是哪来的呢，好像哪里见过？对，就是刚刚脚本里启动容器时通过<code>--name blog</code>给容器指定的名称。

### 遇到的问题

在启动的过程中，Docker容器的端口映射实际是用了iptables的nat来实现的，所以如果iptables中没有相关配置就会出错，需要在<code>/etc/sysconfig/iptables</code>中添加：


```sh
*nat
:PREROUTING ACCEPT [27:11935]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [598:57368]                                                                  8,3           All
:POSTROUTING ACCEPT [591:57092]
:DOCKER - [0:0]
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
COMMIT
```

### 总结

至此，你现在所看到的页面已经是运行在Docker容器上的了，但是上边的整个配置仅仅是实现在Docker容器中代理一个静态网站，如果要使用这个nginx实现反向代理主机的服务呢,甚至是反向代理到其他容器呢？那又是另一回事了。容器之间的网络通讯是目前原生Docker支持得还不够完善的一个方面，在之后我可能会用到Kubernetes来实现nginx反向代理到其他容器服务，把相关容器放在同一个pod中。最终实现前边说的一个目的，把ECS上的所有服务都容器化。
