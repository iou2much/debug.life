title: 【debug.life构建手记】 ( 二 ) Hexo静态博客搭建及配置
date: 2016-01-24 02:48:39
tags: 
 - hexo 
 - Node.js 
 - Mac OS X
description: 本文将介绍如何使用Hexo搭建静态博客
toc: true
category: Tools
---
	

debug.life是基于Hexo来编写以及构建的，本文将为大家介绍Hexo的使用。

## hexo简介
[Hexo](https://hexo.io/zh-cn/) 是一个非常轻量级的博客框架，是一位台湾大学生[tommy351](https://twitter.com/tommy351)用Node.js开发的，使用起来非常方便，我更喜欢它的灵活，通过Hexo最终生成的是一些静态页，能让我能非常方便地在页面上作一些二次开发。

本文将介绍如何在Mac OS上使用Hexo，如何部署到阿里云上，以及我所使用的Hexo相关配置。

## 环境准备
正如前边所说，Hexo是以Node.js开发的，我们要使用的话首先得具备Node.js环境，以下几步如果你的Mac上已经装过了，请酌情跳过。

***注意 : 以下操作皆需要在终端执行***

### 安装Homebrew
我是用了[Homebrew](http://brew.sh/)来安装[Node.js](https://nodejs.org)的，[Homebrew](http://brew.sh/)是MacOS上非常好用的包管理器，类似CentOS上的yum或者Ubuntu上的apt-get。如果你还没用过的话首先安装一下，按Homebrew官网上的命令安装：

```sh
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
### 安装Node.js

brew安装成功后，安装nodejs：

```sh
brew install nodejs
```
### 安装hexo
安装成功后，你电脑上就已经有Node.js的基础开发环境了，我们今天用到的是里头[npm](http://www.infoq.com/cn/articles/msh-using-npm-manage-node.js-dependence)这个工具，它是Node.js 的模块依赖管理工具，我们需要用它来安装hexo：

```sh
npm install hexo-cli -g
```

安装成功后，验证一下有没安装成功：

```sh
hexo -v
```

![hexo-v](http://7xpy3x.com1.z0.glb.clouddn.com/hexo-v.png)

如果能看到类似这些信息，那恭喜你，hexo已经安装好在你的Mac上了。

## Hexo初步使用

其实上边的<code>hexo -v</code>已经暴露了它的本质——它是一个命令行工具，所以要使用它，我们还是得留在这黑乎乎的终端。那接下来，我将介绍hexo的基本操作。


### 新建博客站点

首先要为你的站点选择一个存放的目录，我首先进到了test这个目录下，执行：

```sh
hexo init debug.life
```
完成后可以看到，这个命令已经在当前路径下生成了debug.life目录，并且里边已经有一些初始化的内容：

![hexo-1](http://7xpy3x.com1.z0.glb.clouddn.com/hexo-1.png)

这里简单介绍一下这些文件或者目录的作用：

- _config.yml
	- 这是整个站点的配置文件,具体配置见[官方文档-配置](https://hexo.io/zh-cn/docs/configuration.html)；
- source
	- 从名字也能看出来，这个目录是用于存放源文件，主要放置的是博客文章，和一些资源文件(图片或者js/css等)；
- themes
	- 这个是存放主题的目录；
- scaffolds
	- 这是hexo内置的文章模板，通常不用改动。
- package.json
	- 这是node.js的依赖描述文件，里边定义了站点的依赖包。

***注意：以下命令都需要在站点的根目录下执行***

### 安装相关依赖

在继续管理这个站点之前，需要再安装几个hexo插件。这几个插件会增强hexo的功能，在安装前可以<code>hexo help</code>看一下：

![hexo-3](http://7xpy3x.com1.z0.glb.clouddn.com/hexo-3.png)

可以看到只有三个Commands,接着我们用以下命令安装插件，这个命令会把<code>package.json</code>中的依赖都下载到本地：

```sh
npm install

```

安装成功后，可以在debug.life目录下见到新增了一个<code>node_modules</code>目录，这目录中包含了node.js的依赖。从<code>hexo help</code>可以看到hexo的命令多了不少：

![hexo-4](http://7xpy3x.com1.z0.glb.clouddn.com/hexo-4.png)


简单介绍一下几个插件：

- hexo
	- 这个依赖与之前的<code>hexo-cli</code>不同，它是用于管理站点的组件。
- hexo-deployer-rsync
	- 我之后会使用rsync把站点上传到阿里云，使用这个插件实现一键部署。
- hexo-server
	- 这个插件实现在本地启动一个HTTP服务，能让我们本地预览调试站点。
- hexo-generator-category
	- 这个插件使hexo支持文章分类功能
- hexo-generator-archive
	- 这个插件使hexo支持文章归档功能
- hexo-generator-tag
	- 这个使hexo支持文章添加标签

官网还有大量插件：[https://hexo.io/plugins/](https://hexo.io/plugins/)，多数是功能增强或者优化的，我暂时还没来得及把有用的全部挖掘出来，有待后续再慢慢探索。

### 安装主题

debug.life 使用的是[maupassant](https://github.com/tufu9441/maupassant-hexo)主题，在它的github介绍页可以看到安装方式：

```sh
git clone https://github.com/tufu9441/maupassant-hexo.git themes/maupassant
npm install hexo-renderer-sass --save
npm install hexo-renderer-jade --save
```

这三个命令会把maupassant下载到上边介绍的themes目录，并且安装两个node.js依赖。

在Hexo官网上还有很多高质量的主题可以选择：[https://hexo.io/themes/](https://hexo.io/themes/)

安装方式也大同小异，具体可以参考各个主题的主页。

### 添加博文

新建一篇文章，从结果中能看到新建的<code>md</code>文件路径。

```sh
hexo n test
```
![hexo-2](http://7xpy3x.com1.z0.glb.clouddn.com/hexo-2.png)

### 编辑博文

<code>md</code>是Markdown的缩写，Markdown是一种标记语言，用它来写文章或者写文档是一种非常好的体验，而且它非常容易上手，强烈推荐~

从简书上摘录了几点Markdown的优点：
> - 纯文本，所以兼容性极强，可以用所有文本编辑器打开。
> - 让你专注于文字而不是排版。
> - 格式转换方便，Markdown 的文本你可以轻松转换为 html、电子书等。
> - Markdown 的标记语法有极好的可读性。

> 	————摘自[《献给写作者的 Markdown 新手指南》](http://www.jianshu.com/p/q81RER)

现在很多博客平台都支持了Markdown语法，而在本地编辑通常需要使用专门的Markdown编辑器，这样才能边编辑边预览，在各个平台上都有一些非常优秀的Markdown编辑器，在Mac上，我选用了[Macdown](http://macdown.uranusjr.com/)，我的所有文章都是在这个编辑器中编写的，正如本文：

![macdown](http://7xpy3x.com1.z0.glb.clouddn.com/macdown.png)

### 站点配置

接着我们对站点作一些基本配置，可以从[官方文档-配置](https://hexo.io/zh-cn/docs/configuration.html)中查看各配置项的意义，不过也能从key的命名看出各配置的作用：

```json
# Hexo Configuration
## Docs: http://hexo.io/docs/configuration.html
## Source: https://github.com/hexojs/hexo/

# 
title: Debug my life.
subtitle: 在此记录我的程序人生...
description: Just take some log for myself...
author: Chibs Lee
language: zh-CN 
timezone: Asia/Shanghai

# URL
## If your site is put in a subdirectory, set url as 'http://yoursite.com/child' and root as '/child/'
# 配置站点的url，通常是域名
url: http://debug.life/
# 配置站点的根目录，如果没配置正常，很可能样式文件或js文件引用出错
root: /
# 文章的url模式
permalink: :year/:month/:day/:title/
permalink_defaults:

# Directory
# 以下这节通常留默认配置即可
source_dir: source
public_dir: public
tag_dir: tags
archive_dir: archives
category_dir: categories
code_dir: downloads/code
i18n_dir: :lang
skip_render:

# Writing
new_post_name: :title.md # File name of new posts
default_layout: post
titlecase: false # Transform title into titlecase
external_link: true # Open external links in new tab
filename_case: 0
render_drafts: false
post_asset_folder: false
relative_link: false
future: true
# 在文章中经常会引用代码，以下小节配置代码高亮：
highlight:
  enable: true
  line_number: true
  auto_detect: true
  tab_replace:

# Category & Tag
default_category: uncategorized
category_map:
tag_map:

# Date / Time format
## Hexo uses Moment.js to parse and display date
## You can customize the date format as defined in
## http://momentjs.com/docs/#/displaying/format/
date_format: YYYY-MM-DD
time_format: HH:mm:ss

# Pagination
## Set per_page to 0 to disable pagination
per_page: 10
pagination_dir: page

# Extensions
## Plugins: http://hexo.io/plugins/
## 指定了我刚刚下载的主题
theme: maupassant
plugins:
  - hexo-generator-feed
  - hexo-generator-sitemap
  - hexo-summarizer

# sitemap是给搜索引擎爬虫用的，配置了这个有助于SEO
sitemap:
  path: sitemap.xml
baidusitemap:
    path: baidusitemap.xml


# Deployment
# 使用rsync把静态文件同步到远程服务器上
deploy:
  type: rsync
  host: xxx.xxx.xxx.xx
  user: xxxx
  root: /home/xxxx/debug.life
  port: 22
  delete: true
  verbose: true
  ignore_errors: false

```
### 生成站点及本地预览

通过以下命令生成站点的静态文件，文件会生成在<code>public</code>目录中：

```sh
hexo g
```

<code>hexo g</code>是静态文件的生成，每次改动或者添加一篇文章都需要重新生成一次；

通过deploy命令在本地启动一个服务器，便于预览或调试：

```sh
hexo s
```

这两条命令的输出：

![hexo-5](http://7xpy3x.com1.z0.glb.clouddn.com/hexo-5.png)

<code>hexo s</code>启动后，可以通过默认端口访问：

![hexo-6](http://7xpy3x.com1.z0.glb.clouddn.com/hexo-6.png)


### 部署站点至阿里云

我在[前一篇文章](https://debug.life/2016/01/16/build-my-site-1/)已经在阿里云的ECS上配置好了一个Openresty服务器，站点的根配置在<code>/home/xxxx/debug.life</code>，那我在上边hexo的配置里，用了rsync的方式，把本地生成好的静态文件同步到ECS上。

另外为了方便，我对ECS作了密钥登录的配置。

首先，在Mac上生成密钥对：

```sh
ssh-keygen -t rsa
接下来按四下回车
```

接着，获取公钥：

```sh
cat ~/.ssh/id_rsa.pub
```
把这个命令的输出内容，copy到ECS上的对应用户下的<code>~/.ssh/authorized_keys</code>文件中，然后就可以在Mac上无须密码登录到ECS上了。

接着，用这个命令进行文件同步：

```sh
hexo d
```

<code>hexo d</code>是部署命令，会读取<code>_config.yml</code>中的配置进行部署。

## 小结
至此，本文已经介绍了一个Hexo站点的最基本新建、配置、添加文章及部署操作。下一篇文章会介绍Hexo的几点优化配置。



