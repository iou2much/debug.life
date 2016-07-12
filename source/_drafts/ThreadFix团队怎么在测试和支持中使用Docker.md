# ThreadFix团队怎么在质量控制和技术支持中使用Docker

ThreadFix的技术团队发现他们经常要面临一些非常通用的问题：如何快速构建应用实例。从开发部门到质量控制部门都有这个需求，因为它带来的好处非常明显，能让用户用上最新同时也是最稳定的代码版本。我们基于Docker构建的容器系统（我们内部称为"ThreadFix + Docker"），使实现这个需求前所未有的简单。


![pic](http://www.denimgroup.com/blog/wp-content/uploads/2016/01/DockerBlog1.png)


## 组件
这小节会概述一下“ThreadFix + Docker”系统的组件。

### Docker以及Docker守护进程

这个系统最不可或缺的一块就是Docker守护进程，这个进程部署在一个远程Ubuntu虚拟机上，它和相关的文件组成了"ThreadFix + Docker"的后端。

简单来说，Docker就是一个工具，能让我们动态地生成容器，或者说是能与系统进程空间共存的轻量独立进程空间。这让我们能不用在全虚拟化的虚拟机中部署独立的ThreadFix实例，也就是说虚拟机相关的负载也可以省了下来。

Docker守护进程运行在宿主虚拟机上，等待着指令来创建新的容器，当它接收到相应的指令，它就会以一个镜像作为模板来创建新的容器。Docker镜像代表容器一启动时就会拥有的系统环境，而镜像又是通过一个面向过程的配置脚本来生成（称为"Dockerfile")，这套系统能非常迅速地启动一个开箱即用的容器。我们会在本文的“Jenkins持续集成“小节中讲到这部分内容。

这是一个简单的Dockerfile。

```sh
FROM tomcat:7.0.65-jre7
ADD ./threadfix /usr/local/tomcat/webapps/threadfix
LABEL branch="Dev-QA"
LABEL version="Enterprise"
```
这是"ThreadFix + Docker"界面上的可用镜像列表，以及各自的创建时间：

![pic2](http://www.denimgroup.com/blog/wp-content/uploads/2016/01/DockerBlog2.png)

### Docker API
Docker提供了一套REST风格的API，通过简单的配置修改，我们把Docker守护进程的API暴露在虚拟机上的Unix端口上，“ThreadFix + Docker”中有两个组件会通过这个通道与Docker进程通讯。


### 管理Shell脚本
我们有一个交互式shell脚本，用来与虚拟机中的Docker进程通讯，从而实现创建或者杀死容器，由于这个脚本中是使用Unix的<code>curl</code>程序来调用Docker的REST接口，所以这个脚本也能在用户的机器上运行，而不一定必须从宿主机上运行。这个脚本可以指定这些参数：

- 显示容器的名称(用于AngularJS界面）
- ThreadFix的git版本和分支(社区版或企业版，开发版或稳定版，等等)
- 虚拟机暴露出来的端口
- ThreadFix实例要用到的数据库文件
- 要调用的数据库操作(创建 或者 更新）

![pic3](http://www.denimgroup.com/blog/wp-content/uploads/2016/01/DockerScript.png)

### 轻量的AngularJS客户端
终端用户主要会用到的“ThreadFix + Docker”组件是web界面，这个页面是由AngularJS构建的，它会直接调用GET请求与Docker进程通讯，从而获取到Docker中可用镜像和容器的相关信息。

对每个运行中的容器来说，都有一个链接是带有ThreadFix实例的映射端口，用户访问这些链接会跳转到具体某个ThreadFix实例首页。
另外，还有一个链接是可以查看那个容器的运行日志，这对于测试团队来说是非常方便的，能简化发现以及重现问题的流程。
最后，警告图标会告诉用户容器还没构建，他们所使用的镜像和代码很可能不是最新的。

![pic4](http://www.denimgroup.com/blog/wp-content/uploads/2016/01/DockerIcons.png)

更有趣的是，ThreadFix + Docker的Web界面它本身也运行在一个容器中。

![pic5](http://www.denimgroup.com/blog/wp-content/uploads/2016/01/DockerBlog4.png)

### Jenkins持续集成

拼图上最后一块是把我们现有的Jenkins持续集成任务也整合到这套系统中，我们利用了现有的CI任务，特别是那些会在代码更改后构建ThreadFix包，以及会作单元测试来验证代码质量的任务，这些任务被修改成了把构建好的包复制到Docker运行着的虚拟机中，然后运行脚本去构建新的Docker镜像，并指定特定的ThreadFix版本号。这样的话，当用户操作一个ThreadFix实例时，他们就能确保是正在使用由最新代码所构建的镜像。

## 背后原理
现在我们将讨论一下ThreadFix + Docker背后的进程，当一个ThreadFix容器被管理脚本创建，在界面上将能调用REST API来配置一些运行时参数。

作为参数传进脚本的端口号，会把在容器内的ThreadFix 应用8080端口，映射到宿主虚拟机上，这样实现了用户通过不同端口同时访问他们的实例。

ThreadFix 的版本和分支(社区版或企业版，开发版或稳定版，等等)让Docker进程知道启动容器时应该使用哪个镜像，正如上边所说，Jenkins任务会确保这些镜像是最新构建的。


数据库名称参数会在虚拟宿主机上查找同名的目录，如果这个目录不存在将会被创建。ThreadFix容器会关联这个目录作为“卷”，挂载容器中的一个路径到这个卷上。在Docker术语中，一个“卷”是宿主机上的文件路径，这个路径会被映射到容器中的一个路径上。我们的ThreadFix应用利用了这个特性，应用中把生成的HSQL数据库文件放在卷中，这样的话，当这个容器以新的镜像启动，只要关联回这个卷上，那数据仍然是完整的。

数据库操作参数同样也是利用了卷的特性，如果你指定“创建”操作，ThreadFix + Docker会替换默认的jdbc.properties文件，类似地，“更新”会使用一个“update. jdbc.properties“文件来建立数据库连接。

最后，一定要记得ThreadFix + Docker并没有用到独立的后端，而是直接与Docker进程通讯了。要存储容器的元数据，我们依赖于Docker的“标签"，这些键值对可以生成镜像前在Dockerfile中指定，然后你们在Web界面上看到这些信息，诸如容器名称、版本、分支等等。

管理脚本打印出来的创建容器结果是一串Json，以下是一段摘要：

```json
# Craft JSON Data for Create Call
json="{\"OpenStdin\": true,  \"Image\": \"threadfix/${version}\", \"Tty\": true, \"Labels\": {\"user\":\"${name}\", \"db\": \"${database}\", \"dbMethod\": \"${dbMethod}\"},\"HostConfig\": {${databaseJson} \"PortBindings\": { \"8080/tcp\": [{ \"HostPort\": \"${port}\" }]}, \"DnsSearch\": [\"denimgroup.com\"]}}"
```


### 总结

上边我们介绍了ThreadFix + Docker系统的各个组件，我们另外还遇到另一些用例，也是希望能通过Docker来提升我们的效率的，例如在一个远程ThreadFix容器中连接一个本地Mysql数据库，或者运行一个SQL Server数据库实例来作数据库驱动测试。

就目前来说，ThreadFix + Docker已经显著地减少了我们的构建时间，并且提高了我们产品的鲁棒性，使有时需要10分钟的工作量变成了现在的30秒。无论是开发第三方集成应用，排查问题，跟踪缺陷或者使新成员快速上手，Docker带给我们的好处不止上边这些。