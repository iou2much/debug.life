title: 【译文】Docker:容器与虚拟机的差异 
date: 2016-01-10 00:50:23
toc: true
category: Translation
description: 本文将探讨Docker容器和全虚拟化之间的区别.....
---


虚拟机（VM）是对某计算机操作系统的模拟，虚拟机的实现是基于计算机虚拟化的架构和指令，具体可能需要特定的硬件、软件、或两者同时的支持。

本文将探讨Docker容器和全虚拟化之间的区别。（[注1](https://www.blogger.com/blogger.g?blogID=748094882401183761#Note_1)）
![图1](http://7xnyt8.com1.z0.glb.clouddn.com/dockerContainer.jpg)

## Docker容器

Docker是一个创建封装好的隔离计算机环境，每个封装好的环境被称为容器。[2,7]

启动一个Docker容器非常迅速，因为：
* 每个容器共享宿主系统的内核。
	* 然而，各个容器都运行着一个Linux的副本
	* 这意味着没有**hypervisor**，而且**不需要额外的启动**。

对比之下，KVM, VirtualBox 或者 VMware之类的虚拟机实现是不同的。

## 术语
* **宿主系统** vs **客户系统**
	* 宿主系统
	是直接安装在计算机上的原生系统   
	* 客户系统
       是安装在一个虚拟机上，或者在宿主机的一个分区上的系统
		* 如果是安装在虚拟机上，客户系统可以与宿主系统不同。
		* 如果是安装在一个磁盘分区上，客户系统必须与宿主系统相同。

* [Hypervisor (虚拟机监视器)](https://en.wikipedia.org/wiki/Hypervisor)
	* 是一种计算机软件、固件或者硬件，用于创建并运行虚拟机的。
	* 一个系统中安装着hypervisor，里边运行着一个或多个虚拟机，这个系统可被定义为宿主机。
	* 各个虚拟机被定义为客户机。
	
* [Docker容器](https://en.wikipedia.org/wiki/Docker_(software))
	* 由Docker创建的一个封闭计算环境
	* Linux平台上的Docker
		* 基于[Linux内核](https://en.wikipedia.org/wiki/Linux_kernel)提供的组件构建的(特别是cgroups和namespaces) 
		* 不像虚拟机，不需要包含一个独立的操作系统
	* 非Linux平台上的Docker
		* 使用[Linux虚拟机](https://en.wikipedia.org/wiki/Virtual_machine)去运行容器
* [Docker守护进程](https://docs.docker.com/reference/commandline/daemon/)
	* 是管理容器的持久进程。
	* 使用<u>Linux特定的内核特性去实现</u>。


## 容器 vs 全虚拟化

全虚拟化的系统分配到的是独有的一组资源，只有极少量的资源会共享，是有<u>更强的隔离性</u>，但是更加重了（需要更加多的资源）。用Docker容器有弱些的隔离性，但是它们<u>更加轻量</u>，需要更少的资源，所以你可以毫不费力地启动上千个容器。

基本上，Docker容器(详见[注1](https://www.blogger.com/blogger.g?blogID=748094882401183761#Note_1))和全虚拟化VM有着本质上不同的目标
* VM是用于完全模拟一个外部环境
	* 在一个全虚拟化VM的实现上，Hypervisor主要作用是翻译客户系统和宿主系统之间的指令。
	* 每个虚拟机中，应用以及相关依赖运行在一个完整的操作系统上。
	* 如果你需要同时运行不同的操作系统（如Windows, OS/X 或 BSD），或者需要为需要平台的系统编译程序，那你需要的是一个全虚拟化VM的实现。
		* 相反地，容器的系统(或者更准确来说，是内核)必须与宿主系统的一致，而且与容器和宿主间共享着。(详见[注1](https://www.blogger.com/blogger.g?blogID=748094882401183761#Note_1))
		
* 容器是用于使得应用具移植性，并能自包含
	* 各容器共享着宿主机的内核
		* 这意味着没有hypervisor，而且不需要额外的系统启动。
		* 容器引擎负责启动或停止容器，这与虚拟机实现中的hypervisor类似。
			* 然而，容器中运行的进程与宿主系统的进程是同行级别的，所以不会被相关的hypervisor杀掉。
			
## [注意](https://www.blogger.com/null)
在本文中，我们只关注了Linux平台下的Docker实现，换言之，我们讨论的是排除掉了非Linux平台(也就是Windows,Mac OS X等等)
因为Docker守护进程使用特定的Linux内核特性，你不能在Windows 或 Mac OS X直接运行原生的Docker。
在非Linux平台上，Docker使用[Linux虚拟机](https://en.wikipedia.org/wiki/Virtual_machine)去运行容器。

图片来源
[Docker Blog](http://blog.docker.com/2014/03/docker-0-9-introducing-execution-drivers-and-libcontainer/)

引用
1. [How is Docker different from a normal virtual machine? ](http://stackoverflow.com/questions/16047306/how-is-docker-different-from-a-normal-virtual-machine)(Stackoverflow)
2. [Newbie's Overview of Docker](http://www.troubleshooters.com/linux/docker/docker_newbie.htm)
3. [Supported Installation](https://docs.docker.com/installation/) (Docker)
4. [EXTERIOR: Using Dual-VM Based External Shell for Guest-OS Introspection, Configuration, and Recovery](https://labs.vmware.com/vee2013/docs/p97.pdf)
5. [Comparing Virtual Machines and Linux Containers Performance](http://www.infoq.com/news/2014/08/vm-containers-performance)
6. [An Updated Performance Comparison of Virtual Machines and Linux Containers](http://domino.research.ibm.com/library/cyberdig.nsf/papers/0929052195DD819C85257D2300681E7B/$File/rc25482.pdf)
7. [Security and Isolation Implementation in Docker Containers](http://xmlandmore.blogspot.com/2015/11/security-and-isolation-implementation.html)

