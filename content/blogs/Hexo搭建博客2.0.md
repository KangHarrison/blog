---
title: Hexo搭建博客
author: Harrison
date: 2022-05-10 18:12:00
categories:
  - "Hexo"
tags:
  - "Learning"
  - "Blog"
---

记录从0到1搭建Hexo博客2.0～

<!-- more -->
相比较与1.0，2.0的安装更便捷，使用GitHub Actions后部署方式更"fashion"～主要区别：
+ 使用yum安装nodeJs，手动安装的nodeJs在后续使用GitHub Actions中会存在执行hexo命令时报错，需要手动进行Hexo软链接的创建
+ 使用yum安装Nginx，便于nginx的启动（通过systemctl）
+ 使用GitHub Actions，只需将编写好的markdown push到main分支，便会重新部署，更加的"fashion"

### 0、Server上安装NodeJs（Hexo依赖NodeJs）
使用 `yum install nodejs`安装即可
安装完成后使用 `node -v` 和 `npm -v` 查看版本号，能成功查看则表示安装成功～
> tips：使用yum安装的node位于 `/usr/local/bin/node`；可以使用 `which node` 查看

### 1、Server上安装Hexo
+ 安装Hexo客户端（`npm install -g hexo-cli`）
+ 查看Hexo版本号（`hexo -v`）
> tips：使用npm安装的hexo位于 `/usr/local/bin/hexo`；可以使用 `which hexo` 查看

### 2、Server上初始化Hexo
+ 在home目录下创建blog文件夹，后续的博客文件都放到这个文件夹下
+ `cd blog`, 执行 `sudo hexo init`, 初始化Hexo
+ 执行 `hexo s` 可以启动hexo，并通过`http://yourIp:4000`可以访问
+ 通过 `hexo new "bolgName"` 可以创建博客，位于`blog/source/_post/`，之后可以编辑blobName.md来编写博客内容
+ 写好后，可以 `hexo clean` 清除缓存，再通过 `hexo g` 来生成
+ 此时再执行 `hexo s` ，然后`http://yourIp:4000`就可以看到更新后的博客

> tips:后续结合GitHub Actions，则不再需要执行 `hexo s` 启动hexo，只需通过 `hexo g` 生成静态文件让nginx访问即可。

### 3、Hexo + Nginx
+ Server上安装Nginx，`yum install nginx`
> 此时可以通过 `systemctl status nginx` 查看nginx的状态为：inactive (dead)
+ 编辑nginx的配置文件`/etc/nginx/nginx.conf`
> tips:利用yum安装nginx的配置文件在这个路径，而nginx脚本在 `/usr/sbin/nginx`
```
location / {
    # nginx的root映射为hexo生成的pulic目录，hexo g 后生成public目录
    root /root/blog/public;
    try_files $uri $uri/ /index.html;
}
```
+ 建议将hexo目录下的`_config.yml`中的`root`和`url`进行如下配置，否则生成后的JS和CSS文件可能无法读取：
```yaml
url: http://yourIp/
root: /
```
+ 启动nginx `systemctl start nginx`
> 此时可以通过 `systemctl status nginx` 查看nginx的状态为：active (running)
+ 此时通过IP即可看到自己的博客内容了。

### 4、GitHub Actions + Hexo + Nginx
+ 在自己的blog repo中创建部署工作流文件，例如：`.github/workflows/deploy.yml`
+ 在deploy.yml中：
```yml
name: Deploy site files

on:
  push:
    branches:
      - main # 只在master上push触发部署
    paths-ignore: # 下列文件的变更不触发部署，可以自行添加
      - README.md
      - LICENSE

jobs:
  deploy:
    runs-on: ubuntu-latest # 使用ubuntu系统镜像运行自动化脚本

    steps: # 自动化步骤
      - uses: actions/checkout@v2 # 第一步，下载代码仓库

      - name: Deploy to Server # 第二步，rsync推文件
        uses: AEnterprise/rsync-deploy@v1.0 # 使用别人包装好的步骤镜像
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }} # 引用配置，SSH私钥
          ARGS: -avz --delete --exclude='*.pyc' # rsync参数，排除.pyc文件
          SERVER_PORT: '22' # SSH端口
          FOLDER: ./blogs # 要推送的文件夹，路径相对于代码仓库的根目录
          SERVER_IP: ${{ secrets.SSH_HOST }} # 引用配置，服务器的host名（IP或者域名domain.com）
          USERNAME: ${{ secrets.SSH_USERNAME }} # 引用配置，服务器登录名
          SERVER_DESTINATION: /root/blog/source/ # 部署到目标文件夹
      - name: Restart server # 第三步，重启服务
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOST }} # 下面三个配置与上一步类似
          username: ${{ secrets.SSH_USERNAME }}
          key: ${{ secrets.DEPLOY_KEY }}
          # 重启的脚本，根据自身情况做相应改动
          script: | 
            cd /root/blog/source/
            ./deploy.sh
```

> 其中secrets.DEPLOY_KEY 、 secrets.SSH_HOST 、 secrets.SSH_USERNAME 为repo -> settings -> Secrets -> Actions 中配置的secret。

具体配置方式参考[这篇博客](https://frostming.com/2020/04-26/github-actions-deploy/)中的 `建立 SSH 密钥对` 和 `将自动化配置写到 GitHub 仓库` 这两小节

deploy.yml中最后一行执行的脚本为：
```shell
#!/bin/sh

rm -rf /root/blog/source/_posts
mv /root/blog/source/blogs /root/blog/source/_posts
/usr/local/bin/hexo clean
/usr/local/bin/hexo g
```