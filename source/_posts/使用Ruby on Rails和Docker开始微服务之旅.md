
title: 【译文】使用Ruby on Rails和Docker开始微服务之旅
date: 2016-02-13 18:22:33
toc: true
category: 翻译
description: 本文主要是介绍微服务与Docker环境，还有像Rails这样的框架怎么运行在上边。另外，我们还会研究微服务的基础服务，像Docker、Giant Swarm，还有如何在云平台上运行这些服务。
---

本文作者:[Dirk Breuer](https://twitter.com/railsbros_dirk).

本文主要是介绍微服务与Docker环境，还有像Rails这样的框架怎么运行在上边。另外，我们还会研究微服务的基础服务，像Docker、Giant Swarm，还有如何在云平台上运行这些服务。

今天我们谈论关于架构的话题，总离不开微服务，而微服务又会引向容器和Docker。但是这两个概念其实没有必然联系，它们共同点主要是：能简化庞大而复杂应用的构建过程。
 
对于微服务，没有一个像<code>apt-get</code>这样的工具，让人们可以问：“我怎样安装这个新东西？” 答案是：“你安装不了微服务。” 更具体来说是，“你不可能一下子就用上它。” 记住，“一个系统的架构是最难改变的”，“微服务”这个新事物也不是一颗银弹。即使在今天也没有人能轻易就重构一个复杂的系统，尤其是对于像用了Rails框架构造出来的庞大系统。

另一方面，Docker承诺的一个特性是，“减少开发、测试还有生产环境之间的差异” ，然而，在生产环境运行Docker并不简单，所以我们将研究Giant Swarm这样的工具是如何简化这个部署过程。

接下来我们开始探索之旅吧，作为开始我会把一个简单的应用Docker化，这个应用是一个NoSQL数据库ArangoDb的ODM。你能在Github上找到这个应用，如果你要自己尝试这个例子，你的机器上需要装好Docker，Ruby 2版本以上，还有一个用于部署的[Giant Swarm](https://giantswarm.io/)账号，不需要单独安装数据库，我们会在本地使用一个容器作为数据库。


**免责声明**: 本文中的部分内容是受这篇[《Docker化rails应用》](https://woss.name/articles/dockerising-a-rails-app/)启发，在这篇文章你能看到我没提及的更多细节。


## 各个击破

在我们制作Docker容器之前，先看一下这个应用的本身，以及我们将如何实现Docker化，我们手头上的应用是一个普通的Web工程：

- 一个前端
- 通过OAuth2使用GitHub登录
- 调用外部接口(GitHub)
- 后台长期运行的任务
- 主数据库
- 任务队列

我们可以把这些功能都放到一个容器中，但是这样会得不偿失。例如，我们会失去应用和数据库分离带来的可扩展性。遵循在每个容器[只运行一个进程的原则](http://blog.docker.com/2014/06/why-you-dont-need-to-run-sshd-in-docker/)，我们把应用分成5个容器：

1. Nginx会作为前端代理服务器，在我们的例子中它会提供静态资源，在更复杂的应用中，它可能会作为访问控制或者为后端服务提供负载均衡。

2. 第二层是Rails应用，它会运行在一个简单的web服务中，我们这里用的是Puma。

Sidekiq也会运行在一个独立的容器中，如果你有一个以上的队列，你需要为每一个队列创建一个容器。
3. 一个安装了Redis作为任务队列的容器。
4. 一个安装了ArangoDB作为主数据库的容器。

以下这幅图帮助我们去理解这个架构，以及组件之间的通讯：

![pic](http://blog.giantswarm.io/content/images/2015/04/swarm-architecture.jpg)

把Sidekiq放到一个单独的容器运行还和微服务架构差很远，但这已经使这个应用有不错的隔离性，使每个服务都在各自的工作进程中。


## 各个组件

现在我们已经指定了各个容器的功能，现在就要动手创建它们了。Docker容器是基于[Dockerfile](https://docs.docker.com/reference/builder/)构建的，这个文件描述了每一个构建步骤。前面说到我们需要五个容器，对应地需要五个Dockerfile。

不过幸运的是，这些容器可以共享同一个镜像。我们不需要额外的定制镜像就可以直接用了，你能找到各种应用的镜像，当然种类最多还是数据库。

### 数据库

我们将使用官方的Redis和ArangoDB镜像，通过以下命令运行：

```sh
# 会运行Redis并把端口暴露到宿主机
$ docker run --name redis -d redis

# 会运行ArangoDB并把端口暴露到宿主机
$ docker run --name arangodb -d arangodb/arangodb
```

这两个命令会从官方的镜像库获取到镜像，以后台方式(<code>-d</code>)启动，并且分配了一个名称(<code>--name</code>)，它们都会分配到一个卷还有默认的端口。对于ArangoDB，至少应该为生产环境配置[权限认证](https://docs.arangodb.com/ConfigureArango/Authentication.html)的设置。

### Nginx 前端代理

记住，Docker容器应该是被看作不可变的，改变应该发生在构建时而不是运行时，这个要在每次更改时重新构建镜像。对于Nginx前端，我们需要这样一个更改：指定一个配置文件来代理Rails应用。因为Docker镜像每次构建时都使用一个已经存在的镜像，我们使用了官方的Nginx镜像作为基础镜像：

```sh 
FROM nginx

RUN rm -rf /usr/share/nginx/html
COPY public /usr/share/nginx/html
COPY config/deploy/nginx.conf /etc/nginx/conf.d/default.conf
```

Dockerfile的开头总是<code>FROM</code>语句，它告诉Docker要继承于哪个基础镜像。另外我们只需要<code>COPY</code>这个public目录和配置到镜像中，正如我前边所说，容器应该被看作不可变的，每当需要改变这些资源时，我们应该创建一个新的镜像。Nginx的配置如下：

```sh
server {
    listen       80;
    server_name  localhost;

    location / {
        root      /usr/share/nginx/html;
        index     index.html index.htm;
        try_files $uri/index.html $uri.html $uri @upstream;
    }

    location @upstream {
        proxy_pass http://rails-app:8080;
    }
}
```
还有一件事应该提一下：这个<code>rails-app</code>主机名从哪里来的呢？Docker将提供两种方法去连接容器（我们会解释这点）,一串环境变量和<code>/etc/hosts</code>文件。在这个例子中，我们使用了<code>/etc/hosts</code>。

### Rails应用和Sidekiq Worker

现在我们添加Nginx代理的后端服务:Rails应用。官方有个[Rails Dockerfile](https://github.com/docker-library/rails/blob/cedbbc335ac4520c838e2921257ad1809c734c9a/onbuild/Dockerfile)，但我们不会用它，因为它会安装一些我们不需要的组件，更糟的是它安装bundle的时候没用<code>--deployment</code>参数。尽管如此，我们还是用它作为指引：


```sh
FROM ruby:2.1.5

# 如果Gemfile被修改过则抛出错误
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN bundle install --deployment

COPY . /usr/src/app/

ENV RAILS_ENV production

EXPOSE 8080

CMD ["/usr/src/app/bin/rails", "server", "-p", "8080"]
```

不用Docker我们可以部署类似Capistrano之类的应用，而现在，需要在远程服务器上操作的步骤，我们可以在构建Docker镜像时就完成了。诸如安装gem包和复制代码到服务器，通过这样，我们有了一个在任何地方任何时间都能启动的容器，而且它的状态和我们最初构建它的时候一模一样。

Sidekiq Worker的Dockerfile基本和上边的一样，比直接复制这个Dockerfile更好的方式是，定义一个公用的基础镜像，用于构建Rails应用和Sidekiq Worker。我会把这个作为读者的练习，如果你有好的想法，欢迎向[Github项目](https://github.com/railsbros-dirk/github_recommender/)提交代码。

### 构建容器 

Docker期待的是一个Dockerfile而我们例子中已经有三个了，我把每个Dockerfile加上了一个有意义的后缀，但是使用Docker命令时会重命名这些文件。如果有一个工具可以用来实现这个，那就是[Rake](https://github.com/ruby/rake):


```sh
namespace :docker do
  task :build => ['docker:build:web', 'docker:build:app', 'docker:build:worker', 'assets:clobber']

  namespace :build do
    task :web => ['assets:precompile', 'assets:clean'] do
      sh 'ln -snf Dockerfile.web Dockerfile'
      sh 'sudo docker build -t "registry.giantswarm.io/yoshida/gh-recommender-web" .'
      sh 'rm -f Dockerfile'
    end
    
    task :app => ['assets:precompile', 'assets:clean'] do
      sh 'ln -snf Dockerfile.app Dockerfile'
      sh 'sudo docker build -t "registry.giantswarm.io/yoshida/gh-recommender-app" .'
      sh 'rm -f Dockerfile'
    end

    task :worker do
      sh 'ln -snf Dockerfile.worker Dockerfile'
      sh 'sudo docker build -t "registry.giantswarm.io/yoshida/gh-recommender-worker" .'
      sh 'rm -f Dockerfile'
    end
  end
end
```

web和app的构建都需要使用<code>RAILS_ENV=production</code>，因为我们要这些文件都是给生产环境而不是开发环境生成的。<code>-t</code>参数会指定目标镜像的仓库名称，这对下一步把镜像推到云上是必须的。

### 转移到云上

目前为止我们已经有了一个完整的本地环境，这很好，但是如果我们想真正要的是对外的环境，至少还要几步。

任何人都可以配置服务器来运行我们基于Docker的应用。但是这样的话我们就要面对各种挑战：把容器链接在一起，扩展容器，管理跨节点的容器，还有更多。幸运的是，你可以直接使用Giant Swarm，这些它都帮你考虑了。首先你需要获取一个邀请码，你注册之后就可以使用swarm命令行工具去配置你本地的机器了。第一件要做的事是创建一个<code>swarm.json</code>:

```json
{
  "name": "github_recommender",
  "components": {
    "arangodb": {
      "image": "arangodb/arangodb",
      "ports": [
        "8529/tcp"
      ],
      "volumes": [
        {
          "path": "/data",
          "size": "5 GB"
        }
      ]
    },
    "nginx": {
      "image": "registry.giantswarm.io/yoshida/gh-recommender-web",
      "ports": [
        "80/tcp"
      ],
      "domains": {
        "80/tcp": [
          "gh-recommender.gigantic.io"
        ]
      },
      "links": [
        {
          "component": "rails-app",
          "target_port": "8080/tcp"
        }
      ]
    },
    "rails-app": {
      "image": "registry.giantswarm.io/yoshida/gh-recommender-app",
      "ports": [
        "8080/tcp"
      ],
      "env": [
        "RAILS_ENV=production",
        "SECRET_KEY_BASE=$secret_key_base",
        "REDIS_URL=redis://redis:6379",
        "GITHUB_KEY=$github_key",
        "GITHUB_SECRET=$github_secret"
      ],
      "links": [
        {
          "component": "arangodb",
          "target_port": "8529/tcp"
        },
        {
          "component": "redis",
          "target_port": "6379/tcp"
        }
      ]
    },
    "redis": {
      "image": "redis",
      "ports": [
        "6379/tcp"
      ]
    },
    "sidekiq-worker": {
      "image": "registry.giantswarm.io/yoshida/gh-recommender-worker",
      "env": [
        "RAILS_ENV=production",
        "SECRET_KEY_BASE=$secret_key_base",
        "REDIS_URL=redis://redis:6379"
      ],
      "links": [
        {
          "component": "arangodb",
          "target_port": "8529/tcp"
        },
        {
          "component": "redis",
          "target_port": "6379/tcp"
        }
      ]
    }
  }
}
```

这里你定义了整个应用和组件之间的关联关系，回想一下Nginx的配置，我们使用了http://rails-app:8080作为后端地址，这就是我们定义的地方。rails-app组件会被链接到Nginx组件，同样，REDIS_URL也被关联到了redis组件。

我们不想在<code>swarm.json</code>中放置敏感信息（例如Github OAuth2的token）我们可以单独在一个<code>swarmvars.json</code>文件中定义这些变量：

```sh
{
    "GIANT_SWARM_USER/dev": {
        "github_key": "GITHUB_KEY",
        "github_secret": "GITHUB_SECRET",
        "secret_key_base": "SECRET_KEY_BASE"
    }
}
```

我们可以使用例如<code>$github_key</code>关联这些变量到<code>swarm.json</code>，当应用在Giant Swarm上运行时，各个容器会使用适当的<code>--link</code>和<code>--env</code>选项。为了使所有服务都能从外部访问，我们需要指定域名到至少一个组件，Nginx是我们的入口，所以我们把域名指定到它上。

在我们启动应用之前，我们首先需要上传镜像到Giant Swarm的镜像库上(当然你也可以推到Docker Hub上，但可能你不想你的镜像能被公开访问）：


```sh
$ docker push registry.giantswarm.io/yoshida/gh-recommender-web
$ docker push registry.giantswarm.io/yoshida/gh-recommender-app
$ docker push registry.giantswarm.io/yoshida/gh-recommender-worker
```

你的网络状况会直接影响这个上传过程，一旦上传完成，就可以用这个命令启动所有容器：


```sh
$ swarm up
```

这个命令会从仓库中获取所有需要用到的镜像，然后以适合的参数启动各个容器，收集所有容器的日志，并且在http://gh-recommender.gigantic.io 下部署好了应用。整个过程异常简洁。

如果你已经到了这步，恭喜你！

### 扩容

现在我们为每个组件都使用了一个容器，当你的应用吸引了更多的用户，或者突然发生了不可预见的事件需要更加多的资源。传统的做法是添加更多的服务器，需要一系列的人工操作：启动机器，搭建好环境并且添加节点到负载均衡中。使用Giant Swarm的话，添加一个实例非常简单：

```sh
$ swarm scaleup github_recommender/gh-recommender/rails-app
```

这样减轻了很多技术负担，但是它并不能使你的应用魔法般地就支持水平扩展，当它在数据库应用上就更加复杂了，你还需要研究怎样使应用支持扩展。但是这样至少你可以专注于这块，而不需要担心基础设施的细节了。

## 结论

在本文中谈及的就是这些了，在这主题下，还有更多的东西可以讨论和学习。我希望我起码可以带你们入门，如果你想走得更远，这里有几点建议主题，是本文没有提及但是密切关联的：

- 我在开头说过，容器也能在本地开发环境使用，而它也应该这样使用，但我们在本文没有涉及如何实现。

- 无论在本地或者生产环境下，调试容器都是一个比较大的问题。正如它的其他方面，这个也没有银弹，可能也永远不会有。但是这也是需要注意的地方。

- 在Docker世界中，安全也是一个大问题，使用Giant Swarm会有所帮助，我们需要熟悉容器和Docker可能带来的安全性问题。我这里说的不是安全漏洞，而是与传统部署方式之间的不同，例如像安装或管理虚拟机那样。

另外，我强烈建议你自己打包镜像，而不依赖于公共共镜像库。不然最终你会需要很多不同的镜像，例如，例子中的五个容器就需要三个不同的Linux分发版。

还有，我们尝试在每个容器中只启动一个进程，虽然这是Docker官方的建议，但这是有争议的，是否必须这样做我觉得都没问题，你应该具体问题具体分析，根据实际情况做出这个决定。

别从微服务开始，要从Docker开始。熟悉相关的工具范例，还有使用过程中出现的问题，还有它对现存工具和进程的影响。你应该先熟悉这些，再把你的应用分割成一个个小块。我强烈建议一步一步实现。

我不认为每个人都需要在近期切换到Docker平台，但容器化技术它本身就很是有趣的技术，它现在已经足够稳定，即使是一个初学者也能很容易入手。学习在一个简单的应用中使用这门技术，并且在Giant Swarm上练习，是一件值得立即动手的事。
