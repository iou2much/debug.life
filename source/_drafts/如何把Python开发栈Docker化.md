# 将Docker化进行到底--Python篇
[DevOps](http://devopsreactions.tumblr.com/)社区中的人应该都听过[Docker](http://www.docker.com/)，有很多系统管理员会告诉你Docker是怎样令他们的生活变得更轻松，自动化部署是多么好用，容器是多么轻量...

那么，Docker实际上解决了什么问题呢？

首先，Docker会把应用连同所有依赖打包进一个完整的文件系统，这样构成一个Docker镜像；而下一步就是把容器部署到生产环境的设施上，例如说AWS，Heroku或者其他云服务。

在Docker出现以前，很多系统管理员都以自己的方式去打包部署应用。

一个规模小的电商网站可能使用git去部署代码，用[virtualenv](https://virtualenv.pypa.io/en/latest/)去作为应用运行的隔离环境。另外还有现成的解决方案，像[Heroku](http://www.heroku.com/)，[Elastic Beanstalk](https://aws.amazon.com/documentation/elastic-beanstalk/), [Google AppEngine](https://cloud.google.com/appengine/)和其他一些平台，它们都有各自的打包部署方式。

而今，所有的配置和环境设置都在Docker容器中标准化管理了，这样节省了开发者们非常多的重复安装和维护时间。

![图1](http://7xnyt8.com1.z0.glb.clouddn.com/%E6%8A%8APython%E8%BD%AF%E4%BB%B6%E6%A0%88Docker%E5%8C%96.png)
(来源 https://www.docker.com/whatisdocker)

## 如何在我们Python软件栈中使用Docker?
我们通常在Oursky上使用virtualenv来运行Python环境，而现在，我们来尝试一下Docker，看看它有没有传说中那么厉害。

很快的，我们有小伙伴提出了疑问：

有什么是容器技术能实现，而一个使用python+virtualenv+git作为规范的开发者不能做？

这个问题我们可以从以下方面讨论：
#### 容器的层次
当我们使用Docker把整个应用的隔离环境都打包部署时，它和virtualenv的作用是类似的。

唯一的不同是，应用程序的隔离程度如何：

##### virtualenv
- 依赖于不同版本的Python解释器和模块
- 运行在同一个文件系统和网络环境中，每个进程都在同一个进程空间

##### chroot
- 应用程序运行在独立的文件系统中
- 与其他进程共享网络环境和系统内核
- 进程共享着相同的init进程。

##### Docker
- 应用运行在独立的文件系统和网络环境中
- 与其他进程共享着相同的内核和init进程

##### Virtualization
- 应用运行在独立的操作系统中
- 只是共享着相同的虚拟机hypervisor

各种技术都有不尽相同的隔离方案，而virtualenv是其中最轻量的一个选择。

隔离旨在解决很多环境依赖的问题，也带来安全性方面上的优化，但是Docker本身也和应用环境的安全性有密切关系。


#### Docker并不总是最简单最轻量的方案
作为一个简单的Python应用，这些是Docker能带来：

- Docker增加了复杂度 -- 打包一个Docker镜像比打包一个Python egg包更复杂。
- Docker增加了体积 -- Docker镜像相比来说比Python egg体积要大。

#### Docker中的日志并不持久
日志应该是可以持久化的，即使是经过了版本更新，旧版本应用的日志都应该还保留着。但是这个要求在Docker的世界里并不满足，日志文件与容器绑定了，所以在新的镜像运行时，旧容器的日志便会丢失；而且目前还没有一种解决方案，能在容器外部持久化日志的。

我们的解决方案是：实现在Docker容器中持久化日志

最简单的方法是使用syslog日志驱动：

```sh
docker run --log-driver syslog imagename
```
默认地，syslog驱动把日志输送到默认的unix socket。为了把多个节点上的日志汇总到一个日志收集服务器，可以给每个[日志驱动配置](https://docs.docker.com/reference/logging/overview/)上一个指定地址，可以给docker命令加上额外的参数。

另外，你需要配置syslog去把日志保存在一个合适的路径下（例如，/var/log），或者把日志推到一个独立的日志收集服务。

[Fluentd](http://www.fluentd.org/)是另一个更强大的日志驱动，能把日志发送到S3（一个日志收集服务）并且同时能记录到syslog中。

### 总而言之
#### 有什么是Docker能做，而virtualenv不能的？

如果你是正在开发一个Python web服务，例如[pyramid](http://www.pylonsproject.org/)的API，答案依然还是：并没有多少。
把一个应用Docker化看起来效果与建立一个virtualenv环境差不多，在virtualenv中处理依赖问题，你只需要运行：

```sh
pip insatll -r requirements.txt
```

但是当你面对更加复杂的应用程序时，例如，一个依赖C语言库的应用（如[libxml2](http://www.xmlsoft.org/)或[PyZMQ](https://zeromq.github.io/pyzmq/)），Docker将会为你节省不少依赖库的安装步骤，而且，对于C库的依赖，与操作系统关联性更大，这就不是virtualenv能解决的了。

更重要的是，Docker是史上第一个似乎每个人都认同的容器技术，它优雅的标准化格式能被各个平台兼容，如Heroku，Google AppEngine或者你个人的服务器上。

我们可以预见到DevOps社区将会逐渐地使用Docker来作为标准化部署的重要一环。

### 更多推荐阅读
- Docker 官方博客 [https://blog.docker.com/](https://blog.docker.com/)
- CircleCI上的Docker博客 [http://blog.circleci.com/its-the-future/](http://blog.circleci.com/its-the-future/)
- Sirupsen上的Docker博客 [http://sirupsen.com/production-docker/](http://sirupsen.com/production-docker/)
