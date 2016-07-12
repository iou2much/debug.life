title: 【译文】Docker微型镜像--Go微服务应用 
date: 2016-01-10 00:50:23
toc: true
category: 翻译
---

除非你是住在太平洋的孤岛上，不然你可能早就听说过微服务和Docker了，因为这是在假装知道什么是敏捷开发之后，现在最流行的一个涨薪理由。实际上，微服务也是真的对于我们的工作非常重要，使我们能开发具有独立性的代码，如果我们使用Docker或其他容器技术，我们可以在各个环境部署完全一样的代码。

我们刚接触Docker时，最常见的入门方式是使用Ubuntu或Debian等系统构建虚拟机，这种方式的弊端是产生的镜像太大了，单单是Ubuntu的基础镜像就已经有187.9MB，而且大部分装好的软件和依赖库都不会用到。

![容器的架构](http://nicholasjackson.github.io/images/post_images/micro_containers/containers_vs_vms.png)

容器和虚拟机的主要区别在于，容器在宿主系统的一个隔离进程空间里边运行，因此它不需要有独立的内核和其他系统文件，只要在上边安装你需要使用的东西，我们会需要Python来运行Go的服务吗？这不是一个很难回答的问题。


## 微基础镜像

首先我们要抛弃使用Ubuntu或者Debian作为基础镜像这种思路，我们着眼于更轻量的选择。

[Alpine Linux](http://www.alpinelinux.org/)是一个微型的Linux分发版，可以用来构建一个体积只有5M的基容器，它是基于一个嵌入式系统[BusyBox](http://www.busybox.net/about.html)改造的。那为什么不直接用BusyBox呢？使用Alphine有几个优点，首先，Alphine上有一个包管理系统<code>apk</code>，使用它可以简化容器的维护；第二，Alphine的内核已经被打上[PaX补丁](https://www.grsecurity.net)，可以免受大量0 day漏洞的侵害。

你可以在以下列表看到，Alphine只在BusyBox的基础上增加了4.1MB的体积，但是同时相应增加了那些便利，我觉得这部分开销非常值得。

| 镜像      | 体积  |
| :-------- | :--: |
| ubuntu  | 187.90 MB   |
| nicholasjackson/microservice-basebox      |  15.82 MB  |
| alpine      | 5.24 MB   |
| busybox      |  1.10 MB  |

## 为Alphine Linux编译Go应用
使用Go来构建微服务的一个优点是，它会被编译成二进制包，这样的话，它就不需要框架或者运行依赖，这样非常有利，因为正如前面所说Alphine是一个非常轻量级的分发版，并不是所有C语言依赖库都有安装，所以Go的动态库依赖很可能也没有。所幸的是有专门的方法去禁用了cgo依赖，可以把应用通过链接的方式编译，我们只需要这样告诉编译器去重新构建我们的所有应用包就可以了：
```sh
$ CGO_ENABLED=0 go build -a -installsuffix cgo .
```
我们更详细说一下上边这个命令的细节：
CGO_ENABLED=0 是一个编译标志，会让构建系统忽略cgo并且静态链接所有依赖；
-a会强制重新编译，即使所有包都是由最新代码编译的；
-installsuffix cgo 会为新编译的包目录添加一个后缀，这样可以把编译的输出与默认的路径分离。

## 运行应用

那么在二进制包里怎么使用配置文件呢，如果你是在使用微服务架构，那你很可能在使用[Consul](https://www.consul.io/)，如果还没有的话，那你真的应该好好研究一下它，它确实很强大。在本文中，我会假定你已经熟悉Consul，你在使用这个[Consul模板](https://github.com/hashicorp/consul-template)去管理你的配置文件。


我们通常需要使用监护进程来运行这些服务，例如[Supervisor](http://supervisord.org/)，不过这个工具需要使用Python，这样有违我们轻量级的初衷，所以我们使用[Skaware S6](http://skarnet.org/software/s6/)。

S6是一个简单有效的工具，它使用<code>/etc/s6</code>下的配置文件，来启动s6-svscan进程。你可以从我的[基镜像仓库](https://hub.docker.com/r/nicholasjackson/microservice-basebox/)中看到，这个目录下包含了一系列的shell脚本。


## .s6-svscan
这个目录包含两个脚本"crash"和"finish"，当s6所管理的应用由于错误终结时，crash脚本会被调用，当s6进程关闭时，finish脚本会被调用。


## app
这个目录包含"run"和"finish"两个脚本，run用来启动主服务，并且会被配置上Go应用的执行路径。而在finish中可以设置应用程序关闭时要执行的脚本。

## consul-template
这个目录同样也是包含了那两个脚本，但是这次它是用来配置consul-template应用的，consul-template生成微服务所用到的配置文件，相关配置文件会被储存在Consul服务端上，在Go微服务的整个生命周期中，Consul应用都需要运行着提供配置服务，所以我们也要通过s6来监控守护它。

## Docker基础镜像

为了方便测试，我已经使用Alphine来构建了一个带有Skaware S6和Consul Template的镜像，这个[新的镜像](https://hub.docker.com/r/nicholasjackson/microservice-basebox/)也是只有15.82MB。即使你基于这个镜像构建一个再臃肿的应用，那也估计不过30MB左右，但是这样还是只有一个Ubuntu基础镜像体积的13%。

## 结论
本文中，我主要是讨论了Go应用，但你可以基于类似的技术使用在Ruby或Python上，Alphine 的apk已经提供这两种语言的相关依赖包，另外再研究一下，你可能也可以在上边部署一个JRE环境在上边。
