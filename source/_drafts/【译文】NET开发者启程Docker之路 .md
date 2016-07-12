title: 【译文】NET开发者启程Docker之路 
date: 2016-01-10 00:50:23
toc: true
category: 翻译
---

编者话：本文作者为微软Azure MVP专家[Elton Stoneman](https://mvp.microsoft.com/en-us/PublicProfile/4028368?fullName=Elton%20Stoneman)，由Azure MVP专家[Richard Seroter](http://https//mvp.microsoft.com/en-us/PublicProfile/4014256?fullName=Richard%20Seroter)担任技术编辑。

Docker让我们能用更少的资源，更快的速度来构建运行应用程序，所以应用容器技术(Docker就是其中一种)在当今那么受欢迎。我们可以在只能跑几个虚拟机的物理机器上跑上百个容器，容器的部署效率非常高，而且能用版本管理。
 
如果你在微软的环境下工作，那你可能以为容器只是其他平台的开发者能用的技术（例如LAMP，NodeJs或者Java)，但是实际上你已经能在Docker里运行.NET应用了。本文中，我将详细介绍如何操作。

 

## 应用容器

应用容器是一种快捷且轻量的计算单元，能让你在一个物理（或虚拟）服务器上承载大量计算任务。一个已被容器化的应用，会被部署在一个包含了所有依赖的镜像上，这里据说的依赖，包括了最小化安装的操作系统。这些镜像非常轻量，通常只有几百兆，而且启动只需要数秒。
 
Docker已经引领了容器技术的发展，让构建、分发和使用都更加简单，容器技术在过去几年是一个热门话题，原因很简单，这种技术能让你在单个节点上运行成百上千个容器，而且，它的分发和运行速度让人欲罢不能，所以到现在，它已经成为了很多团队的开发、测试和构建流程的核心。另外，它的出现也让人们加速转向更易于扩展的无状态架构。

如果按目前的发展趋势，很可能再过几年应用容器就会成为我们的默认部署方式了。容器技术即将正式应用在Windows平台上了，但其实现在你就可以用Docker来运行.NET核心的应用了，下面我们来提前体验一下这种激动人心的技术吧。

## 不止是别人的玩具 
容器技术使用了Linux内核的特性，使容器内的应用能像运行在原生系统上那样调用系统指令。所以你既需要在容器中运行Linux系统，也需要Linux系统来运行容器。

