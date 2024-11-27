---
title: iTerm连接Remote Server
date: 2022-05-09 13:29:00
author: Harrison
categories:
  - "iTerm"
tags:
  - "Learning"
  - "iTerm"
  - "Server"

---
iTerm链接Remote Server，推荐使用2.0版本的免密登录~
<!-- more -->
## 一、1.0版本连接
### 0、前言

iTerm可以通过SSH链接远端server，常用命令是：`ssh <user>@<ip>`，然后输入密码即可连接服务器。

但是每次输入用户和IP较麻烦，因此可以写一个脚本，然后将脚本放在`/usr/local/bin`下，每次执行脚本即可登录服务器。

### 1、编写脚本

在`/usr/local/bin`目录下创建文件`serverLogin`(没有后缀)

```shell
#!/usr/bin/expect -f
  set user <user>
  set host <ip>
  set password <yourPasswprd>
  set timeout -1

  spawn ssh $user@$host
  expect "*assword:*"
  send "$password\r"
  interact
```

<user> <ip> <yourPasswprd> 换成自己的相关信息

Tips: 需要给`serverLogin`文件添加可执行权限

### 2、剧终

打开iTerm，输入serverLogin即可连接远端服务器。

## 二、2.0版本连接

通过命令：`ssh <user>@<ip>` 可以通过ssh连接服务器，但是需要输入服务器的密码才能连接成功，比较麻烦，其实是可以通过配置ssh的免密登录，来避免这个操作。
ssh免密登录配置：
+ 在客户端使用ssh-keygen生成密钥对：`ssh-keygen -t rsa -C "yourself_email@domain.com" -f ~/.ssh/id_rsa_server_login` 
+ 将生成的公钥（`id_rsa_server_login.pub`）添加到服务端的 `~/.ssh/authorized_keys` 文件中
+ - `echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..." >> ~/.ssh/authorized_keys`

此时在客户端通过指定私钥来连接服务器 `ssh -i id_rsa_server_login <user>@<ip>`。
可以在客户端执行`ssh-add -k ~/.ssh/id_rsa_server_login`将该私钥添加到ssh代理中，这样下次连接服务器时可以不需要指定私钥。
但是这样操作私钥信息只是缓存到内存中，客服端重启后，就需要再次执行`ssh-add`命令。

## 三、ssh免密登录原理：
当客户端SSH连接服务器时，客户端携带着公钥向服务器发出链接请求，服务器收到请求后，在 `~/.ssh/authorized_keys`信任文件里比对该公钥是否存在，如果对比成功，服务器则使用该公钥加密一个随机字符串，然后发送给客户端。客户端接收到该服务器回来的请求后，将随机字符串用自己的私钥进行解密，之后再将解密的结果传给服务器，服务器对比传来的字符串是否一致，一致则建立连接。·


## 四、scp文件上传
此时通过scp命令上传文件至服务器也可以不需要输入密码了，因为scp使用的是ssh协议。
在`/usr/local/bin`目录下创建文件`ulf`(没有后缀)，实现上传文件小工具：
```shell
#!/bin/sh

filePath=$*
echo $filePath
fileName=${filePath##*/}
echo "即将上传文件 >>$fileName<< 至服务器"
scp -i ~/.ssh/id_rsa_server_login $filePath root@<ip>:/home/root/
```
然后给`ulf`添加可执行权限`chmod +x /usr/local/bin/ulf`
