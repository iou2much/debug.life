title: 【译文】Java项目与Docker 
date: 2016-02-01 12:50:23
tag:
  - Docker
toc: true
description: 本文将介绍如何把Java应用进行Docker化
category: Translation
---

### 用Docker重新定义Java虚拟化

[Docker](https://www.docker.com/)是一个用于构建、分发、运行分布式应用的开源平台。Docker化的应用可以在开发者的电脑上运行，并能够被部署到生产的云环境中，Docker正以前所未有的方式在持续集成和持续部署中发挥着巨大作用，总之，Docker这个平台是每个开发者都应该熟悉的。

**开源Java项目** 把Docker带来给Java开发者，我会解释为什么Docker对Java开发者那么重要，引导你们在Docker中安装并部署Java应用，并让你们看到如何把Docker集成到构建流程中。

> #### Docker技术快速指南
> Docker有它自己的术语，这些术语我会在本文中反复到用，请先花一些时间去熟悉它们：
> * **Docker引擎(Docker engine)**：在服务器上的一个守护进程，它是你和Docker应用与所依赖的操作系统的桥梁。
> * **Dockerfile**: 一个文本文件，内容是用于构建Docker镜像的指令。
> * **Docker 镜像**:  构建一个Dockerfile的产物，构建过程中执行Dockerfile中的命令，会生成一个镜像。.它首先会基于一个根系统构建，然后安装应用，接着执行一系列命令来准备启动应用的环境。Docker镜像作为Docker容器的基础，相当于容器的一个静态模块。
> * **Docker 容器**: 一个Docker镜像的运行时实例，Docker镜像类似于模块的概念（从Dockerfile构建，这个Dockerfile包含了根系统，应用以及一系列构建镜像的命令），容器是那个镜像的一个实际能运行的实例。
> * **Docker 宿主** : 一个物理机或者虚拟机，在此系统上运行着Docker引擎，维持着容器所依赖的Dockerhub。 
> * **DockerHub** : 官方的Docker镜像仓库，把DockerHub想象为GitHub仓库，对于Git来说是中央仓库，DockerHub是官方保存及提供Docker镜像的中央仓库。

### Docker简介
在二十多年前，软件应用曾经是非常庞大并且复杂的，会被部署在大型的计算机上。在Java的世界里边，我们开发的企业软件包(EAR)中，包含企业JavaBean(EJB)和web组件(WAR)，然后会部署在大型应用服务器上。为了能尽量有效地利用这些大型计算机上的资源，我们会尽最大能力去设计这些应用。

在21世纪早期，随着云计算的出现，开发者们开始使用虚拟机以及服务器集群，去扩展应用以满足需求。要以虚拟化的方式部署应用，应用必须被设计得与传统方式有所不同，轻量级，面向对象的应用成为新标准。我们学会了把软件成各种能互联的服务集合，将各组件尽可能地设计成无状态。可扩展架构的概念和实现都发生了变化，不再是依赖于单台大型计算机的垂直扩展，开发者和架构师开始思考以水平扩展方式实现：如何把单个应用部署到数个轻量级的计算机上。

Docker的出现使虚拟化更向前了一步，提供了一个轻量级的层处于应用和所依赖的硬件中间，Docker把应用当作是宿主系统的一个进程来运行。图一对比了传统虚拟机和Docker。

![图1Comparing a VM to Docker](http://images.techhive.com/images/article/2015/11/docker-fig01-100625728-large.idge.png)
图 1. 虚拟机与Docker的比较

传统的虚拟机会在宿主系统运行着一个虚拟机监视器，并在虚拟机中运行着一个完整的客户系统，应用依赖的所有包都在客户系统中。

Docker，相反地，有个Docker引擎，也是一个运行在宿主系统的守护进程。Docker引擎把Docker容器中的系统调用，翻译成宿主系统的原生调用。一个Docker镜像，作为Docker容器的创建模板，只是包含了操作系统的最小层，以及仅仅是应用所需要的依赖库。

这些差异似乎不大，但实际上却是天差地别。

#### 理解进程虚拟化

我们仔细分析一下虚拟机中的操作系统，我们会留意到虚拟机中的资源，例如CPU和内存。但当我们运行一个Docker容器，我们会直接看到宿主机上的资源。我把Docker看成是进程级的虚拟化平台，而不是系统级的虚拟化平台。基本上，应用是作为一个独立的自包含进程运行在宿主机上，Docker通过借助着Linux上几个强大的组件，实现了隔离性，确保了每个进程都是操作系统上的独立进程。

因为Docker化的应用与宿主机上的进程运行方式类似，所以设计上也和虚拟机中的应用不同。举个例子说，我们通常会在一个虚拟机上运行Tomcat和MySQL数据库，但Docker的实践中，我们会把app服务器与数据库分别部署，各自运行在不同的容器中。这样让Docker更好地管理宿主系统上的独立单元，这意味着要更有效率地使用Docker，我们需要以适当的粒度设计应用，例如微服务的方式。

#### Docker中的微服务
简单来说，微服务是一种可以促进系统模块化的架构方式。在微服务架构中，复杂的应用帽更小的独立进程组成，各个进程有一个或多个特定的功能，用与语言无关的API和其他进程通信。

微服务是通过粒度非常小，高度解耦的服务集合，来提供单一或多个相关联的功能。例如，如果你正在管理着一个用户中心和购物车，那你很可能是选择把它们设计成独立的服务，如用户中心服务和购物车服务；而不是把两个模块打成一个包作为一个服务运行。更具体来说，使用微服务意味着构建web services，而且是最常见的[RESTful web service](http://www.javaworld.com/article/2077920/soa/java-app-dev-rest-for-java-developers-%20part-1-it-s-about-the-information-stupid.html) ，并把它们按功能分组。在Java中，我们会把这些服务打成WAR包，并部署到一个容器中，例如Tomcat，然后运行Tomcat和Docker容器中的服务。

### 安装Docker
在我们深入研究Docker之前，先让我们把本地环境搭建起来。如果你正在使用Linux系统，那非常好，你可以直接安装并运行Docker。对于那些使用Windows或者Mac的用户来说，Docker可以通过一个叫Docker Toolbox的工具来使用，这个工具会安装一个虚拟机(使用Oracle的Virtual Box)，这个虚拟机中会运行着包含Docker守护进程的Linux系统。我们可以使用Docker客户端把指令发送给守护进程处理，注意，你不需要管理这个虚拟机，只要安装这个工具并执行Docker命令行工具即可。

开始从[Mac](http://docs.docker.com/mac/step_one/)，[Windows](http://docs.docker.com/windows/step_one/)，或[Linux](http://docs.docker.com/linux/started/)相应的文档里[下载Docker](http://docs.docker.com/)。

我的电脑是Mac，所以我下载并运行了Mac版的Docker Toolbox安装包，之后我运行了Docker Quickstart终端，这样会启动一个Virtual Box镜像和一个命令行终端。这个安装过程与Windows下的基本相同，更多请参考Windows版的文档。

#### DockerHub: Docker的镜像仓库
我们开始使用Docker之前，先花几分钟去访问一下[DockerHub](https://hub.docker.com/)，这个官方的镜像仓库。浏览一下DockerHub，你会发现上边有数千个镜像，其中包含官方打包的和独立开发者打包的。你会发现有基础系统，如CentOS, Ubuntu, 和 Fedora，或者Java相关的如Tomcat, Jetty等等。你还可以发现几乎所有流行的应用上边都会有，包括MySQL, MongoDB, Neo4j, Redis, Couchbase, Cassandra, Memcached, Postgres, Nginx, Node.js, WordPress, Joomla, PHP, Perl, Ruby等等。在你打算自行构建一个新镜像之前，请确认DockerHub上还没有。
作为一个练习，我们运行一个简单的CentOS镜像，在Docker Toolbox的命令行中输入：

```sh
$ docker run -it centos
```

这个docker命令是你与Docker守护进程的主要接口。run指令告诉Docker去下载并运行指定的镜像(假设在本地还没有这个镜像)。又或者，你可以用pull命令直接下载一个镜像但不运行它。有两个参数：<code>i</code> 会让Docker用交互模式运行，<code>t</code> 会让它创建一个TTY终端。注意非官方的镜像使用既定的格式"用户名/镜像名"，而官方的镜像会省略用户名，所以我们只需要指定"<code>centos</code>"来运行镜像即可。另外，也可以在镜像名后加“:版本号”指定版本号，例如，<code>centos:7</code>。每个镜像默认使用的都是最新版本，当前CentOS最新版本号是7.

在运行<code>$ docker run -it centos </code>之后，你会见到Docker开始下载这个镜像，完成后会见到类似以下的输出：
```sh
$ docker run -it centos
[root@dcd69de89aad /]#    
```
因为我们用了交互模式去运行，它显示了一个root用户的shell命令提示符。查看一下这个系统，然后使用<code>exit</code>退出。

可以用<code>docker images</code>命令来查看系统中已下载好的镜像：
```sh
$ docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
java                        8                   5282faca75e8        4 weeks ago         817.6 MB
tomcat                      latest              71093fb71661        8 weeks ago         347.7 MB
centos                      latest              7322fbe74aa5        11 weeks ago        172.2 MB
```
你可以看到我已经有了最新版的CentOS、Tomcat和Java 8。

#### 在Docker中运行Tomcat
在Docker中启动Tomcat比只是启动系统稍微复杂一点，使用命令：

```sh
$ docker run -d -p 8080:8080 tomcat
```

在这例子中，我们通过"<code>-d</code>"参数把Tomcat启动为一个守护进程，并且把Docker容器中的<code>8080</code>端口映射到Docker宿主机的8080端口(虚拟机系统)，你会看到类似以下的输出：

```
$ docker run -d -p 8080:8080 tomcat
bdbedc47836028b9d1fee3d4a96eee4d89838d7b6b0b4298d9e5a7d117292003
```
这个非常长的十六进制数字是容器的ID，之后我们会用到这个ID。你可以执行<code>docker ps</code>查看正在运行的进程：

```sh
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                    NAMES
bdbedc478360        tomcat              "catalina.sh run"   3 seconds ago       Up 3 seconds        0.0.0.0:8080->8080/tcp   focused_morse
```

你会看到输出中只会显示ID的前12位，因为完整的ID非常长，Docker允许你使用足够能区分出唯一一个容器的ID。例如，你可以使用"bdb"来定位这个容器，因为这三个字母已经足够能区分出这个实例了。要查看Tomcat是否启动成功，可以用tail打印出catalina.out文件，在Docker中，相应地使用<code>docker logs</code>命令，并指定"-f"参数来实时打印出日志：
```sh
$ docker logs -f bdb
09-Sep-2015 02:15:21.611 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server version:        Apache Tomcat/8.0.24
...
09-Sep-2015 02:15:25.137 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in 3188 ms
```
使用**Ctrl-C**来中断打印。

#### 测试

要测试Tomcat，你需要知道Virtual Box虚拟机的地址，启动Docker Quickstart终端时，你可以看到以下输出：

```sh
docker is configured to use the default machine with IP 192.168.99.100
```
或者，你可以查看<code>DOCKER_HOST</code>环境来得到主机IP：

```sh
DOCKER_HOST=tcp://192.168.99.100:2376
```
在浏览器中输入Docker宿主机的URL:
```sh
http://192.168.99.100:8080
```
然后就能看到Tomcat的默认首页了。

在关闭实例前，可以学习用以下几个命令来查看更多信息：
* <code>docker stats 容器ID</code>查看每个容器的CPU，内存及网络 I/O。
* <code>docker inspect 容器ID</code>查看镜像的配置。
* <code>docker info</code>查看Docker宿主机的信息。

然后，可以使用<code>docker stop 容器ID</code>来终止这个Docker容器进程了。

可以通过<code>docker ps</code>来验证Tomcat已经不再运行了，也可以使用<code>docker ps -a</code>来查看历史容器：

```sh
$ docker ps -a
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
bdbedc478360   tomcat  "catalina.sh run"  26 minutes ago  Exited (143) 5 seconds ago   focused_morse
```

这时候，你应该知道怎么在DockerHub上查看镜像，如何下载并运行镜像，如何查看运行中的镜像，如何查看一个容器实例的状态及日志，如何终止一个容器。下面我们集中看看Docker镜像是怎么定义的。


### Dockerfiles

Dockerfile包含了一系列指令，告诉Docker如何去构建一个镜像，它指定了镜像的基点，以及配置镜像的每个细节。以下是一个Dockerfile示例，是CentOS镜像的Dockerfile。

**代码清单1. CentOS Dockerfile**

```sh
FROM scratch
MAINTAINER The CentOS Project <cloud-ops@centos.org> - ami_creator
ADD centos-7-20150616_1752-docker.tar.xz /
# Volumes for systemd
# VOLUME ["/run", "/tmp"]
# Environment for systemd
# ENV container=docker
# For systemd usage this changes to /usr/sbin/init
# Keeping it as /bin/bash for compatibility with previous
CMD ["/bin/bash"]
```

大部分内容是注释，主要有四句命令：
1. <code>FROM scratch</code>：所有Dockerfile都要从一个基础镜像继承，在这个例子中，CentOS镜像是继承于"scratch"镜像，这个镜像是所有镜像的根。这个配置是固定的，表明了这个是Docker的根镜像之一。
2. <code>MAINTAINER ...</code>：<code>MAINTAINER</code>指令指明了镜像的所有者，这个例子中所有者是CentOS Project。
3. <code>ADD centos...tar.xz</code>：<code>ADD</code>指令告诉Docker把指定文件上传到镜像中，如果文件是压缩过的，会把它解压到指定路径。这个例子中，Docker会上传一个CentOS操作系统的Gzip包，并解压到系统的根目录。
4. <code>CMD ["/bin/bash"]</code>：最后，<code>CMD</code>指令告诉Docker要执行什么命令，这个例子中，最后会进入Bourne Again Shell (bash)终端。
现在你知道Docker大概是长什么样子了，接下来再看看Tomcat官方的Dockerfile，图2说明了这个文件的架构。

![图2Tomcat Dockerfile hierarchy Figure 2. Tomcat Dockerfile hierarchy](http://images.techhive.com/images/article/2015/11/docker-fig02-100625731-medium.idge.png)

这个架构未必如你想象中那么简单，但我们接下来会慢慢学习它，其实它是非常有逻辑的。上边已经提过所有Dockerfile的根是<code>scratch</code>，接下来指定的是<code>debian:jessie</code>镜像，这个官方镜像是基于标准镜像构建的，Docker不需要重复发明轮子，每次都创建一个新镜像了，只要基于一个稳定的镜像来继续构建新镜像即可，在这个例子中，<code>debian:jessie</code>是一个官方Debian Linux镜像，就像上边的CentOS一样，它只有三行指令。

**代码清单 2. debian:jessie Dockerfile**

```sh
FROM scratch
ADD rootfs.tar.xz /
CMD ["/bin/bash"]
```

在上图中我们还见到有安装两个额外的镜像，CURL 和 Source Code Management，镜像<code>buildpack-deps:jessie-curl</code>的Dockerfile如清单3所示。

**代码清单 3. buildpack-deps:jessie-curl Dockerfile**

```sh
FROM debian:jessie
RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		wget \
	&& rm -rf /var/lib/apt/lists/*
```

这个Dockerfile中使用<code>apt-get</code>去安装<code>curl</code>和<code>wget</code>，使这个镜像能从其他服务器下载软件。<code>RUN</code>指令让Docker在运行的实例中执行具体的命令，这个例子中，它会更新所有库(<code>apt-get update</code>)，然后执行<code>apt-get install</code>去安装<code>curl</code>和<code>wget</code>。

<code>buildpack-deps:jessie-scp</code>的Dockerfile如清单4所示.

**代码清单 4. buildpack-deps:jessie-scp Dockerfile**

```sh
FROM buildpack-deps:jessie-curl
RUN apt-get update && apt-get install -y --no-install-recommends \
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
	&& rm -rf /var/lib/apt/lists/*
```

这个[Dockerfile](https://github.com/docker-library/buildpack-deps/blob/a0a59c61102e8b079d568db69368fb89421f75f2/jessie/scm/Dockerfile)会安装源码管理工具，例如Git，Mercurial, 和 Subversion。

Java的[Dockerfile](https://github.com/docker-library/java/blob/6f340724d3bc1f9b4385975c5de6bfe15aac8c85%20/openjdk-8-jdk/Dockerfile)会更加复杂些，如清单5所示。

代码清单 5. Java Dockerfile

```sh
FROM buildpack-deps:jessie-scm
# A few problems with compiling Java from source:
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#       really hairy.

RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*
RUN echo 'deb http://httpredir.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list
# Default to UTF-8 file.encoding
ENV LANG C.UTF-8
ENV JAVA_VERSION 8u66
ENV JAVA_DEBIAN_VERSION 8u66-b01-1~bpo8+1
# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
ENV CA_CERTIFICATES_JAVA_VERSION 20140324
RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
		ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
	&& rm -rf /var/lib/apt/lists/*
# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure
# If you're reading this and have any feedback on how this image could be
#   improved, please open an issue or a pull request so we can discuss it!
```
	
简单来说，这个Dockerfile使用了安全参数去执行<code>apt-get install -y openjdk-8-jdk</code>去下载安装Java，而ENV指令配置系统的环境变量。

最后，清单6是Tomcat的[Dockerfile](https://github.com/docker-library/tomcat/blob/9afdd27634a5b847a3b7aa2d611ad5828659d228/8-jre7/Dockerfile)。

代码清单 6. Tomcat Dockerfile

```sh
FROM java:7-jre
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME
# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
	05AB33110949707C93A279E3D3EFE6B686867BA6 \
	07E48665A34DCAFAE522E5E6266191C37C037D42 \
	47309207D818FFD8DCD3F83F1931D684307A10A5 \
	541FBE7D8F78B25E055DDEE13C370389288584E7 \
	61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
	79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
	9BA44C2621385CB966EBA586F72C284D731FABEE \
	A27677289986DB50844682F8ACB77FC2E86E29AC \
	A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
	DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
	F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
	F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.26
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --verify tomcat.tar.gz.asc \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz*
EXPOSE 8080
CMD ["catalina.sh", "run"]
```

严格来说，Tomcat使用了Java 7的父级Dockerfile（默认的最新Java版本是8）。这个Dockerfile设置了<code>CATALINA_HOME</code>和<code>PATH</code>环境变量，然后用<code>mkdir</code>命令新建了<code>CATALINA_HOME</code>目录，<code>WORKDIR</code>指令把当前工作路径更改为<code>CATALINA_HOME</code>，然后<code>RUN</code>指令执行了同一行中一系列的命令：

1. 下载Tomcat压缩包。
2. 下载文件校验码。
3. 验证下载的文件正确。
4. 解压Tomcat压缩包。
5. 删除所有批处理文件（我们是在Linux上运行）。
6. 删除压缩包文件。

把这些命令写在同一行，对应Docker来说就是一条命令，最后Docker会把执行的结果缓存起来，Docker有个策略是检测镜像何时需要重建，以及验证构建过程中的指令是否正确。当一条指令会使镜像更改，Docker会把每个步的结果缓存起来，Docker能把最上一个正确指令产生的镜像启动起来。

<code>EXPOSE</code>指令会让Docker启动一个容器时暴露指定的端口，正如之前我们启动时那样，我们需要告诉Docker哪个物理端口会被映射到容器上(<code>-p</code>参数)，<code>EXPOSE</code>的作用就是这个定义Docker容器端口。最后Dockerfile使用catalina.sh脚本启动Tomcat。


### 简单回顾

用Dockerfile从头开始构建Tomcat是一个漫长的过程，我们总结一下目前为止的步骤：

1. 安装Debian Linux。
2. 安装curl和wget。
3. 安装源码管理工具。
4. 下载并安装Java。
5. 下载并安装Tomcat。
6. 暴露Docker实例的8080端口。
7. 用catalina.sh启动Tomcat。
现在你应该成为一个Dockerfile专家了，下一步我们将尝试构建一个自定义Docker镜像。

### 部署自定义应用到Docker

因为本篇指南主要关注点是如何Docker中部署Java应用，而不是应用本身，我会构建一个简单的Hello World servlet。你可以从[GitHub](https://github.com/ligado/hello-world-servlet)获取到这个项目，源码并无任何特别，只是一个输出"Hello World!"的servlet。更加有趣的是相应的[Dockerfile](https://github.com/ligado/hello-world-servlet/blob/master/docker/Dockerfile)，如清单7所示。

代码清单 7. Hello World servlet的Dockerfile

```sh
FROM tomcat
ADD deploy /usr/local/tomcat/webapps
```
可能看起来不大一样，但你应该能理解以上代码的作用是：
* <code>FROM tomcat</code>指明这个Dockerfile是基于Tomcat镜像构建。
* <code>ADD deploy </code>告诉Docker把本地文件系统中的"deploy"目录，复制到Tomcat镜像中的 /usr/local/tomcat/webapps路径 。

在本地使用maven命令编译这个项目：

```sh
mvn clean install
```

这样将会生成一个war包，target/helloworld.war，把这个文件复制到项目的docker/deploy目录(你需要先创建好)，最后你要使用上边的Dockerfile构建Docker镜像，在项目的docker目录中执行以下命令：

```sh
docker build -t lygado/docker-tomcat .
```

这个命令让Docker从当前目录（用点号.表示）构建一个新的镜像，并用"<code>-t</code>"打上标签<code>lygado/docker-tomcat</code>，这个例子中，lygado是我的DockerHub用户名，docker-image是镜像名称(你需要替换成你自己的用户名)。查看是否构建成功你可以执行以下命令：

```sh
$ docker images
REPOSITORY                      TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
lygado/docker-tomcat            latest              ccb455fabad9        42 seconds ago      849.5 MB
```

最后，你可以用以下命令加载这个镜像：

```sh
docker run -d -p 8080:8080 lygado/docker-tomcat
```
这个实例启动之后 ，你可以用以下URL访问（请把URL中的IP替换成你虚拟机的IP）：

```sh
http://192.168.99.100:8080/helloworld/hello
```	
还是那样，你可以用容器的ID来终止这个实例。


#### Docker push

一旦你构建并测试过了你的Docker镜像，你可以把这个镜像推送到你DockerHub的账号中：
```sh
docker push lygado/docker-tomcat
```
这样，你的镜像就能被全世界访问到了，当然，为了隐私起见，你也可以推送到私有的Docker仓库。
下面，我们将把Docker集成到应用的构建过程，目标是在构建应用完成后，会产出一个包含应用的Docker镜像。

### 把Docker集成到Maven构建过程

在前边的部分，我们创建了一个自定义的Dockerfile，并把WAR包部署到它里边。这样意味着把WAR包从项目的target目录，复制到<code>docker/deploy</code>目录下，并且从命令行中运行docker。这并没花多少功夫，但如果你需要频繁的改动并测试代码，你会发现这个过程很烦琐。而且，如果你需要在一个CI服务器上构建应用，并产出一个Docker镜像，那你需要弄明白怎样把Docker和CI工具整合起来。

现在我们尝试一种更有效的方法，使用Maven和Maven Docker插件来构建一个Docker镜像。

 在网上，有几种Maven插件可以集成Docker，但基于本文的目标，我选择了[rhuss/docker-maven-plugin](https://github.com/rhuss/docker-maven-plugin)。然而这并不是经过全面的比较，并不一定适合于所有场景，插件作者Roland Huss有一篇[文章](https://github.com/rhuss/shootout-docker-maven)详细对比了同类产品的优劣，我推荐你可以阅读一下，来决定最适合你用的Maven Docker插件。

我的用例有这些：
1. 能创建基于Tomcat的Docker镜像，以用于部署我的应用。
2. 能在测试中自行构建。
3. 能整合到前期集成测试和后期集成测试。

docker-maven-plugin能满足这些需求，而且易于使用和理解。


#### 关于 Maven Docker插件

这个插件本身有良好的[文档](https://github.com/rhuss/docker-maven-plugin/blob/master/doc/manual.md)，这里特别说明一下两个主要的组件：

1. 在POM.xml中配置Docker镜像的构建和运行。
2. 描述哪些文件要包含在镜像中。

清单8是POM.xml中插件的配置，定义了镜像的构建和运行的配置。

**代码清单 8. POM 文件的 build 小节， Docker Maven plug-in 配置**

```xml
<build>
   <finalName>helloworld</finalName>
     <plugins>
       <plugin>
         <groupId>org.jolokia</groupId>
         <artifactId>docker-maven-plugin</artifactId>
         <version>0.13.4</version>
         <configuration>
            <dockerHost>tcp://192.168.99.100:2376</dockerHost>                                         <certPath>/Users/shaines/.docker/machine/machines/default</certPath>
                <useColor>true</useColor>
                   <images>
                     <image>
                       <name>lygado/tomcat-with-my-app:0.1</name>
                       <alias>tomcat</alias>
                       <build>
                          <from>tomcat</from>
                          <assembly>
                          <mode>dir</mode
                          <basedir>/usr/local/tomcat/webapps</basedir
                          <descriptor>assembly.xml</descriptor>
                                        </assembly>
                                </build>
                                <run>
                                        <ports>
                                           <port>8080:8080</port>
                                        </ports>
                                </run>
                        </image>
                   </images>
                </configuration>
            </plugin>
        </plugins>
  </build>    
```


正如你所见，这个配置相当简单，包含了以下元素：

#### Plug-in定义
<code>groupId</code>, <code>artifactId</code> 和 <code>version</code> 这些信息指定要用哪个插件。

#### 全局设置
<code>dockerHost</code>和<code>certPath</code>元素，定义了Docker主机的位置，这些配置会用于启动容器，以及指定Docker证书。Docker证书的路径在<code>DOCKER_CERT_PATH</code>环境变量中能看到。

#### 镜像设置
在<code>build</code>元素下的所有<code>image</code>元素都定义在<code>images</code>元素下，每个<code>image</code>元素都有镜像相关的配置，与<code>build</code>和<code>run</code>的配置一样，主要的配置是镜像的名称，在这个例子中，是我的DockerHub用户名(<code>lygado</code>)，镜像的名称(<code>tomcat-with-my-app</code>)和镜像的版本号(0.1)。你也可以用Maven的属性来定义这些值。

#### 镜像构建配置
一般构建镜像时，我们会使用<code>docker build</code>命令，以及一个Dockerfile来定义构建过程。Maven Docker插件也允许你使用Dockerfile，但在例子中，我们使用一个运行时生成在内存中的Dockerfile来构建。因此，我们在<code>from</code>元素中定义父级镜像，这个例子中是tomcat，然后在<code>assembly</code>中作其他配置。

使用Maven的<code>maven-assembly-plugin</code>，可以定义一个项目的输出内容，指定包含依赖，模块，文档，或其他文件到一个独立分发的包中。<code>docker-maven-plugin</code>继承了这个标准，在这个例子中，我们选择了<code>dir</code>模式，也就是说定义在<code>src/main/docker/assembly.xml</code>中的文件会被拷贝到Docker镜像中的basedir中。其他模式还有<code>tar</code>，<code>tgz</code>和<code>zip</code>。<code>basedir</code>元素中定义了放置文件的路径，这个例子中是Tomcat的webapps目录。

最后，<code>descriptor</code>元素指定了<code>assembly</code>文件，这个文件位于<code>basedir</code>中定义的<code>src/main/docker</code>中。以上是一个很简单的例子，我建议你通读一下相关文档，特别地，可以了解<code>entrypoint</code>和<code>cmd</code>元素，这两个元素可以指定启动Docker镜像的命令，<code>env</code>元素可以指定环境变量，<code>runCmds</code>元素类似Dockerfile中的<code>RUN</code>指令，<code>workdir</code>元素可以指定工作路径，<code>volumes</code>元素可以指定要挂载的磁盘卷。简言之，这个插件实现了所有Dockerfile中所需要的语法，所以前面所用到的Dockerfile指令都可以在这个插件中使用。

#### 镜像运行配置
启动Docker镜像时会用到<code>docker run</code>命令，你可以传一些参数给Docker。这个例子中，我们要用<code>docker run -d -p 8080:8080 lygado/tomcat-with-my-app:0.1</code>这个命令启动镜像，所以我们只需要指定一下端口映射。

run元素可以让我们指定所有运行时参数，所以我们指定了把Docker容器中的8080映射到Docker宿主机的8080。另外，还可以在run这节中指定要挂载的卷(使用<code>volumes</code>)，或者要链接起来的容器(使用<code>links</code>)。<code>docker:start</code>在集成测试中很常用，在run小节中，我们可以使用wait参数来指定一个时间周期，这样就可以等待到某个日志输出，或者一个URL可用时，才继续执行下去，这样就可以保证在集成测试开始前镜像已经运行起来了。

#### 加载依赖

<code>src/main/docker/assembly.xml</code>文件定义了哪些文件需要复制到Docker镜像中，如清单9所示：
**清单 9. assembly.xml**

```xml
<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.2 http://maven.apache.org/xsd/assembly-1.1.2.xsd">
  <dependencySets>
    <dependencySet>
      <includes>
        <include>com.geekcap.vmturbo:hello-world-servlet-example</include>
      </includes>
      <outputDirectory>.</outputDirectory>
      <outputFileNameMapping>helloworld.war</outputFileNameMapping>
    </dependencySet>
  </dependencySets>
</assembly>
```
在清单 9 中，我们可以看到包含<code>hello-world-servlet-example</code>在内的一个依赖集合，以及复制的目标路径，<code>outputDirectory</code>这个路径是相对于前面提到的<code>basedir</code>的，也就是Tomcat的webapps目录。

这个插件有以下几个Maven targets：
1. docker:build:  构建镜像
2. docker:start: 启动镜像
3. docker:stop: 停止镜像
4. docker:push: 把镜像推送到镜像仓库，如DockerHub
5. docker:remove: 本地删除镜像
6. docker:logs: 输出容器日志

#### 构建镜像
你可以从[GitHub](https://github.com/ligado/hello-world-servlet)中获取源码，然后用下边的命令构建：
```sh
mvn clean install
```
用以下命令构建Docker镜像：
```sh
mvn clean package docker:build
```
一旦镜像构建成功，你可以在<code>docker images</code>的返回结果中看到：
```sh
$ docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
lygado/tomcat-with-my-app   0.1                 1d49e6924d19        16 minutes ago      347.7 MB    
```
可以用以下命令启动镜像：

```sh
mvn docker:start
```
现在可以在<code>docker ps</code>中看到已经启动了，然后可以通过以下URL访问：
```sh
http://192.168.99.100:8080/helloworld/hello
```
最后，可以用以下命令停止容器：
```sh
mvn docker:stop
```
### 总结

Docker是一种使进程虚拟化的容器技术，它提供了一系列Docker客户端命令来调用Docker守护进程。在Linux上，Docker守护进程可以直接运行于Linux操作系统，但是在Windows和Mac上，需要有一个Linux虚拟机来运行Docker守护进程。Docker镜像包含了一个轻量级的操作系统，还额外包含了应用运行的依赖库。Docker镜像由Dockerfile定义，可以在Dockerfile中包含一系列配置镜像的指令。

在这个开源Java项目指南中，我介绍了Docker的基础，讲解了CentOS、Java、Tomcat等镜像的Dockerfile细节，并演示了如果用Tomcat镜像来构建新的镜像。最后，我们使用docker-maven-plugin来把Docker集成到Maven的构建过程中。通过这样，使得测试更加简单了，还可以把构建过程配置在CI服务器上部署到生产环境。

本文中的示例应用非常简单，但是涉及的构建步骤同样可以用在更复杂的企业级应用中。好好享受Docker带给我们的乐趣吧。


