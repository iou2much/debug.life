title: 【译文】如何使用Docker创建开箱即用的MapR集群
date: 2016-02-12 00:50:23
toc: true
category: 翻译
description: 为了保持快速创新的步伐，MapR团队已经在大量使用Docker。我们根据不同需要构建并维护了不同的运行着MapR的Docker镜像，而不是用物理机或者虚拟机来运行大量的测试集群，这样把数以小时计的部署测试集群时间减少到了秒级！.....
---

>September 1, 2015
译自[How to Create Instant MapR Clusters with Docker](https://www.mapr.com/blog/how-create-instant-mapr-clusters-docker#.Vf--zvR73HI) by [Mitra Kaseebhotla](https://www.mapr.com/blog/author/mitra-kaseebhotla)

在MapR公司中，开发效率对我们非常重要。为了保持我们创新的节奏，为了提供给客户更多的选择，让他们能更灵活地使用我们基于Apache Hadoop及其他开源项目改进的MapR发行版，我们尽可能广泛地推行DevOps。其中非常重要的一个环是保证我们可以快速测试我们的构建包，以保证代码库的质量。自动化测试是其中的关键，有了它才得以在我们的发行版中集成开源社区中众多项目版本的最新特性。例如，我们测试通过了基于Hadoop 2.7的Drill 1.1和Hive 1.0，基于Hadoop 2.6的Drill 1.2和Spark 1.3.1等等。为能支持让客户[在单个MapR集群中运行50个以上的应用](https://www.mapr.com/blog/hadoop-adoption-is-the-cluster-half-full) ，在MapR发行版中的组件版本有很多组合可能，因为为了节省客户的时间和金钱，我们允许他们增量地升级各个应用。

为了保持快速创新的步伐，我们已经在大量使用Docker。我们根据不同需要构建并维护了不同的运行着MapR的Docker镜像，而不是用物理机或者虚拟机来运行大量的测试集群，这样把数以小时计的部署测试集群时间减少到了秒级！

在本篇文章中，我们将分享创建Docker化的MapR集群时所用到的工具和方法。我们希望你这些方法从中受益，无论是MapR相关知识还是测试新应用的方法。

## 目标：

- 创建一个多节点MapR集群
- 集群中的节点需要能被运行这些容器的物理机以外的机器访问到
- 能以各种规模运行集群
- 使用物理磁盘去减少I/O性能损耗

## 要求：

- 内存16以上运行着CentOS/RHEL 7.x 的服务器
- Docker 1.6.0以上版本
- 安装了sshpass
- 多个空闲且未挂载的物理磁盘，将用于挂载到MapR节点的容器

## 网络配置：
要实现这些目标，网络配置是其中重要的一环。这些容器(集群中的节点)需要被外部网络访问(可被路由)。我们不希望进行复杂的网络配置。

### 第一步：
设置一个可被路由的网桥.(如：br0) [参考](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s2-networkscripts-interfaces_network-bridge.html)

这是一个CentOS 7.0上的配置示例：

```sh
# cat /etc/sysconfig/network-scripts/ifcfg-br0 
DEVICE="br0"
ONBOOT=yes
IPV6INIT=no
BOOTPROTO=static
TYPE=Bridge
NAME="br0"
IPADDR=10.10.101.135
NETMASK=255.255.255.0
GATEWAY=10.10.101.1
#
```
```sh
# cat /etc/sysconfig/network-scripts/ifcfg-enp4s0 
DEVICE="enp4s0"
ONBOOT=yes
IPV6INIT=no
BOOTPROTO=none
HWADDR="0c:c4:7a:58:7d:19"
TYPE=Ethernet
NAME="enp4s0"
BRIDGE=br0
#
```

### 第二步：
从网络管理员那获取到一组能被路由到的空闲IP，这些IP将被分配到容器，并且和网桥的IP属于同一个虚拟网络。
例如：我们拿到10.10.101.16/29这个IP段，这个IP段包括10.10.101.17 到 10.10.101.22的IP将被分配给各容器。

## Docker配置：
用以下选项配置docker:
```
-b=bridge-inf --fixed-cidr=x.x.x.x/mask
例如：-b=br0 --fixed-cidr=10.10.101.8/29 
这样为容器设置了上边提及到可被路由的IP范围。
```
## 设置容器的磁盘：
每个容器需要一个磁盘或分区以供MapR使用。首先新建一个文本文件，在这个文本中输入一系列磁盘的列表，每行代表一个磁盘。

示例 :

```sh
# cat /tmp/disklist.txt 
/dev/sdb
/dev/sdc
/dev/sdd
/dev/sde
/dev/sdf
```
如果文本中的磁盘数量比容器需要的多，多余的磁盘会被分配给第一个容器。

## 下载并运行这个脚本：
launch-cluster.sh 在此下载 [4.0.2](https://raw.githubusercontent.com/mapr/mapr-docker-multi/master/4.0.2/launch-cluster.sh), [4.1.0](https://raw.githubusercontent.com/mapr/mapr-docker-multi/master/4.1.0/launch-cluster.sh), [5.0.0](https://raw.githubusercontent.com/mapr/mapr-docker-multi/master/5.0.0/launch-cluster.sh)

```sh
使用方法 : ./launch-cluster.sh 集群名称 节点数量 内存大小(kB为单位) 磁盘列表文件的路径
示例:
# ./launch-cluster.sh  demo 4 16384000 /tmp/disklist.txt 
Control Node IP : 10.10.101.21		
Starting the cluster: https://10.10.101.21:8443/    
login:mapr   password:mapr
Data Nodes : 10.10.101.22,10.10.101.17,10.10.101.18
#
```
通过控制节点的IP打开MapR的管理终端：https://10.10.101.21:8443 （从上述示例的输出可以看到）

在这篇博文中，你已经学到了如何用Docker创建开箱即用的MapR集群。如果你有任何疑问，请在下边的评论区提出。

你有兴趣阅读更多MapR运行在Docker环境下的相关文章吗？请阅读另一篇博文[我在Mesos上运行Docker容器的经验](https://www.mapr.com/blog/my-experience-running-docker-containers-on-mesos#.VeXbjrxVhBc)

