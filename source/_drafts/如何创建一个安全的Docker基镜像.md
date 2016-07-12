# 如何创建一个安全的Docker基镜像


## 背景
我最初使用Docker的时候，每个人都在说它用起来有多简单方便，它内部的机制是有多么好，它为我们节省了多少时间。但是当我一使用它就发现，几乎所有镜像都是臃肿而且不安全的（没有使用包签名，盲目相信上游的镜像库以<code>curl | sh</code>的方式安装)，而且也没有一个镜像能实现Docker的初衷：隔离，单纯种，容易分发，简洁。


Docker镜像本来不是为了取代复杂的虚拟机而设计的，后者有完整的日志、监控、警报和资源管理模块。而Docker则倾向于从<code>cgroups</code>和<code>namespaces</code>抽象出相应的内核模块。

> 容器启动后的状态与内核完成初始化，init进程启动完成时的基础环境一样。

> 这也是为什么当你在Dockerfile的<code>CMD</code>指令启动的进程PID是1，这是与Unix中的进程机制类似的。

现在请查看一下你的进程列表，使用<code>top</code>或者<code>ps</code>，你会看到<code>init</code>进程占用的也是这个PID，这是每个类Unix系统的核心进程，所有进程的父级进程，一旦你理解这个概念：在类Unix系统上每个进程都是init进程的子进程，你会理解Docker容器应该是仅仅包含内核的扁平化环境，它应该是刚好满足进程运行需要。


## 如何开始

现在的应用多数是大型复杂的系统，通常都需要很多依赖库，例如有调度，编译和很多其他相关工具类应用，它们的架构通常封装性良好，通过一层层的抽象和接口把底层细节隐藏了，从某种程度上说，这也算是一种容器，但是从系统架构视角看，我们需要一种比以往虚拟环境更简单的方案了。


### 以Java为例

从零开始，思考你要构建一个最通用的基础容器，想想你的应用本身，它运行需要什么？

可能性有很多，如果你要运行Java应用，它需要Java运行时；如果运行Rails应用，它需要Ruby解释器，对Python应用也一样。Go和其他一些编译型语言有些许不同，我以下会提到。

在Java例子中，下一步要想的是：JRE需要什么依赖才能运行？因为它是让应用能运行的最重要的组件，所以很自然的下一步就是要想清楚JRE运行依赖于什么。

而实际上JRE并没太多依赖，它本来就是作为操作系统的抽象层，使代码不依赖于宿主系统运行，因此安装好JRE就基本准备就绪了。

（实际上，对操作系统的独立性并不是理所当然的事，有非常多的系统特有API和专有的系统扩展，但是便于举例，我们把注意力放在简单的情况下）

我将在Linux x86_64系统上演示这个例子，虽然Java理论上是支持跨平台运行，但是Docker，这个容器引擎并不能，它还是只能运行在Linux上。（译者：目前在最新的Windows Server上也能运行Docker)

在Linux上，JVM主要是调用系统的C语言库，Oracle的官方JRE，使用的是libc，也就是glibc，这意味着你要运行任何Java程序，都需要先装好glibc。另外你可能需要某种shell来管理环境，还有一个与外部通讯的接口，例如网络和资源的接口。

我们总结一下Java应用示例需要的最低配置是：

- JRE，在例子中我们使用Oracle JRE
- glibc，JRE的依赖
- 一个基础环境（包含网络、内存、文件系统等资源管理工具）

## 走进Alpine Linux

Alpine Linux最近得到很多关注，主要是因为它打包了一系列的经过验签的可信任的依赖，并且还保持体积在2MB！而在本文发布时，其他的一些镜像分发版如下：

