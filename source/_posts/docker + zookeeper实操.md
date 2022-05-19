---
title: docker + zookeeper实操部署grpc-kit
date: 2022-05-09 13:52:00
author: Harrison
categories:
  - "Java"
tags:
  - "gRPC"
  - "docker"
  - "zookeeper"

---
docker + zookeeper实操部署grpc-kit
<!-- more -->

docker + zookeeper实操部署grpc-kit

grpc-kit的项目地址：[grpc-kit](https://github.com/KangHarrison/grpc-java-kit/)

1、先通过`docker run -d -p 2181:2181 --rm --name zookeeper-test zookeeper:3.7.0`在docker中启动zk。

2、zk启动成功后，就可以在项目中运行测试类`GreeterServiceTest`。若启动成功的话，可以打开zkCli查看server是否已经注册到zk中，具体操作如下：
> + 在终端中输入`docker exec -it zookeeper-test sh`，表示在容器zookeeper中以交互模式执行容器内shell
> + 此时通过`ls -al`查看到容器内目录结构，然后进入bin目录，在bin目录下可以看到一些shell脚本，比如：zkCli.sh（zk客户端脚本）
> + 通过`./zkCli.sh`运行zkCli.sh
> + 在zkCli中，通过`ls -R /`就可以看到所有注册到zk中的节点。
> 具体的zkCli语法可查看[这里](https://zookeeper.apache.org/doc/r3.6.0/zookeeperCLI.html)
> + 最后通过`quit`就可以退出zkCli

