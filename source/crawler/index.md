---
title: crawler
layout: normal
---

<md-input-container> <label>URL</label> <input ng-model="url" type="url"> </md-input-container>
<md-button class="md-primary" ng-click="crawl()">抓取</md-button>
<md-content ng-bing="content" flex layout-padding></md-content>


