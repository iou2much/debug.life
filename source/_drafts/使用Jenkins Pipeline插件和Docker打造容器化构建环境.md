# 使用Jenkins Pipeline插件和Docker打造容器化构建环境

Docker和Jenkins像DevOps界的巧克力和花生酱那样，它们的组合产生了无数的机会，当然也产生了很多难题，笔者将提及这两个方面。

本文中，我假定读者已经熟悉Jenkins和Docker，我将把焦点放在特定的配置上而不是把笔墨花费在许多博文已经介绍过的入门概念上。


## 设定目标

我所要达成的目标其实非常简单：在一个容器中搭建Jenkins主节点，并且在多个主机上搭建多个JNLP代理容器。这些代理节点可以运行在不同的AWS VPC或者ECS上。

![pic](https://damnhandy.files.wordpress.com/2016/03/architecture2.png)

我的目标是得到一个能在任何主机上部署的通用配置，而每个项目分别定义各自的构建环境。这样各个开发团队就可以掌控这份配置，而不用经由Jenkins的构建团队。我会尽量避免构建一个特定工具集的代理节点。容器技术能实现这样的构建环境，但是要真正把每个细节都做好绝对是一个挑战。

为了实现这个目标，我还使用了Jenkins Pipeline / Workflow插件。这个插件让你能非常优雅地使用DSL语言描述构建过程，更棒的是，它的Cloudbees Docker插件对容器化的构建环境支持得非常好，例如这样简单地定义：

```js
node('test-agent') {
    stage "Container Prep"
    // do the thing in the container
    docker.image('maven:3.3.3-jdk-8').inside {
        // get the codez
        stage 'Checkout'
        git url: 'https://github.com/damnhandy/Handy-URI-Templates.git'
        stage 'Build'
        // Do the build
        sh "./mvnw clean install"
    }
}
```

这个管道会在一个名为"test-agent"的Jenkins代理上执行，它会基于“maven”3.3.3-jdk-8”镜像构建一个容器。这个管道在物理节点上能正常运行，但是在容器中运行则会报错。


## 运行在Docker中的Docker

在容器中运行Jenkins的主或从节点，可能有人会以为我需要特权模式来使用"Docker in Docker"，但是我并没有，Jérôme Petazzoni发表了一篇文章[《要用Docker-in-Docker来构建持续集成环境？请三思》](https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/)，你应该参考一下这篇文章。


如果你还在使用wrapdocker的脚本，你应该问问自己为什么，因为这样用起来更简单：


```sh
docker run -v ${JENKINS_HOME}:/var/jenkins_home \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v $(which docker):/bin/docker -p 8080:8080 \
     -p 50000:50000 damnhandy/jenkins
```

这个命令会启动Jenkins并且在"Docker-in-Docker"中完成所有操作，所以并不需要特权模式来启动容器。

有个地方需要注意：在这里你不能用官方的Jenkins镜像，因为jenkins用户需要属于docker用户组，这样才能使用socket，从而能在容器中的Jenkins调用docker，最终实现通过Jenkins构建和运行其他容器。

## Jenkins JNLP代理容器

Jenkins代理容器的启动方式与主节点类似，它也需要连接docker的socket接口，你可以这样启动：


```sh
docker run -v ${JENKINS_HOME}:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/bin/docker --name=jenkins-slave \
    -d damnhandy/jenkins-slave -url http://192.168.99.100:8080/ \
    a0a1b92971030d5f5dd69bd972c6cd899f705ddd3699ca3c5e92f937d860be7e 
test-agent
```

与Jenkins主节点一样，你需要确保jenkins用户有权限访问docker socket接口，我使用的是Jenkins JNLP从节点容器，并且添加了相应的用户组，这样，这个代理容器就可以执行构建操作了。

## 准备就绪，开始构建

在容器中开始一个构建过程不难，问题是你必需让这个代理容器绑定一个宿主机上的路径<code>${JENKINS_HOME}:/var/jenkins_home</code>，而且被构建的容器也需要这个目录的访问权限。Cloudbees Docker Pipeline插件会执行<code>docker.inside()</code>方法：


```sh 
docker run -t -d -u 1000:1000 -w /var/jenkins_home/workspace/uri-templates-in-docker \
-v /var/jenkins_home/workspace/uri-templates-in-docker:/var/jenkins_home/workspace/uri-templates-in-docker:rw \
-e ******** -e ******** -e ******** -e ******** -e ******** -e ******** -e ******** -e ******** \
-e ******** -e ******** -e ******** -e ******** -e ******** -e ******** -e ******** -e ******** \
maven:3.3.3-jdk-8 cat
```

这个容器会把宿主机上的 /var/jenkins_home/workspace/uri-templates-in-docker目录挂载到容器化环境以供Maven使用，并且会把这个路径设置成当前工作路径，这些在物理机上都能正常运行，但是要在容器中执行，我需要尝试这样做：


![pic](https://damnhandy.files.wordpress.com/2016/03/host-volumes1-e1458156340984.png)

这样明显不行，因为我把docker socket端口映射到了Jenkins代理容器上，挂载到Jenkins agent容器的所有卷实际上都是引用宿主上的路径，假定宿主上的<code>${JENKINS_HOME}</code>是<code> /opt/jenkins_home</code>，以下的命令应该生效：


```sh
docker run -t -d -u 1000:1000 -w /opt/jenkins_home/workspace/uri-templates-in-docker \
-v /opt/jenkins_home:/var/jenkins_home/workspace/uri-templates-in-docker:rw \
-e ******** 
maven:3.3.3-jdk-8 cat
```

但是这种方式有几个问题：

* 因为我们在使用“docker-in-docker”，获取宿主的路径会很麻烦。
* 这样不具备可移植性，因为容器需要依赖于宿主上的目录结构。

以下我将使用更好的方法。

## Docker数据卷容器之美

我经过18个月才明白为什么需要一个容器来存储数据，现在我明白了，在这个用例中，使用docker的数据卷容器在多个容器中共享数据异常优雅，它提供了简洁的抽象，并且还不依赖于宿主环境。用数据卷容器，最终实现了这样的架构：


![pic](https://damnhandy.files.wordpress.com/2016/03/data-volume-container1.png)

Docker 1.9以上的版本能创建命名卷了，现在要使用这个特性还有几个问题：

* 文档非常缺乏（其实是根本没有）。
* 数据卷会总是属于root用户，这个会在Docker 1.11才修复。

我使用的环境是Amazon ECS，它使用的是Docker 1.9，我还是会使用数据卷容器，以这个命令创建:


```sh
docker create --name=jenkins-data damnhandy/jenkins-data
```

启动Jenkins代理：

```sh
docker run --volumes-from=jenkins-data \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/bin/docker --name=jenkins-slave \
    -d damnhandy/jenkins-slave -url http://192.168.99.100:8080/ \
    a0a1b92971030d5f5dd69bd972c6cd899f705ddd3699ca3c5e92f937d860be7e test-agent
```

到现在，还剩下一个问题：Docker Pipeline插件仍然尝试挂载宿主上的路径，我们还需要修改一下它的配置：

```js
node('test-agent') {
    // Get some code from a GitHub repository
    git url: 'https://github.com/damnhandy/Handy-URI-Templates.git'
    sh 'docker run -t -u 1000:1000 --volumes-from=jenkins-data -w /var/jenkins_home/workspace/uri-templates-in-docker maven:3.3.3-jdk-8 ./mvnw package'
}
```

这样就基本上成功了。


## 总结

把构建环境容器化是一个非常好的主意，这样节省了很多时间。我把整个构建过程用到的相关代码放在了github上:

https://github.com/damnhandy/jenkins-pipeline-docker

注意，这份代码可能不正正满足你的需求，但是起码是一个demo，我希望本文能帮助更多人用上Jenkins的容器来构建应用，同时也能让大家对docker的数据卷更加熟悉。