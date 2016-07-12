title: 【译文】如何使用Docker开源仓库建立代理缓存仓库
date: 2016-01-10 00:50:23
toc: true
category: 翻译
---


>October 16, 2015 By [Matt Bentley](http://blog.docker.com/author/mbentley/)

[开源Docker仓库v2](https://github.com/docker/distribution)的其中一个最新特性,是能够被用作代理缓存仓库,以缓存Docker Hub上的镜像。运行一个缓存仓库允许你在本地储存镜像,减少过多的通过互联网从Docker Hub拉取镜像,这个特性对于一些在他们环境中拥有数量庞大的Docker引擎的用户来说很有用。跟着本篇教程,你可以让Docker引擎从本地代理缓存仓库拉取镜像,而不是让每个引擎总是从Docker Hub拉取,从而节省时间和带宽。

你可以这样开始：

#### 要求：
- Docker引擎1.8.3
- Docker仓库v2 
- 足够储存Docker镜像的磁盘空间
- TLS证书和密钥

####持久化数据
在这个例子中,我们会假设你会储存所有持久化数据在本地文件系统的<code>/data</code>路径下,这个路径下包含TLS证书和密钥文件,配置文件和镜像缓存文件。我们之后会用卷挂载这个目录进运行仓库的容器。

####保护你的代理缓存仓库安全
代理缓存仓库需要一个TLS证书来保证Docker引擎和缓存仓库之间的连接安全,在这个例子中,我们会放置我们证书文件(<code>domain.crt</code>)和密钥文件(<code>domain.key</code>)在主机的<code>/data</code>目录。

更多关于使用TLS加强仓库安全的信息,请参照[Docker仓库2.0文档](https://docs.docker.com/registry/deploying/#get-a-certificate)。

####创建代理缓存仓库配置文件
下一步你需要创建一个配置文件,来把这个仓库用作代理缓存。你可以用cat命令把<code>registry:2</code>镜像中的缺省配置文件重定向输出到一个文件中：

```sh
$ docker run -it --rm --entrypoint cat registry:2 \
/etc/docker/registry/config.yml > /data/config.yml
```

<code>我强烈建议从Docker镜像中获得这个默认配置,而不是使用例子中的配置,因为将来这个默认配置可能会有更新。</code>

####默认的config.yml例子：
```yaml
version: 0.1
log:
   fields
      service: registry
storage:
      cache:
         layerinfo: inmemory
      filesystem:
         rootdirectory: /var/lib/registry
http:
   addr: :5000
```

####修改'http'这节配置上TLS:
```yaml
http:
      addr: :5000
      tls:
            certificate: /var/lib/registry/domain.crt
            key: /var/lib/registry/domain.key
```
####在配置文件中新加一节'proxy'来开启缓存：
[点击打开文档](https://github.com/docker/distribution/blob/master/docs/mirror.md)

```yaml
proxy:
      remoteurl: https://registry-1.docker.io
      username: [username]
      password: [password]
```

'username'和'password'这两个设置是可选的,设置一组Docker Hub的用户名和密码会允许这个代理缓存仓库储存任何这个账号有权限获取的私有镜像,也就是说,这个用户有权限获取的镜像,这个缓存仓库同样有权限获取。

<code>请确保完全理解设置这个Docker Hub账号背后意味着什么,并且确保你镜像的安全还有严格的访问权限!如果你不确定,请不要在配置包含用户名和密码,那么你的代理缓存仓库就只会缓存公共镜像。</code>

####启动代理缓存仓库的容器：
```sh
$ docker run -d --restart=always -p 5000:5000 --name v2-mirror \
-v /data:/var/lib/registry registry:2 /var/lib/registry/config.yml
```

以上命令使用一个卷把宿主机上的/data挂载进了容器中,使容器能使用持久储存镜像缓存,TLS证书和密钥,还有自定义的仓库配置文件。


####验证你的代理缓存仓库已经启动并正常运行：

```sh
$ curl -I https://mycache.example.com:5000/v2/
HTTP/1.1 200 OK
Content-Length: 2
Content-Type: application/json; charset=utf-8
Docker-Distribution-Api-Version: registry/2.0
Date: Thu, 17 Sep 2015 21:42:02 GMT
```
####配置你的Docker引擎使用代理缓存仓库

修改Docker守护进程的启动参数,加上<code>--registry-mirror</code>选项：


```sh
--registry-mirror=https://<my-docker-mirror-host>:<port-number>
```

例如,如果你的缓存仓库的主机名为mycache.example.com并且仓库服务端口为5000,你需要加上以下选项到守护进程的参数：

```sh
--registry-mirror=https://mycache.example.com:5000
```
参考[在各种的Linux分发版中配置运行Docker](https://docs.docker.com/articles/configuring/)了解更多信息关于如何添加Docker守护进程参数。


####测试你的代理缓存仓库
从Docker Hub上拉取一个你本地没有的镜像。例如,busybox:latest镜像：
```sh
$ docker pull busybox:latest
```

检查缓存仓库中的目录,验证busybox镜像是否被缓存：
```sh
$ curl https://mycache.example.com:5000/v2/_catalog
{"repositories":["library/busybox"]}
```

你也可以验证latest标签是否被缓存：
```sh
$ curl https://mycache.example.com:5000/v2/library/busybox/tags/list
{"name":"library/busybox","tags":["latest"]}
```

现在开始当你拉取镜像时,镜像将被缓存到你的代理缓存仓库,之后拉取相同的镜像时会更快,并且这些镜像缓存会维护自身,当他们不再被使用时将会自动清除。

了解更多信息,请参考[文档](https://github.com/docker/distribution/blob/master/docs/mirror.md)。

[从这里下载Docker引擎](https://github.com/docker/distribution/blob/master/docs/mirror.md),并尝试创建用开源的Docker仓库创建代理缓存仓库吧！
