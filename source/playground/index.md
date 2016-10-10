---
title: The Lab
layout: normal
---

<div ng-cloak ng-class="{'vis-hidden': is_login}">未登录用户请登录公用终端 host : <code>guest</code> / 用户 : <code>guest</code> / 密码: <code>guest</code> 登录</div> <div ng-cloak ng-class="{'vis-hidden':  !is_login || is_has_container}"> 尚未创建容器,请先创建您的专属容器. <md-button id="crt_btn"  class="md-raised " ng-click="create_container()">创建容器</md-button> </div> <table class="table" ng-class="{'vis-hidden':  !is_has_container || !is_login}"> <tr><td> 主机名</td><td><span ng-bind="host"></span> </td><td></td></tr> <tr><td>用户名</td><td><span ng-bind="user"></span> </td><td></td></tr> <tr><td>密码</td><td><md-button ng-click="show_pwd()" class="md-raised "><span class="glyphicon glyphicon-eye-open" aria-hidden="true"></span>显示密码</md-button><span ng-show="!is_show_pwd">****************</span><span ng-show="is_show_pwd" ng-bind="pwd"></span></td><td></td></tr> </table>

<md-button class="md-raised " ng-click="show_help()"> 使用帮助 </md-button>
<div ng-cloak  ng-class="{'vis-hidden': !is_show_help}" >
- 点击登入

![进入](http://7xpy3x.com1.z0.glb.clouddn.com/ssh-1.png)

- 输入主机名
![输入主机名](http://7xpy3x.com1.z0.glb.clouddn.com/ssh-2.png)

- 输入用户和密码
![输入用户名和密码](http://7xpy3x.com1.z0.glb.clouddn.com/ssh-3.png)

这样，就可以进到容器里头操作了。装的依赖包不多，但是基本的Linux指令都可以玩起来了~ 

</div>

<script src="https://linux.debug.life/static/gateone.js">
</script>