但实际上Linux也可以作为虚拟机运行在Windows或者OS/X上，[Docker Toolbox](https://www.docker.com/docker-toolbox)把所有相关的都打成了一个包，让我们能轻松上手在Windows上使用容器，只需要花几分钟下载安装好，它带有一个Linux虚拟机，底层使用的是[VirtualBox](https://www.virtualbox.org/)。
 
微软正在大力推进Docker在非Linux下运行的开发工作，在Windows Server 2016上，我们将能在Windows原生系统上运行Docker容器；而在容器中，我们将能运行Windows Nano Server系统，所以届时我们将把.NET应用运行在原生系统上。

## .NET Core
 
而现在，我们可以使用跨平台的.NET Core去在Linux容器中打包应用，Docker有公共镜像仓库，我已经把一个示例镜像推到上边了，你安装好Docker之后，可以通过以下命令来体验一个基础版的.NET内核应用：

```sh
docker run sixeyed/coracle-hello-world
```
第一次运行这个命令，会从Docker Hub下载容器的镜像，这会花费一段时间，但你下次运行时，由于这个镜像已经存在于你本地，所以将会立即运行，这个简单的应用会输出当前时间和日期：
![图1](https://msdnshared.blob.core.windows.net/media/2015/12/12-300x50.jpg)

虽然功能很简单，但它是使用了.NET中的Console.WriteLine(),而这个容器中的系统是Ubuntu Server。也就是说，我们现在有了一个运行在Linux上的.NET应用容器镜像，这样相当于我们可以在任何地方运行.NET应用了。

.NET Core 是一个开源版的.NET，它与原来的.NET关注点并不一样，它是一个模块化的框架，也就是说你可以只引入你需要的依赖，这个框架本身是由NuGet包组成。[这篇文章](https://docs.asp.net/en/latest/getting-started/choosing-the-right-dotnet.html)介绍了如何选择不同的.NET框架。

在你要运行.NET Core应用在Linux（或OS/X或Windows）上，你需要安装DNX运行时组件，这不是官方的.NET运行时，而是一个瘦身版的.NET运行环境(DNX)。在[这本书](https://github.com/dotnet/coreclr/blob/master/Documentation/README.md#book-of-the-runtime)中介绍了它的原理，但其实要在Docker构建一个.NET应用，并不需要了解得太深入。
 
当你定义了一个Docker镜像，你可以从一个基镜像开始构建，[sixeyed/coreclr-base](https://hub.docker.com/r/sixeyed/coreclr-base/)这个镜像发布在Hub上，在它里边DNX已经安装配置好了，要把你的应用容器化的话，只需要在这个基镜像中加入你的代码，下一部分，我们看看应该怎么做。

## The Uptimer App
 
我在GitHub上有一个.NET Core应用，它会去ping一个的URL，然后记录一些关键字段，例如响应码和响应时间，把结果写到Azure blob上。代码在我的[coreclr-uptimer](https://github.com/sixeyed/coreclr-docker/tree/master/coreclr-uptimer)仓库。
 
它是一个.NET Core 应用，所以它和典型的Visual Studio solution应用结构不同，它没有solution文件，它的Sixeyed.Uptimer相当于solution，还有一个project.json定义了应用运行的配置和相关依赖：
 
```json
“frameworks”: {

“dnxcore50″: {

“dependencies”: {

“Microsoft.CSharp”: “4.0.1-beta-23516″,

“WindowsAzure.Storage”: “6.1.1-preview”,

“System.Net.Http”: “4.0.1-beta-23516″

…
```
 
这里我定义了应用运行在dnxcore50上，这是DNX最新的版本。还有那些依赖全部都是NuGet的包，.NET Core应用像普通应用那样使用NuGet，但你可以只引用用于构建.NET Core的包，这里使用了WindowsAzure.Storage和System.Net.Http 。
 
以下这段代码使用了标准C#，包括timer，disposables 和 AAT (Async, Await and Tasks)：

```java
var request = new HttpRequestMessage(HttpMethod.Get, url);

using (var client = new HttpClient())

{

return await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead);

}

```

然后这样把输出写到Azure中：

```java
var blockId = Convert.ToBase64String(Guid.NewGuid().ToByteArray());

using (var stream = new MemoryStream(Encoding.UTF8.GetBytes(content)))

{

stream.Position = 0;

await blockBlob.PutBlockAsync(blockId, stream, md5, access, options, context);

}
```
 
project.json文件使我们能从任何机器上用源码构建，而不需要指定平台，所以这应用的代码能运行于Windows，OS/X和Linux，也就是说我们能把它打包到Docker容器中。
 
容器通过Dockerfile来定义，这个文件中包含了构建和运行镜像的所有程序。通常来说，我们会创建一个目录用于容器的定义，这个目录包含了Dockerfile和所有用到的文件，例如Sixeyed.Uptimer的代码目录。

![图1](https://msdnshared.blob.core.windows.net/media/2015/12/21.jpg)


我们构建这个容器后，会得到一个包含编译后应用的镜像。所以在容器的定义中，我需要告诉Docker去使用.NET Core基镜像，并且把我应用的代码复制进去。Dockerfile的语法是自解释的，[整个流程](https://github.com/sixeyed/coreclr-docker/blob/master/coreclr-uptimer/Dockerfile)只需要7行代码 ：
 
```sh
FROM sixeyed/coreclr-base:1.0.0-rc1-final

MAINTAINER Elton Stoneman <elton@sixeyed.com>

# deploy the app code

COPY /Sixeyed.Uptimer /opt/sixeyed-uptimer
```
 
Docker刚刚构建镜像时，我们只有一个装有.NET Core的Ubuntu Server镜像，还有应用的代码文件都复制进容器中了，但是还没有构建。要构建一个.NET Core 应用，首先要运行dnu，这会从NuGet获取全部依赖包，我们可以用<code>RUN</code>指令：

```sh
WORKDIR opt/sixeyed-uptimer

RUN dnu restore
```
 <code>WORKDIR</code>指令设置了当前目录，所以dnu命令会读取应用目录下的project.json文件去获取依赖。
 
这时，镜像中已经具备了所有需要的条件，所以在Dockerfile最后的部分，它告诉容器要运行什么。我用ENV指令添加了DNX的路径到环境变量中，ENTRYPOINT指定当容器开始运行时，会执行dnx命令。
```sh
ENV PATH /root/.dnx/runtimes/dnx-coreclr-linux-x64.1.0.0-rc1-final/bin:$PATH

ENTRYPOINT [“dnx”, “run”]
```
 
上边就是定义这个容器的方法，你可以在本地构建，也可以我在Docker Hub上发布的版本<code>sixeyed/coreclr-uptimer</code>：

```sh
docker pull sixeyed/coreclr-uptimer
```
 
这个.NET应用需要两个参数，一个是需要ping的URL，一个是ping的频率。它还需要配置Azure Storage的账号用于存放ping的结果，这个配置会读取环境变量STORAGE_CONNECTION_STRING。
 
 连接字符串是可变的，所以我不把它放到镜像构建过程中。为了在运行容器时能传这个进去，可以使用环境变量或者一个独立的文件。

 我运行了这个容器的一个实例，它会每10秒ping 我的博客，并且把结果保存起来：
 
```sh
docker run -e STORAGE_CONNECTION_STRING=’connection-string’ sixeyed/coreclr-uptimer https://blog.sixeyed.com 00:00:10
```
 
我可以在任何Docker主机运行这个命令，无论是一个开发笔记本，还是虚拟机，或者是云上的容器，无论宿主机的系统是什么，它都会运行同样的代码。

## Docker的架构方案
 
上边介绍的应用只是小儿科，那么到底它有什么用呢？把网站的响应时间记录下来或许并不是很有用，但是这个项目涉及到一个实际问题，这个问题是我一直不满意传统方式的地方，而在Docker下有更好的实现。
 
想象一下这个场景，我把一组REST接口开放给客户端，其中很多都面临很大的业务压力，所以我们希望能每几秒就ping一下这些接口，来实时检查接口是否出现了问题。市场上的产品没有周期性的ping，所以我们写了自己的工具：


![图3](https://msdnshared.blob.core.windows.net/media/2015/12/32-300x205.jpg)

 这些任务中的代码与本文的一样，但是如果你写了一个庞大的应用来处理多个URL，那你就会添加了很多不必要的复杂性。
 
你需要存储每个URL，你需要一个调度器，你需要管理多个并发的任务，你需要一个机制来检测这个应用是否失效....一下子，这个监控的组件就变得大而复杂了，越是稳定，那它就会越庞大复杂。

在Docker的方案中，实现这些简单得多。我把核心的代码放到一个.NET 应用中，只实现了ping单个URL和记录返回值 ，这就是全部了，最多就只有100行代码，而其他需求就可以用其他适当的技术来满足。
 
为了ping多个URL，我们可以启动多个实例，而Docker会帮我们管理资源。而且如果我们用的是云服务，我们可以根据需要随时扩容或缩容，Mesos和Kubernetes提供了集成Docker的管理层。

这段示例代码启动了多个后台实例，每个实例监控不同的域名，会每10秒ping a.com一次，每20秒ping  b.com一次，每30秒ping c.com一次。
 
```sh
docker run -i -d –env-file /etc/azure-env.list sixeyed/coreclr-uptimer http://a.com 00:00:10

docker run -i -d –env-file /etc/azure-env.list sixeyed/coreclr-uptimer http://b.com 00:00:20

docker run -i -d –env-file /etc/azure-env.list sixeyed/coreclr-uptimer http://c.com 00:00:30
```
 
–env-file参数告诉Docker去指定路径下找到连接字符串，这样我们就可以确保那个文件的安全。-i和-d参数告诉Docker在后台运行，并且保持输入通道的打开。

这样监控单个站点的功能很简单，也应该保持简单。而需要监控的站点越多，我们就需要往这个脚本文件添加越多行。但是每个容器占用的资源是非常少的。

为了看到它能怎样扩容，我在Azure上启动了一个虚拟机，使用了库里的Ubuntu Server镜像，上边已经安装好了最新的Docker，我用了一个D1-spec设备，它主要的配置是单核和3.5GB内存。

然后我拉取了coreclr-uptimer镜像，并运行一个脚本监控50个互联网上最受欢迎的网站。这些容器几秒就启动了，但是它用了几分钟来运行dnx来构建应用。

当这些容器都准备好了，我同时监控了50个域名 ，每隔10到30秒ping一次，这时机器资源只占了10-20%。

![图4](https://msdnshared.blob.core.windows.net/media/2015/12/41-300x171.jpg)

 
这是容器的一个完美用例，当我们有很多独立的任务要运行时，我们可以使用这种架构，在同一个节点上运行数百个容器也不会占用太多资源。
 

## 部署 .NET Core 应用
 
你可以在Mac和Linux上构建和运行.NET应用，但是你也要在这些平台上开发，Visual Studio Code是一个Visual Studio的精简版，可以使用.NET Core的项目结构，并且提供了多种语言的语法高亮，如Node和Dockerfile:
![5](https://msdnshared.blob.core.windows.net/media/2015/12/5-300x188.jpg)

你甚至可以使用标准的本文编辑器来写.NET Core代码 ，[OmniSharp(http://www.omnisharp.net/)项目添加了.NET项目的格式化特性，还有很受欢迎的跨平台编辑器Sublime Text:

![6](https://msdnshared.blob.core.windows.net/media/2015/12/6-300x188.jpg)

 
但是这些项目都还是初期，如果你在Windows上用Visual Studio安装了ASP.NET 5 ，你可以用VS来构建调试.NET Core的代码。
 
Visual Studio 2015可以使用project.json文件来加载源码到项目中，你能用上所有智能提示，调试和类导航，但是目前NuGet包管理器还不能用在上边，所以你可以这样尝试把标准的.NET添加到一个.NET Core项目，但是会得到一个类似这样的提示：
 
```sh
NU1002: The dependency CommonServiceLocator 1.3.0 in project Sixeyed.Uptimer does not support framework DNXCore,Version=v5.0.
```
 
所以完整版Visual Studio还是我更常用的.NET Core应用开发IDE，其他替代版虽然轻量，但是功能还不够完善。

Visual Studio 2015能让.NET Core应用程序开发起来像.NET原生的应用那样，设置全都是类似的，在项目的属性页，你可以配置开启调试模式，并且可以使用跨平台特性来支持DNX运行时：

![7](https://msdnshared.blob.core.windows.net/media/2015/12/7-300x178.jpg)


## 未来的Docker and .NET
 
Windows Server 2016很快就要发布了，它不需要虚拟机层就能直接支持Docker容器，所以sixeyed/coreclr-uptimer镜像将能运行在原生的Windows上。

相对Linux基础镜像来说，在容器中能运行的Windows系统版本是Nano Server，这个系统也是基于模块化架构的，目标是要构造非常小的镜像（目前不到200MB，比1.5GB的Windows Server Core要小得多，但仍然比仅有44MB的Ubuntu镜像要大很多），所以， .NET Core将仍会引入整个框架，即使容器已经能满足了。

我们期待的是届时是否能像这样子定义一个镜像：

```sh
FROM windowsnanoserver.
```
 
Dockerfile现在还不能兼容微软的镜像定义，微软现在在用PowerShell和Desired State配置。同时，Windows Nano Server如果能免费使用，那对基于Windows的镜像被发布到Docker Hub上来说也是大大的便利。
 
但是如果Dockerfile格式并不能兼容Windows Server，对于把开源社区上的Dockerfile转换成PowerShell格式的翻译器项目来说，那将是一个很好的发展机会。

应用容器正在改变软件的设计、构建和发布方式，现在对于.NET项目来说也该好好利用起来了。

![EltonStoneman](https://msdnshared.blob.core.windows.net/media/2015/12/EltonStoneman-300x300.jpg)

## 关于作者

Elton是软件架构师、微软MVP，并且在2000年以来在Pluralsight Author上带来很多成功的解决方案。他主要开发环境是在Azure和微软软件栈上，但也意识到跨平台的发展带来了很多机遇，他在Pluralsight上最新的课程也是如此，涵盖了Azure上的大数据应用和Ubuntu基础，他在Twitter上是@EltonStoneman，个人博客是blog.sixeyed.com。