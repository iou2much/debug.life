title: 【译文】使用Java构建微服务
date: 2016-01-23 00:50:23
toc: true
category: Translation
description: 本文讲述了如何在容器中用Java构建微服务
---

by [Ivar Grimstad](https://dzone.com/users/1478693/ivargrimstad.html)    ·  Oct. 23, 15

本文是我们《Java生态DZone指南》的前篇，由[Ivar Grimstad](https://dzone.com/users/1478693/ivargrimstad.html)供稿，讲述了如果在容器中用Java构建微服务。

## 概览
1. 在Java生态系统中构建微服务的策略有三种，分别为：无容器、自成容器、外置容器。
2. 以无容器的方式提供微服务，会把整个应用打包，包含所有依赖，打进一个fat JAR包中。
3. 自成容器的微服务同样也是打成单个JAR包，JAR包中会包含带有第三方类库的嵌入式框架。
4. 外置容器的微服务方式，会把整个Java EE容器和服务的实现打包进一个Docker容器。

基于微服务的架构给架构师和开发者带来了新的挑战，不断出现的新语言和开发工具使我们得以应对这个挑战。Java也不例外，本文将探索在Java生态系统中构建微服务的新思路。

## 介绍
本文不讨论微服务的好坏，也不讨论你是否应该一开始就以微服务架构来设计应用，或者是否应该将已有的庞大应用重构成微服务架构。

这里讨论的方法并不是仅有的方法，但它们会为我们看到其他可能带来启发。虽然本文的重点是Java生态系统，但其中的概念对其他语言和技术也通用。

我在本文命名了几种方式为“无容器”、“自成容器”、“外置容器”。这些术语并未被广泛使用，但是它们能足以区分每种方法的特点，我会在以下小节中讨论。

## 无容器方案
在无容器的方式中，开发者把JVM上的所有组件都看作应用的一部分。

无容器的方式使用单个JAR包部署（所谓的"fat JAR部署"），意味着，这个应用以及它所有的依赖，都被打包成一个JAR文件，这个JAR可被作为独立的Java进程启动。

![图1](http://7xnyt8.com1.z0.glb.clouddn.com/java-1-cn.png)

```sh
$ java -jar myservice.jar
```
这方法其中一个优点是，可以根据需要非常简单地停启服务，以达到扩容或缩容的目的；另一个优势是方便实现分布式部署，只需要同步一个JAR文件就可以了。

另一方面，它的缺点是类库依赖的兼容性问题。例如你需要使应用支持事务特性，你只能靠自己了，或者需要引入支持这个功能是第三方类库。以后，每当你需要支持其他特性，例如说，持久化，就很可能会遇到类库之间的兼容性问题。

## 自成容器方案
单JAR包的部署方式有一个变体，就是把你的服务基于一个内置框架构建。通过这种方法，框架可以提供服务所需要的特性，开发者可以自行选择哪些特性被包含在服务内。

你可能会争论说这和"无容器"方案不是一模一样吗？但是，在这我想特地区分开它们，因为“自成容器”的方案实际上会提供一套具兼容性的第三方类库。
![图2](http://7xnyt8.com1.z0.glb.clouddn.com/java-2-cn.png)

这种方案的实践通常涉及Spring Boot或Wildfly Swarm等框架。

### Spring Boot
[Spring Boot](http://projects.spring.io/spring-boot)和[Spring Cloud Netflix](http://cloud.spring.io/spring-cloud-netflix)项目对构建Java微服务有良好的支持。Spring Boot允许你从Spring系列的组件中挑选不同的部分出来，连同其他出色的外部工具一起，和你的应用打包进一个JAR文件中，[Spring Initializr](https://start.spring.io/)让你可以通过一个复选列表的表单就完成这些工作。一个简单的Hello World服务在以下例子中可以看到：[Gist Snippet](https://gist.github.com/ivargrimstad/8bbc2b1085948a38fcdd)。

### Wildfly Swarm
[WildFly Swarm](http://wildfly.org/swarm)相当于Jave EE版的Spring Boot，它让你可以挑选Jave EE规范里的组件，并与你的应用同时打包进一个JAR文件中。Hello World示例在此可看到：[Gist Snippet](https://gist.github.com/ivargrimstad/2d2fee6193e33bc554b7)。

“自成容器”方案的优点在于，你能够自由选择服务所需要的最小集组件。

这个方案不好的地方在于，配置起来稍微复杂些，并且最终生成可交付的JAR包体积会大些，因为它已经包含了容器的特性在里边。

## 外置容器方案
然而需要整个Java EE容器才能部署好一个微服务似乎有点大材小用了，有些开发者会争论微服务中的”微”并不一定是这个服务很小或者很简单。
![图3](http://7xnyt8.com1.z0.glb.clouddn.com/java-3-cn.png)
这种情况下，把Java EE容器作为一个必要的基础似乎是适当的。因此，你唯一需要的是Jave EE的API。注意这些依赖已经由容器提供好了，这意味着最终应用的WAR文件会非常小。这种微服务的实现方式和上边的Wildfly Swarm例子一样：[Gist Snippet](https://gist.github.com/ivargrimstad/c368221fa079285856e7)

这种方式的优点是，容器通过标准的API提供了已验证标准功能的实现，因此，作为一个开发者，你可以不关心底层细节，完全集中在业务功能上。

这个方案的另一个优点是，应用层的代码并不依赖于它所部署的Jave EE应用服务器，无论它是[GlassFish](https://glassfish.java.net/), [WildFly](http://wildfly.org/), [WebLogic](http://www.oracle.com/us/products/middleware/cloud-app-foundation/weblogic/overview/index.html), [WebSphere](http://www.ibm.com/software/websphere)或者任何其他Jave EE兼容的实现。

缺点是你需要把服务部署进一个容器中，所以一定程度上增加了部署的复杂度。

### Docker
[Docker](https://www.docker.com/)现在要出场了，通过把Java EE容器和服务的实现打包进一个Docker镜像，可以达到和单JAR包方式部署差不多的效果，不同之处是服务是打包进一个Docker镜像而不是一个JAR包了。

```sh
Dockerfile 

FROM jboss/wildfly:9.0.1.Final ADD myservice.war /opt/jboss/wildfly/standalone/deployments
```

通过启动Docker引擎中的镜像来开启这个服务。

```sh
$ docker run -it -p 8081:8080 myorganization/myservice
```

### Snoop
细心的读者可能注意到前边Spring Boot示例中的<code>@EnableEurekaClient</code>注解，这个注解通过Eureka把服务注册了，让它能被服务的消费者发现。[Eureka](https://github.com/Netflix/eureka/wiki/Eureka-at-a-glance)是Spring Cloud Netflix工具集的一部分，能极度简化服务发现的配置。

Java EE并没有提供这个特性，但是相应的有几个开源的方案。其中一个是[Snoop](https://github.com/ivargrimstad/snoop)，与Eureka有[类似的功能](https://github.com/ivargrimstad/snoop)，要使Java EE微服务能被路由到，唯一一件事要做的是使用@EnableSnoopClient注释，详见示例：[Gist Snippet](https://gist.github.com/ivargrimstad/34bfe4b5368a35d30007)

## 总结
要构建微服务，Java是一个非常好的选择，本文中提到的任何一个方案都可以实现。最适合的方案视乎服务的具体需求。对于相对简单的服务来说，“无容器”或”自成容器”是更好的选择，但是使用外置容器的方式，能更快捷简单地构建更复杂的服务。无论是哪种方案，要实现微服务，使用Java生态圈的组件都是被验证过的。

欢迎来到DZone社区，这里有更多关于微服务，JVM语言，和Java的发展趋势的文章。


