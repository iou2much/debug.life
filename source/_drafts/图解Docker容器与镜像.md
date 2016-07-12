title: 【译文】图解Docker容器与镜像
date: 2016-02-02 06:48:39
tags: 
 - Docker
description: 本文将详解Docker中容器及镜像的关联与差异
toc: true
category: 工具
---


By [Daniel Eklund](https://www.blogger.com/profile/11570452431861145598)     [原文链接](http://merrigrove.blogspot.co.uk/2015/10/visualizing-docker-containers-and-images.html?_tmc=Diy2bNEQqG5t8sSbcMW6T5Us4KCmgsInjBviObh0atg&mkt_tok=3RkMMJWWfF9wsRonuqTMZKXonjHpfsX67%2B4sWKG0lMI%2F0ER3fOvrPUfGjI4AS8VqI%2BSLDwEYGJlv6SgFQ7LMMaZq1rgMXBk%3D)


本篇是介绍Docker进阶知识的文章，如果你还不知道Docker是什么,或者不知道它与虚拟机有什么区别，或者不知道如何使用相关的配置管理工具，那么本文目前或许还不大适合您。

本文意在帮助在彻底领会Docker命令行有困难的读者，尤其是那些已经清楚容器和镜像之间区别的人。更进一步来说，本文严格区分开了一个简单的容器和运行中的容器。

![图2](http://7xnyt8.com1.z0.glb.clouddn.com/2-cn.png)
为达到本文目的，我着眼于一些底层细节，也就是Docker中堆栈式联合文件系统，这个过程我独自一人花了过去好几个星期才完成，因为我对Docker技术接触时间不长，刚接触时也发现Docker的命令行知识难以内化。

<code>题外话：
常言道磨刀不误砍柴工，我认为理解某种技术的底层是一种最快速的学习方法，而且还能让你确信，你是以正确的方式使用着这些工具。经常有些技术被匆忙发布了并被各种炒作，这种现状使得我们很难去理解这些技术的使用模式。而且，新发布的技术通常会被简化成一些的抽象模型，并且可能用新发明的术语和隐喻来加以描述，这对初学者可能有些帮助，但是会对阻碍了往后想要精通这些技术的人。
Git是一个很好的例子，我在理解它的底层模型前并没有被它吸引，例如trees,blobs,commits,tags,tree-ish,等等。关于这个话题我之前写了一篇[博文](http://merrigrove.blogspot.com/2014/02/why-heck-is-git-so-hard-places-model-ok.html)，也是让人们知道，没理解Git底层原理的话是没办法精通这个工具的。</code>


## 镜像的定义

第一幅图是以两种形式展示的一个镜像，它可以定义为多个只读层堆栈式的联合视图。
![图3](http://7xnyt8.com1.z0.glb.clouddn.com/3-cn.png)

在左边我们可以看到一个只读层组合的栈，这些是内部实现的细节，这些层能通过宿主机的文件系统访问。重要的是，它们虽然是只读的，但是却能捕获到下层的变化。各层可以有一个父级，最顶级的层能被联合文件系统读取(在我的Docker中的实现是AUFS)，最终实现一个能体现所有层变化的统一视图。对我们来说，看到的是右边这个“联合视图”。

若你想一睹这些层的庐山真面目，你可以在你宿主机的文件系统上找到不同的路径，这些层对运行中的容器并不可见。在我的主系统里，我看在/var/lib/docker这路径下找到一个名为aufs的子目录。

```sh
# sudo tree -L 1 /var/lib/docker/
/var/lib/docker/
├── aufs
├── containers
├── graph
├── init
├── linkgraph.db
├── repositories-aufs
├── tmp
├── trust
└── volumes

7 directories, 2 files
```

## 容器的定义

容器也可以定义为一个堆栈的联合视图，不同的是个个堆栈的顶层是一个可读写的层。

![图4](http://7xnyt8.com1.z0.glb.clouddn.com/4-cn.png)

从上图可以看出，容器和镜像几乎是同一回事，除了最顶级的层是可读写的。现在，可能有人会注意到，定义里并没有提到这个容器是否运行状态，当然，这是故意的，这是为了避免当时可能引起一此概念上的混淆。

容器可被定义为镜像上的一个可读写层,它并**不一定非得处于运行状态**。

所以如果我们要讨论容器的运行，我们需要定义什么是运行中的容器。

## 运行状态中的容器
运行中的容器定义为可读写的联合视图，并包含一个独立的进程空间和进程。下图展示的是处于进程空间中的容器。

![图5](http://7xnyt8.com1.z0.glb.clouddn.com/5-cn.png)

得益于文件隔离这个源自cgroups,namespaces等Linux内核级的特性，Docker才发展成那么有前景的技术。在这个进程空间中的进程可以新建、修改或者删除联合视图中的文件，这些变更会被可读写层捕获到，如下图所示：
![图6](http://7xnyt8.com1.z0.glb.clouddn.com/6-cn.png)

可以执行以下命令看到效果：<code>docker run ubuntu touch happiness.txt</code> 。然后你可以在宿主系统的可读写层见到这个新文件，即使这个容器已经不是运行状态。（注意，在宿主系统运行这个命令，而不是在容器中）：

```sh
# find / -name happiness.txt
/var/lib/docker/aufs/diff/860a7b...889/happiness.txt
```

## 镜像层定义
最后，为了理清一些细节问题，我们来给镜像层下个定义。下图是一个镜像层，让我们意识到一个层并不只是文件系统的变更。
![图7](http://7xnyt8.com1.z0.glb.clouddn.com/7-cn.png)

元数据记录着Docker运行时与编译时的信息，还有该层父级的级别信息。只读层和可读写层都包含元数据。
![图8](http://7xnyt8.com1.z0.glb.clouddn.com/8-cn.png)
另外，我们前边也提到过，每一层上都维护了一个指针，指向父级层的ID（在图中，父级位于下方）。如果一个层没有这个指针，那么它就是位于栈底。
![图9](http://7xnyt8.com1.z0.glb.clouddn.com/9-cn.png)

```sh
元数据的路径：
目前（我当然知道Docker的开发者们可能改变这个实现），镜像(只读)层的元数据能在一个json文件中找到，这个文件在/var/lib/docker/graph下对应的层目录中，例如：/var/lib/docker/graph/e809f156dc985.../json， "e809f156dc985..." 在这里是一个层ID的省略。

容器的元数据似乎被打散在许多文件当中，但是大致也能在/var/lib/docker/containers/< id >中找到，< id >是可读写层的ID。这个目录中的文件包含了更多运行时的元数据，这些元数据需要对外暴露，如网络信息，命名信息，日志等等。
```

## 融会贯通

现在，我们用下边这些图片，加深对Docker命令的理解：


### docker create < image-id >

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图10](http://7xnyt8.com1.z0.glb.clouddn.com/10-cn.png)  | ![图11](http://7xnyt8.com1.z0.glb.clouddn.com/11-cn.png) |

<code>docker create</code>命令基于参数中的镜像ID，新建了一个可读写层在堆栈顶部。这个命令并不会运行容器。
![图12](http://7xnyt8.com1.z0.glb.clouddn.com/12-cn.png)


### docker start < container-id >

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
|![图13](http://7xnyt8.com1.z0.glb.clouddn.com/13-cn.png) |![图14](http://7xnyt8.com1.z0.glb.clouddn.com/14-cn.png) |
<code>docker start</code>命令，在容器的联合视图层上创建了一个进程空间，并且一个容器只能有一个进程空间。

### docker run < image-id >
| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------: | 
|![图15](http://7xnyt8.com1.z0.glb.clouddn.com/15-cn.png) |![图16](http://7xnyt8.com1.z0.glb.clouddn.com/16-cn.png) |

初学者最常问到的一个问题（包括我自己）是，“<code>docker start</code>和<code>docker run</code>有什么不同？” 	本文想解释的最主要一点就是两者之间的细微差别。
![图17](http://7xnyt8.com1.z0.glb.clouddn.com/17-cn.png)  
我们可以看到，<code>docker run</code>命令从一个镜像开始，创建了一个容器，并运行这个容器。这是一个方便得多的命令，并且隐藏了前两个命令的细节。

```sh
题外话：继续前边提到的Git话题，我认为<code>docker run</code>命令类似于<code>git pull</code>（是<code>git fetch</code>和<code>git merge</code>的合体）。<code>docker run</code>命令是两个底层命令的组合。

在这个角度看它当然方便，但它也一定程度上让人产生误解。
```

### docker ps

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| 宿主系统 | ![图18](http://7xnyt8.com1.z0.glb.clouddn.com/18.png)  | 

<code>docker ps</code>命令列出宿主系统上所有运行中的容器。这个一个非常重要的过滤，隐藏了非运行状态下的容器，要同时看到非运行中的容器，我们需要使用下一个命令。


### docker ps -a

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| 宿主系统 | ![图19](http://7xnyt8.com1.z0.glb.clouddn.com/19.png)| 
<code>docker ps -a</code>中a是all 的缩写，会列出系统中所有容器，无论是运行还是中止的状态。

### docker images

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| 宿主系统 | ![图20](http://7xnyt8.com1.z0.glb.clouddn.com/20-cn.png)| 	

<code>docker images</code>命令列出系统中的顶级镜像。实际上没有什么能区别一个镜像和一个只读层，只有那些有容器关联上，或者被拉取回来的镜像，才被认为是顶级镜像。作出这样的区分，是为了方便查看，因为顶级镜像下还可能会有许多隐藏着的只读层。

### docker images -a

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| 宿主系统 | ![图21](http://7xnyt8.com1.z0.glb.clouddn.com/21-cn.png)| 	

<code>docker images -a</code>命令列出系统中所有镜像，这与列出系统中所有的只读层是一样的。如果你想查看某个镜像ID下的层，你可以用下边会提到的<code>docker history</code>命令。


### docker stop <container-id>

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图22](http://7xnyt8.com1.z0.glb.clouddn.com/22-cn.png) | ![图23](http://7xnyt8.com1.z0.glb.clouddn.com/23-cn.png)| 	

<code>docker stop</code>命令向一个运行中的容器发出SIGTERM信号，这会友好地关闭那个进程空间中的所有进程，执行结果是一个非运行状态下的容器。

### docker kill < container-id >

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图24](http://7xnyt8.com1.z0.glb.clouddn.com/24-cn.png) | ![图25](http://7xnyt8.com1.z0.glb.clouddn.com/25-cn.png)| 	

<code>docker kill</code>命令会向一个运行中的容器下所有进程发出一个非友好的SIGKILL信号，这和在shell里按Control-C是一样的（Control-C发出一个SIGINT信号）。


### docker pause <container-id>

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图26](http://7xnyt8.com1.z0.glb.clouddn.com/26-cn.png) | ![图27](http://7xnyt8.com1.z0.glb.clouddn.com/27-cn.png)|  

不像<code>docker stop</code>和<code>docker kill</code>那样向运行中的进程发出UNIX信号，<code>docker pause</code>使用一个cgroups的特性去冻结/暂停一个运行中的进程空间。实现的原理可以从这里看到：[https://www.kernel.org/doc/Documentation/cgroups/freezer-subsystem.txt](https://www.kernel.org/doc/Documentation/cgroups/freezer-subsystem.txt)  ，但简单来说发出一个Control-Z (SIGTSTP) 信号并不能使得整个进程空间的进程都被冻结。



### docker rm < container-id >

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图28](http://7xnyt8.com1.z0.glb.clouddn.com/28-cn.png) | ![图29](http://7xnyt8.com1.z0.glb.clouddn.com/29.png)|  

<code>docker rm</code>命令会物理删除属于一个容器的可读写层。这个命令必须应用在停止的容器上，它会删除宿主系统上的相应文件。


### docker rmi < image-id >


| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图30](http://7xnyt8.com1.z0.glb.clouddn.com/30-cn.png) | ![图31](http://7xnyt8.com1.z0.glb.clouddn.com/31.png)|  

<code>docker rmi</code>命令会物理删除属于一个镜像的只读层。它删除的是宿主系统上的镜像，当然你还是可以用<code>docker pull</code>从镜像仓库拉取。你只能用<code>docker rmi</code>命令删除顶级的层(或镜像)，不能直接应用于只读层(除非使用 -f 强制删除)。

### docker commit <container-id>

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图32](http://7xnyt8.com1.z0.glb.clouddn.com/32.png) 或![图33](http://7xnyt8.com1.z0.glb.clouddn.com/33.png)|![图34](http://7xnyt8.com1.z0.glb.clouddn.com/34.png) |  

<code>docker commit</code>命令会把容器上的顶级可读写层提交到只读层，这实际上把容器转换为镜像。
![图35](http://7xnyt8.com1.z0.glb.clouddn.com/35-cn.png)

### docker build

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| Dockerfile: ![图36](http://7xnyt8.com1.z0.glb.clouddn.com/36.png)与![图38](http://7xnyt8.com1.z0.glb.clouddn.com/38-cn.png)| ![图38](http://7xnyt8.com1.z0.glb.clouddn.com/38-cn.png)|  


<code>docker build</code>命令很有趣，它能一次性执行多条命令。
![图39](http://7xnyt8.com1.z0.glb.clouddn.com/39-cn.png)
我们从上图可以看到，这个构建命令是如何在Dockerfile文件中，使用<code>FROM</code>指令指定初始镜像，并迭代执行 1)运行 2)修改 3)提交。迭代中，每一步都会创建一个新的层。一次<code>docker build</code>命令可以创建许多个新的层。

### docker exec < running-container-id >

| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图40](http://7xnyt8.com1.z0.glb.clouddn.com/40.png) | ![图31](http://7xnyt8.com1.z0.glb.clouddn.com/41.png)|  

<code>docker exec</code>命令应用在一个运行中的容器上，在那个容器的进程空间中执行一个进程。

### docker inspect < container-id > or < image-id >


| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图42](http://7xnyt8.com1.z0.glb.clouddn.com/42-cn.png)或![图43](http://7xnyt8.com1.z0.glb.clouddn.com/43-cn.png)|![图44](http://7xnyt8.com1.z0.glb.clouddn.com/44.png)  |

<code>docker inspect</code>命令能获取容器或镜像的元数据。



### docker save < image-id >
| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图45](http://7xnyt8.com1.z0.glb.clouddn.com/45-cn.png) | ![图46](http://7xnyt8.com1.z0.glb.clouddn.com/46-cn.png)|  

<code>docker save</code>命令创建一个tar文件，可用于在另一个宿主系统导入。不像<code>export</code>命令，它把每个层的元数据也保存进了文件。这个命令仅限于镜像使用。


### docker export < container-id >

<code>docker save</code>命令把联合视图中的内容保存成一个tar文件，并且这个文件不能被Docker使用，这个命令没有保存元数据和层信息，只能应用于容器。
| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图47](http://7xnyt8.com1.z0.glb.clouddn.com/47-cn.png) | ![图48](http://7xnyt8.com1.z0.glb.clouddn.com/48-cn.png)|  

### docker history < image-id >
| 输入 (若有)      |    输出 (若有) | 
| :--------: | :--------:| 
| ![图49](http://7xnyt8.com1.z0.glb.clouddn.com/49-cn.png) | ![图50](http://7xnyt8.com1.z0.glb.clouddn.com/50-cn.png)|  


<code>docker save</code>命令接收一个镜像ID,并递归地打印出这个镜像ID的祖先只读层。

## 总结
希望你喜欢本篇《图解容器与镜像》，还有其他很多命令(如pull, search, restart, attach等)我们没有提及到，但我相信Docker的绝大部分命令，都能以本文的思路去理解。我只是刚接触Docker两个星期，所以如果我漏了什么或者有什么没解释到位的，请留言指出，谢谢。


