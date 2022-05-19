---
title: Hexo搭建博客
author: Harrison
date: 2022-01-17 18:12:00
categories:
  - "Hexo"
tags:
  - "Learning"
  - "Blog"
---

记录从0到1搭建Hexo博客～

<!-- more -->
### 0、安装NodeJs（Hexo依赖NodeJs）
1、安装NodeJs，官网下载（https://nodejs.org），然后一路next安装。
2、安装完后，可以切换至root用户（终端输入：	`sudo su`），查看node版本（终端输入：`node -v`）
3、切换镜像源(`npm install -g cnpm --registry=https://registry.npm.taobao.org`)，镜像源切换为淘宝


### 1、安装Hexo
1、利用淘宝镜像安装Hexo客户端（`cnpm install -g hexo-cli`）
2、查看Hexo版本号（`hexo -v`）

### 2、初始化Hexo
1、创建blog文件夹，后续的博客文件都放到这个文件夹下
2、`cd blog`, 执行 `sudo hexo init`, 初始化Hexo
3、执行 `hexo s` 可以本地启动hexo，并通过http://localhost:4000可以访问
4、通过 `hexo new "bolgName"` 可以创建博客，位于`blog/source/_post/`，之后可以编辑blobName.md来编写博客内容
5、写好后，可以 `hexo clean` 清除缓存，再通过 `hexo g` 来生成
6、此时再 `hexo s` ，然后在本地浏览器就可以看到自己写的博客

### 3、让Hexo博客在后台跑起来
1、安装pm2，`npm install -g pm2`
2、编写执行脚本，在博客根目录下创建一个文件`run.js`
```js
//run.js
const { exec } = require('child_process')
exec('hexo server',(error, stdout, stderr) => {
  if(error){
    console.log(`exec error: ${error}`)
    return
  }
  console.log(`stdout: ${stdout}`);
  console.log(`stderr: ${stderr}`);
})
```
3、执行脚本，进入博客根目录，`pm2 start run.js`
4、这时候我们即使关闭终端，我们的博客也依然会在服务器上运行，问题就解决啦
并且通过 git 我们可以方便的管理我们的文章，git 拉取后博客内容也会自动更新 !

### 4、Hexo + Nginx
1、服务安装Nginx，参考这片博客：[安装Nginx](https://www.cnblogs.com/boonya/p/7907999.html)，或者这篇[安装Nginx](https://www.jianshu.com/p/97cdbeebef96)。二选一即可。
2、编辑nginx的配置文件`/usr/local/nginx/conf/nginx.conf`，我的Nginx安装在`/usr/local/`目录下。
```
location / {
    # nginx的root映射为hexo生成的pulic目录，hexo g 后生成该目录
    root /root/blog/public;
    try_files $uri $uri/ /index.html;
}
```
3、建议将hexo目录下的`_config.yml`中的`root`和`url`进行如下配置，否则生成后的JS和CSS文件可能无法读取：
```yaml
url: http://yourIp/
root: /
```
4、启动Nginx，此时通过IP即可看到自己的博客内容。

