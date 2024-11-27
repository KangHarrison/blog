---
title: Git多环境最佳实践
date: 2022-05-09 13:53:00
author: Harrison
categories:
  - "Git"
tags:
  - "Git"

---
Git多环境最佳实践~
<!-- more -->
### 一、什么是Git多环境
现在几乎所有的公司代码仓库都是Gitlab搭建的，我们自己学习也肯定要用Github的，而只却有一个git环境。那就需要使用本地的git管理Gitlab以及Github，一般这称之为git的多环境。
tips：当然公司代码仓库不一定是Gitlab，Gitee也是一样的，这里以Gitlab为例。

### 二、最佳实践
1、既然有多个环境，则每个环境应该有对应的ssh密钥和公钥，因此需要为每个环境先生成密钥和公钥
+ 为Github生成：终端执行`ssh-keygen -t rsa -C "yourself_email@domain.com" -f ~/.ssh/id_rsa_github`
+ 为Gitlab生成：终端执行`ssh-keygen -t rsa -C "your_company_email@domain.com" -f ~/.ssh/id_rsa_gitlab`

2、添加config，在~/.ssh下添加config配置文件（没有的话新建名为config的文件）
<b>tips:需要将gilab中的HostName换成公司的即可（一般是：gitlab.company.cn）</b>
```
# github key
Host github
    Port 22
    User git
    HostName github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_github
# gitlab key
Host gitlab
    Port 22
    User git
    HostName gitlab.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa_gitlab
```

3、将公钥配置到Gitlab或Github，具体怎么配置请google

4、测试
+ 终端执行`ssh -T git@github.com`，成功的话会返回successful

5、some errors
+ 提示需要输入Github或Gitlab密码，则在终端执行：`ssh-add -k ~/.ssh/id_rsa_github` 或 `ssh-add -k ~/.ssh/id_rsa_gitlab`
+ 遇到Github或Gitlab报permission denied错就在终端执行：`ssh-add -k ~/.ssh/id_rsa_github` 或 `ssh-add -k ~/.ssh/id_rsa_gitlab`

