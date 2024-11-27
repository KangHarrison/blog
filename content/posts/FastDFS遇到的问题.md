---
title: FastDFS 无法获取服务端连接资源问题
author: Harrison
date: 2020-08-15 17:27:23
categories:
  - "Problems"
tags:
  - "FastDFS"
---
FastDFS 无法获取服务端连接资源问题 mark~
<!-- more -->

"com.github.tobato.fastdfs.exception.FdfsConnectException: 无法获取服务端连接资源：can’t create connection to/ip:22122" 的解决方案。

之前在Github上clone了一个[微人事项目](https://github.com/lenve/vhr)，然后在本地虚拟机上安装了FastDFS，之前是测试通过了。但是今天再次使用FastDFS时，却报如下错误：
自己在本地搭建FastDFS项目，项目源码在[我的GitHub](https://github.com/kangkanglang/JavaLearning/tree/master/FastDFSTest)上。

> <font color=red>com.github.tobato.fastdfs.exception.FdfsConnectException: 无法获取服务端连接资源：can’t create connection to/192.168.xxx.xxx:22122</font>


现在提供以下3种解决办法：

#### 1. 检查项目application.yml配置文件中的IP地址是否正确（虚拟机的IP地址可能会发生改变）。

application.yml中关于FastDFS的配置：
```yml
# ===================================================================
# 分布式文件系统FDFS配置
# ===================================================================
fdfs:
  so-timeout: 6000
  connect-timeout: 6000
  thumb-image:             #缩略图生成参数
    width: 150
    height: 150
  tracker-list:            #TrackerList参数,支持多个
    - 192.168.xxx.xxx:22122
```
本人虚拟机的IP地址就发生了改变，遂要修改项目application.yml中的IP配置，同时也要修改虚拟机中关于storage的配置文件。
即将 ``` /etc/fdfs/storage.conf``` 配置文件中的IP修改成当前IP地址。
```bash
tracker_server=192.168.xxx.xxx:22122
```
经过上述2步修改后，将Tracker Server和Storage Server分别进行重启，即
```bash
service fdfs_trackerd stop # 关闭Tracker Server

service fdfs_trackerd start # 开启Tracker Server
```

```bash
service fdfs_storaged stop # 关闭Storage Server

service fdfs_storaged start # 开启Storage Server
```

#### 2. Tracker Server和Storage Server未启动

可通过以下命令检测两个Server是否启动
```bash
netstat -anp | grep 22122 # 检测Tracker Server是否启动
netstat -anp | grep 3000 # 检测Tracker Server是否启动
```
若未启动，则分别执行以上两个命令后，无任何输出；若是启动了，则输出如下内容：
```bash
# Tracker Server 启动
tcp   0   0.0.0.0:22122     0.0.0.0:*     LISTEN    1972/fdfs_trackerd

# Tracker Server 启动
tcp   0   0.0.0.0:23000     0.0.0.0:*     LISTEN    2056/fdfs_storaged
```
若是未启动，则分将两个Server启动即可：
```bash
service fdfs_trackerd start # 开启Tracker Server

service fdfs_storaged start # 开启Storage Server
```

### 3. 尝试关闭虚拟机的防火墙

不同系统关闭防火墙的方式各不一样，可自行寻找方法。