- ubuntu:latest: 66MB (已经瘦身了非常多了，以前有些版本超过600MB)
- debian:latest: 55MB (同上，一开始是200MB以上的）
- arch:latest: 145MB 
- busybox:latest: 676KB (是的！KB，我稍后会讨论它)
- alpine:latest: 2MB (2MB，包含一个包管理工具的Linux系统)

我不会深入探究Alpine Linux是什么和它为什么诞生，[这些文章](https://www.alpinelinux.org/about/)解释得非常清楚。
 

### Busybox是最小的竞争者？

从上边的对比中你可以看到，在体积上唯一能打败Alpine Linux的是Busybox，所以现在几乎所有嵌入式系统都是使用它，它被应用在路由器，交换机，ATM，或者你的吐司机上。它作为一个最最基础的环境，但是又提供了足够容易维护的shell接口。

在网上有很多文章解释了为什么人们会选择Alpine Linux而不是Busybox，我在这总结一下：

- 开放活跃的软件包仓库：Alpine Linux使用apk包管理工具，它集成在Docker镜像中，而Busybox你需要另外安装一个包管理器，例如opkg，更甚者，你需要寻找一个稳定的包仓库源（这几乎没有），Alpine的包仓库中提供了大量常用的依赖包，例如，如果你仍然需要在容器中编译NodeJS或Ruby之类的代码，你可以直接运行apk来添加nodejs和ruby，这在几秒内便可以完成。
- 体积确实重要，但是当你在功能性，灵活性，易用性和1.5MB之间衡量，体积就不那么重要了，Alpine上添加的包使这些方面都大大增强了。
- 广泛的支持：Docker公司已经聘请了Alpine Linux的作者来维护它，所有官方镜像，在以后都将基于Alpine Linux来构建。没有比这个更有说服力的理由去让你在自己的容器中使用它了吧。

## 构建一个Java环境基镜像
正如我刚解释的，Alpine Linux是一个构建自有镜像时不错的选择，因此，我们在此将使用它来构建简洁高效的Docker镜像，我们开始吧!


### 组合：Alpine + bash

每个Dockerfile第一个指令都是指定它的父级容器，通常是用于继承，在我们的例子中是<code>alpine:latest</code>:


```sh
FROM alpine:latest
MAINTAINER Moritz Heiber <hello@heiber.im>
```

我们同时声明了谁为这个镜像负责，这个信息对上传到Docker Hub的镜像是必要的。

就这样，你就有了往下操作的基础，接下来安装我们选好的shell,把下边的命令加上：


```sh
RUN apk add --no-cache --update-cache bash
CMD ["/bin/bash"]
```
最终的Dockerfile是这样：

```sh
FROM alpine:latest
MAINTAINER Moritz Heiber <hello@heiber.im> # You want to add your own name here

RUN apk add --no-cache --update-cache bash
CMD ["/bin/bash"]
```

好了，现在我们构建容器：

```sh
$ docker build -t my-java-base-image .
Sending build context to Docker daemon 2.048 kB
Step 1 : FROM alpine:latest
 ---> 2314ad3eeb90
Step 2 : MAINTAINER Moritz Heiber <hello@heiber.im>
 ---> Running in 63433312d77e
 ---> bfe94713797a
Removing intermediate container 63433312d77e
Step 3 : RUN apk --no-cache --update-cache add bash
 ---> Running in 12ae43605260
fetch http://dl-4.alpinelinux.org/alpine/v3.3/main/x86_64/APKINDEX.tar.gz
fetch http://dl-4.alpinelinux.org/alpine/v3.3/main/x86_64/APKINDEX.tar.gz
fetch http://dl-4.alpinelinux.org/alpine/v3.3/community/x86_64/APKINDEX.tar.gz
fetch http://dl-4.alpinelinux.org/alpine/v3.3/community/x86_64/APKINDEX.tar.gz
(1/5) Installing ncurses-terminfo-base (6.0-r6)
(2/5) Installing ncurses-terminfo (6.0-r6)
(3/5) Installing ncurses-libs (6.0-r6)
(4/5) Installing readline (6.3.008-r4)
(5/5) Installing bash (4.3.42-r3)
Executing bash-4.3.42-r3.post-install
Executing busybox-1.24.1-r7.trigger
OK: 13 MiB in 16 packages
 ---> 2ea4fbc1c950
Removing intermediate container 12ae43605260
Step 4 : CMD /bin/bash
 ---> Running in d2291684b797
 ---> ecc443d68f27
Removing intermediate container d2291684b797
Successfully built ecc443d68f27
```

并且运行它：

```sh
$ docker run --rm -ti my-java-base-image
bash-4.3#
```

成功了！我们有了一个运行着bash的Alpine Linux。


### glibc and friends
前边提到，Oracle的JRE依赖于glibc，Alpine Linux上并没有glibc，它使用一个更小体积的替代版,叫musl libc。glibc发展了这么多年，几乎包含了所有C语言中需要的依赖包，显然这样会很不灵活，一个glibc库被编译进Alpine Linux，勉强能维持在5MB的体积，而它的替代者musl-libc是一个二进制文件，只有897KB，并且支持了所有Linux架构上的C依赖。

对Oracle的JRE，没有办法不把glibc加上，幸运的是，Andy Shinn已经做过了这些，他提供了一个预编译的glibc镜像给Alpine Linux，在Github上的alpine-pkg-glibc，最新版是2.23-r1。

这样把这相关依赖加到Dockerfile中：


```sh
ENV GLIBC_PKG_VERSION=2.23-r1

RUN apk add --no-cache --update-cache curl ca-certificates bash && \
  curl -Lo /etc/apk/keys/andyshinn.rsa.pub "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/andyshinn.rsa.pub" && \
  curl -Lo glibc-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-bin-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-bin-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-i18n-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-i18n-${GLIBC_PKG_VERSION}.apk" && \
  apk add glibc-${GLIBC_PKG_VERSION}.apk glibc-bin-${GLIBC_PKG_VERSION}.apk glibc-i18n-${GLIBC_PKG_VERSION}.apk && \
```

现在我们的Dockerfile看起来是这样：


```sh
FROM alpine:latest
MAINTAINER Moritz Heiber <hello@heiber.im>

ENV GLIBC_PKG_VERSION=2.23-r1

RUN apk add --no-cache --update-cache curl ca-certificates bash && \
  curl -Lo /etc/apk/keys/andyshinn.rsa.pub "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/andyshinn.rsa.pub" && \
  curl -Lo glibc-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-bin-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-bin-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-i18n-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-i18n-${GLIBC_PKG_VERSION}.apk" && \
  apk add glibc-${GLIBC_PKG_VERSION}.apk glibc-bin-${GLIBC_PKG_VERSION}.apk glibc-i18n-${GLIBC_PKG_VERSION}.apk

CMD ["/bin/bash"]
```

我们一句句解释一下这些指令：


```sh
ENV GLIBC_PKG_VERSION=2.23-r1
```

我们通过变量指定GitHub上的glibc版本，所以每当一个新版本发布，都不需要更改URL，而直接更改这个变量即可。



```sh
RUN apk add --update-cache curl ca-certificates bash && \
```
这个指令会使用apk命令安装我们需要的包，包括curl和ca-certificates（以便使用TLS的页面），最后的bash是我们Dockerfile上个版本已经有的了。


```sh
  curl -Lo /etc/apk/keys/andyshinn.rsa.pub "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/andyshinn.rsa.pub" && \
  curl -Lo glibc-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-bin-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-bin-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-i18n-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-i18n-${GLIBC_PKG_VERSION}.apk" && \
```

这些命令会接着刚刚的RUN指令，它们会从GitHub下载相关公钥和依赖包。

```sh
  apk add glibc-${GLIBC_PKG_VERSION}.apk glibc-bin-${GLIBC_PKG_VERSION}.apk glibc-i18n-${GLIBC_PKG_VERSION}.apk
```
所有包下载完成后，我们会用这一行命令安装全部，由于我们之前添加了公钥，所以它们的签名会被验证。

好了！我们现在有了一个能运行几乎全部依赖于glibc包的环境。


### Java运行环境

一般来说，Oracle不提供软件仓库的形式让人们下载，但是人们总是会找到一些方法绕过它，你可以使用以下命令把JRE添加到Docker镜像中：


```sh

ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=73 \
    JAVA_VERSION_BUILD=02 \
    JAVA_PACKAGE=server-jre

WORKDIR /tmp

RUN curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz" | gunzip -c - | tar -xf - && \
  apk del curl ca-certificates && \
  mv jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}/jre /jre && \
  rm /jre/bin/jjs && \
  rm /jre/bin/keytool && \
  rm /jre/bin/orbd && \
  rm /jre/bin/pack200 && \
  rm /jre/bin/policytool && \
  rm /jre/bin/rmid && \
  rm /jre/bin/rmiregistry && \
  rm /jre/bin/servertool && \
  rm /jre/bin/tnameserv && \
  rm /jre/bin/unpack200 && \
  rm /jre/lib/ext/nashorn.jar && \
  rm /jre/lib/jfr.jar && \
  rm -rf /jre/lib/jfr && \
  rm -rf /jre/lib/oblique-fonts && \
  rm -rf /tmp/* /var/cache/apk/* && \
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

ENV JAVA_HOME /jre
ENV PATH ${PATH}:${JAVA_HOME}/bin
```
这堆命令究竟做了什么，我们还是一句句来看一下吧：


```sh
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=73 \
    JAVA_VERSION_BUILD=02 
    JAVA_PACKAGE=server-jre

WORKDIR /tmp
```

这句非常简单，它定义了我们要从Oracle服务器上要下载的软件版本，本文编写时，上边的版本号是最新的，以后可能会变化，你可以从Oracle官网上查看。它同时也指定了<code>WORKDIR</code>工作目录，我们需要从一个临时目录开始运行，所以这里设置了/tmp。


```sh
RUN curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz" | gunzip -c - | tar -xf - && \
```

这句稍微有点复杂，它使用curl传了一个指定的头信息("Cookie: oraclelicense=accept-securebackup-cookie")，以从Oracle上获取真正的下载包，这是必须的，不然会返回一个错误页。然后它会把下载好的包通过管道传给gunzip和tar ，换言之，它并不会保存下载回来的tar包，而是直接解压出来到磁盘上。


```sh
apk del curl ca-certificates && \
```

这时curl和ca-certificates两个包都完成了它们的使命，可以删除了它们以节省空间。


```sh
  rm /jre/bin/jjs && \
  rm /jre/bin/keytool && \
  rm /jre/bin/orbd && \
  rm /jre/bin/pack200 && \
  rm /jre/bin/policytool && \
  rm /jre/bin/rmid && \
  rm /jre/bin/rmiregistry && \
  rm /jre/bin/servertool && \
  rm /jre/bin/tnameserv && \
  rm /jre/bin/unpack200 && \
  rm /jre/lib/ext/nashorn.jar && \
  rm /jre/lib/jfr.jar && \
  rm -rf /jre/lib/jfr && \
  rm -rf /jre/lib/oblique-fonts && \
  rm -rf /tmp/* /var/cache/apk/* && \
```

JRE自带了一些工具包，可能永远都不会用到的，我们也将它们删掉。 最后一行，会把全部临时文件和apk的包缓存也清理了。 

```sh
echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf
```
这一行中，我们修改了nsswitch.conf，以确保网络正常，这会被glibc等包所用到。

最后，我们的Dockerfile会是下边这样：


```sh
FROM alpine:latest
MAINTAINER Moritz Heiber <hello@heiber.im>

ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=73 \
    JAVA_VERSION_BUILD=02 \
    JAVA_PACKAGE=server-jre \
    GLIBC_PKG_VERSION=2.23-r1 \
    LANG=en_US.UTF8

WORKDIR /tmp

RUN apk add --no-cache --update-cache curl ca-certificates bash && \
  curl -Lo /etc/apk/keys/andyshinn.rsa.pub "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/andyshinn.rsa.pub" && \
  curl -Lo glibc-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-bin-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-bin-${GLIBC_PKG_VERSION}.apk" && \
  curl -Lo glibc-i18n-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-i18n-${GLIBC_PKG_VERSION}.apk" && \
  apk add glibc-${GLIBC_PKG_VERSION}.apk glibc-bin-${GLIBC_PKG_VERSION}.apk glibc-i18n-${GLIBC_PKG_VERSION}.apk && \
  curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz" | gunzip -c - | tar -xf - && \
  apk del curl ca-certificates && \
  mv jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}/jre /jre && \
  rm /jre/bin/jjs && \
  rm /jre/bin/keytool && \
  rm /jre/bin/orbd && \
  rm /jre/bin/pack200 && \
  rm /jre/bin/policytool && \
  rm /jre/bin/rmid && \
  rm /jre/bin/rmiregistry && \
  rm /jre/bin/servertool && \
  rm /jre/bin/tnameserv && \
  rm /jre/bin/unpack200 && \
  rm /jre/lib/ext/nashorn.jar && \
  rm /jre/lib/jfr.jar && \
  rm -rf /jre/lib/jfr && \
  rm -rf /jre/lib/oblique-fonts && \
  rm -rf /tmp/* /var/cache/apk/* && \
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

ENV JAVA_HOME=/jre
ENV PATH=${PATH}:${JAVA_HOME}/bin
```
注意这里，我整合了两个ENV和RUN指令，因为最好是用更少的中间层，特别是这个容器是作为通用的构建单元。

简单来说，有一个规则：你需要更大的灵活性，那你需要更多的层；如果你需要减小体积和降低复杂度，你需要更少的层。这完全取决于你的需求。

在顶部我还加上了这句：

```sh
ENV LANG=en_US.UTF-8
```

这句是为了确保运行在这个系统环境的应用能指定语言。你可以根据需要设定这个LANG环境变量。

另外，JAVA_HOME和PATH也要设置好，以使用刚刚装好的JRE。


### CMD指令会怎么运行?

我之前提到，我们这是在构建一个能提供给其他服务作为基础的镜像，它不需要带上CMD指令，因为它永远不会运行，但是一旦一个服务关联上它，就需要用到了。

不过你还是可以通过其他方式启动这个容器，例如<code>docker run</code>或<code>docker exec</code>指令：

```sh
$ docker run --rm -ti my-java-base-image /bin/bash
```


## 构建最终镜像
最后，我们终于到了构建镜像这步了：

```sh
$ docker build -t my-java-base-image .
Sending build context to Docker daemon 60.42 kB
Step 1 : FROM alpine:latest
 ---> 2314ad3eeb90
Step 2 : MAINTAINER Moritz Heiber <hello@heiber.im>
 ---> Using cache
 ---> 93cc2bc0bd60
Step 3 : ENV JAVA_VERSION_MAJOR 8 JAVA_VERSION_MINOR 73 JAVA_VERSION_BUILD 02 JAVA_PACKAGE server-jre GLIBC_PKG_VERSION 2.23-r1 LANG en_US.UTF8
 ---> Running in 3f0ffeaeca78
 ---> 1dcfd34b0f1a
Removing intermediate container 3f0ffeaeca78
Step 4 : WORKDIR /tmp
 ---> Running in 5c81aa8921e0
 ---> 9904a9a1a0af
Removing intermediate container 5c81aa8921e0
Step 5 : RUN apk add --no-cache --update-cache curl ca-certificates bash &&   curl -Lo /etc/apk/keys/andyshinn.rsa.pub "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/andyshinn.rsa.pub" &&   curl -Lo glibc-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-${GLIBC_PKG_VERSION}.apk" &&   curl -Lo glibc-bin-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-bin-${GLIBC_PKG_VERSION}.apk" &&   curl -Lo glibc-i18n-${GLIBC_PKG_VERSION}.apk "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-i18n-${GLIBC_PKG_VERSION}.apk" &&   apk add glibc-${GLIBC_PKG_VERSION}.apk glibc-bin-${GLIBC_PKG_VERSION}.apk glibc-i18n-${GLIBC_PKG_VERSION}.apk &&   curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie"   "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz" | gunzip -c - | tar -xf - &&   apk del curl ca-certificates &&   mv jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}/jre /jre &&   rm /jre/bin/jjs &&   rm /jre/bin/keytool &&   rm /jre/bin/orbd &&   rm /jre/bin/pack200 &&   rm /jre/bin/policytool &&   rm /jre/bin/rmid &&   rm /jre/bin/rmiregistry &&   rm /jre/bin/servertool &&   rm /jre/bin/tnameserv &&   rm /jre/bin/unpack200 &&   rm /jre/lib/ext/nashorn.jar &&   rm /jre/lib/jfr.jar &&   rm -rf /jre/lib/jfr &&   rm -rf /jre/lib/oblique-fonts &&   rm -rf /tmp/* /var/cache/apk/* &&   echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf
 ---> Running in ab3222998627
fetch http://dl-4.alpinelinux.org/alpine/v3.3/main/x86_64/APKINDEX.tar.gz
fetch http://dl-4.alpinelinux.org/alpine/v3.3/main/x86_64/APKINDEX.tar.gz
fetch http://dl-4.alpinelinux.org/alpine/v3.3/community/x86_64/APKINDEX.tar.gz
fetch http://dl-4.alpinelinux.org/alpine/v3.3/community/x86_64/APKINDEX.tar.gz
(1/9) Installing ncurses-terminfo-base (6.0-r6)
(2/9) Installing ncurses-terminfo (6.0-r6)
(3/9) Installing ncurses-libs (6.0-r6)
(4/9) Installing readline (6.3.008-r4)
(5/9) Installing bash (4.3.42-r3)
Executing bash-4.3.42-r3.post-install
(6/9) Installing openssl (1.0.2f-r0)
(7/9) Installing ca-certificates (20160104-r2)
(8/9) Installing libssh2 (1.6.0-r0)
(9/9) Installing curl (7.47.0-r0)
Executing busybox-1.24.1-r7.trigger
Executing ca-certificates-20160104-r2.trigger
OK: 15 MiB in 20 packages
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   594    0   594    0     0   1135      0 --:--:-- --:--:-- --:--:--  1200
100   451  100   451    0     0    417      0  0:00:01  0:00:01 --:--:--   417
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   609    0   609    0     0   1246      0 --:--:-- --:--:-- --:--:--  1247
100 2874k  100 2874k    0     0   777k      0  0:00:03  0:00:03 --:--:-- 1211k
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   613    0   613    0     0   1286      0 --:--:-- --:--:-- --:--:--  1293
100 1710k  100 1710k    0     0   515k      0  0:00:03  0:00:03 --:--:--  649k
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   614    0   614    0     0   1162      0 --:--:-- --:--:-- --:--:--  1178
100 7154k  100 7154k    0     0  1314k      0  0:00:05  0:00:05 --:--:-- 1736k
(1/4) Installing glibc (2.23-r1)
(2/4) Installing libgcc (5.3.0-r0)
(3/4) Installing glibc-bin (2.23-r1)
(4/4) Installing glibc-i18n (2.23-r1)
Executing glibc-bin-2.23-r1.trigger
OK: 31 MiB in 24 packages
(1/4) Purging curl (7.47.0-r0)
(2/4) Purging ca-certificates (20160104-r2)
(3/4) Purging openssl (1.0.2f-r0)
(4/4) Purging libssh2 (1.6.0-r0)
Executing busybox-1.24.1-r7.trigger
Executing glibc-bin-2.23-r1.trigger
OK: 29 MiB in 20 packages
 ---> 51992d8f231c
Removing intermediate container ab3222998627
Step 6 : ENV JAVA_HOME /jre
 ---> Running in 0a98b36a6e37
 ---> 5af4d87e3790
Removing intermediate container 0a98b36a6e37
Step 7 : ENV PATH ${PATH}:${JAVA_HOME}/bin
 ---> Running in 54d0dfb04f98
 ---> 493399ac9ca6
Removing intermediate container 54d0dfb04f98
Successfully built 493399ac9ca6
```
哈哈！它执行成功了。我们运行容器里的java来验证一下吧：


```sh
$ docker run --rm -ti my-java-base-image java -version
java version "1.8.0_73"
Java(TM) SE Runtime Environment (build 1.8.0_73-b02)
Java HotSpot(TM) 64-Bit Server VM (build 25.73-b02, mixed mode)
```

太好了，这正是我们要看到的结果，我们已经有了一个独立的Oracle JRE环境，以后我们只需要基于这个镜像来构建应用镜像即可：


```sh
FROM my-java-base-image

[...]
```

### 最终镜像有多大？

我们来看看：

```sh
$ docker images | grep my-java-base-image | awk '{print $7,$8}'
130.4 MB
```
说实话，这还是挺大的，但是毕竟里边装的是Java嘛~


## 总结

我们现在构建了一个安全、轻量的Docker镜像，基本上可以运行任何Java应用在上面，当然你也可以根据实际情况调整这个Dockerfile，但是主要的思想还是像上边说的那样，减小体积，使用安全的软件源。

一旦你明白Docker容器只是一个基础的单进程容器，只是一个应用运行的环境，它能让你专注于应用的构建而不是其他杂七杂八的依赖关系，你就会把Docker应用到得心应手。

### 以下是简单的几点指引：

- 在每个容器中运行一个进程，如果你需要多个进程，那就构建多个容器，并且使用如docker-compose之类的工具去组合这些组件。
- 从一个非常小的镜像开始构建。你不需要整个Debian或者Ubuntu镜像，特别是当你使用的是编译型语言（例如 C / C++ / Golang)。几乎所有的应用加上Alpine Linux就足够了。
- 高效地使用层：添加更多的文件层会便于打标签和调试，但是这样会使镜像体积膨胀。你需要平衡这两点。
- 安全性是非常重要的，确保从安全的仓库拉取镜像，从安全的安装源安装相关软件包。(Alpine Linux镜像从Docker官方拉取，JRE从Oracle官方下载）
