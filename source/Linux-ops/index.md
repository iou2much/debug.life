title: Linux 下常用运维命令 / Hadoop 排错
date: 2016-01-21 16:31:36
tag:
- Linux 
toc: true
layout: false
---

<html lang="en"> <head> <meta charset="utf-8" /> <meta name="viewport" content="width=1024" /> <meta name="apple-mobile-web-app-capable" content="yes" /> <link href="/css/impress.css" rel="stylesheet" /></head> <body style="background:url('http://www.dvd-ppt-slideshow.com/images/ppt-background/background-11.jpg');"> 
<div data-transition-duration="1000" id="impress">
<div data-x="0" data-y="0" data-z="800" data-rotate-x=90 data-rotate-y=90 data-rotate-z=-90 class="step" id="start1">

## 资源管理
### 硬盘
- df
- fdisk

### cpu
- top
 - M
 - P
 - c
 - 1
 - -H

### 内存
- free 

### 负载
- uptime

### 网络
- netstat -anp
- lsof -P |grep xxx
- ifconfig
- /etc/hosts
</div><div data-x="1024" data-y="800" data-z="-800" data-rotate-x=90 data-rotate-y=90 data-rotate-z=90 class="step">
## 进程管理
### 进程查看
- ps aux
- top

### 进程管理
- kill
- killall
</div><div data-x="2048" data-y="0" data-rotate-x=90 data-rotate-y=-90 data-rotate-z=90 class="step">
### 文本编辑

#### vim
- 导航
 - G
 - gg
 - 0 / $
 - w / b
 - %
 - set nu
 - set ignorecase
 - dd / yy / p
 - u / Ctrl + R
 - ZZ / :wq / :x
 - Ctrl + V 
 - J
 - number + gg
- 复制/粘贴
![vim](http://7xpy3x.com1.z0.glb.clouddn.com/VIM%E9%94%AE%E7%9B%98%E5%9B%BE.png)
</div><div data-x="3072" data-y="200" data-z="400" data-rotate-x=90 data-rotate-y=-90 data-rotate-z=-90 class="step">

## 日志查看

### 文件查找
- find
- whereis
- locate

### 内容查看
- grep
- tail
- head
- cat
- more
</div><div data-x="4096" data-y="-200" data-z="-2000" data-rotate-x=-90 data-rotate-y=-90 data-rotate-z=-90 class="step">


## 系统维护
### 环境变量
- source
- /etc/profile

### 用户管理
- groupadd
- useradd
- passwd
- su / sudo

### 权限分配
- chown 
- chmod

### 远程操作
- ssh 登录、远程执行
- ssh-keygen
- ssh-copy-id

</div><div data-x="5120" data-y="-800" data-z="2000" data-rotate-x=-90 data-rotate-y=-90 data-rotate-z=-90 class="step">

## 文件操作
- mv
- cp
- rm 
- ls -tr / -a 
- ln -s
- tar zvxf / zvcf 
- zip / unzip
- scp / rsync
</div><div data-x="6044" data-y="-200" data-z="-3000" data-rotate-x=360 data-rotate-y=-90 data-rotate-z=-90 class="step">

## 终端常用快捷键/变量
- !$
- Ctrl + L
- Ctrl + R
- Ctrl + W
- Ctrl + U
- Ctrl + A
- Ctrl + E
- cd -
- xargs
- Ctrl + C
- Ctrl + Z / fg
</div><div data-x="7068" data-y="0" class="step">

## 问题跟踪
- Ambari上日志查看
- Hadoop日志路径

</div> <div id="overview" class="step" data-x="3000" data-y="1500" data-scale="10"></div></div><script src="/js/impress.js"></script><script src="/js/showdown.min.js"></script><script src="/js/jquery.min.js"></script> <script type="text/javascript"> impress().init();var converter=new showdown.Converter();var html=converter.makeHtml($('#start1').html());console.log(html);</script> </body> </html> 
