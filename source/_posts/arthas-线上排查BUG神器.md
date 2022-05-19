---
title: arthas-线上排查BUG神器
date: 2022-05-09 13:29:00
author: Harrison
categories:
  - "Arthas"
tags:
  - "Arthas"

---
arthas使用的简单介绍~
<!-- more -->

### 1. arthas介绍
[Arthas](https://arthas.aliyun.com/doc/)是Alibaba开co源的Java诊断工具，采用命令行交互模式，提供了丰富的功能，是排查jvm相关问题的利器

### 2. arthas整合到jdk镜像
#### 2.1 docker要求18版本以上
```
FROM centos:7.4.1708
MAINTAINER xx

COPY sources.list /etc/apt/sources.list
COPY --from=hengyunabc/arthas:3.1.3-no-jdk /opt/arthas /opt/arthas
RUN rm -rf /etc/yum.repos.d/CentOS-Base.repo
ADD CentOS-Base.repo /etc/yum.repos.d
RUN yum update -y && yum makecache
RUN rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime #修改时区
RUN yum -y install kde-l10n-Chinese && yum -y reinstall glibc-common #安装中文支持
RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 #配置显示中文

ADD jdk-8u161-linux-x64.tar.gz /usr/local/java

ENV TZ Asia/Shanghai
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN:zh
ENV LC_ALL zh_CN.UTF-8
ENV JAVA_HOME /usr/local/java/jdk1.8.0_161
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $PATH:$JAVA_HOME/bin

WORKDIR /usr/local/java/jdk1.8.0_161/jre/bin
#构建镜像命令
docker build -t jdk8/arthas:latest .
```
引用到服务
```
version: "2.2"
services:
  hikappservice1:
    image: jdk8/arthas #指定镜像即可，其他的均为常规配置
    volumes:
      - /home/hikapp/hikappservice/hikappservice.jar:/usr/local/hikappservice.jar:ro
      - /etc/localtime:/etc/localtime:ro
      - /home/hikapp/apm_hikappservice1:/home/hikapp/apm:rw
      - /hikappproject/static/upload/app/sncode:/hikappproject/static/upload/app/sncode:rw
      - /home/hikapp/hikappservice/log_8088:/project/deploy/logs/hikappservice1:rw   
    working_dir: /usr/local/hikappservice
    ports:
      - "8088:8088"
    container_name: hikappservice1
    restart: on-failure
    network_mode: "host"
    entrypoint: java  -jar -Xms3g -Xmx3g -XX:+HeapDumpOnOutOfMemoryError -Dspring.profiles.active=prod  /usr/local/hikappservice.jar  --server.port=8088
    logging:
      driver: "json-file"
      options:
        max-size: "1g"
```
#### 2.2 linux直接安装arthas包
```shell
yum install unzip
unzip arthas-packaging-3.3.9-bin.zip
./as.sh
```
### 3. 基础命令
#### 3.1 进入arthas控制台命令
```
自己的docker
docker exec -it 容器名称 /bin/sh -c "java -jar /opt/arthas/arthas-boot.jar"
---
在容器内部： java -jar /opt/arthas/arthas-boot.jar
```
### 3.2 其他常用命令
```
help —— 查看命令帮助信息
cat —— 打印文件内容，和linux里的cat命令类似
pwd —— 返回当前的工作目录，和linux命令类似
cls —— 清空当前屏幕区域
session —— 查看当前会话的信息
reset —— 重置增强类，将被 Arthas 增强过的类全部还原，Arthas 服务端关闭时会重置所有增强过的类
version —— 输出当前目标 Java 进程所加载的 Arthas 版本号
history —— 打印命令历史
quit —— 退出当前 Arthas 客户端，其他 Arthas 客户端不受影响
shutdown —— 关闭 Arthas 服务端，所有 Arthas 客户端全部退出
keymap —— Arthas快捷键列表及自定义快捷键退出arthas如果只是退出当前的连接，可以用quit或者exit命令。Attach到目标进程上的arthas还会继续运行，端口会保持开放，下次连接时可以直接连接上。如果想完全退出arthas，可以执行shutdown命令。
```
#### 3.3 其他常用命令
```
dashboard  :展示当前进程的信息，按ctrl+c可以中断执行

thread  :查看所有的线程
    thread 1  :查看主函数线程
    thread 1 | grep 'main'  :过滤线程
    thread -n 1  :展示当前最忙的前N个线程并打印堆栈
    thread -b  :找出当前阻塞其他线程的线程。一般死锁时用
    thread -n 3 -i 1000 :指定最忙的3个线程1s种内的cpu占比

JVM DEADLOCK-COUNT :JVM当前死锁的线程数

sysprop ：查看当前JVM的系统属性(System Property) 查看系统参数端口号等
    sysprop https.proxyHost 10.1.44.163
    sysprop https.proxyPort 89

sysenv ：查看当前JVM的环境属性 系统环境变量

jad :反编译文件
    jad demo.MathGame（类的全路径）

watch : 实时监控某个方法入参和返回值
    监控方法和返回值：查看入参和返回值，返回值的深度为3 （对象里面的对象 的属性）
    watch com.A.impl.ItemsServiceImpl gettemDetail "{params,returnObj}" -x 3
    watch org.springframework.web.client.RestTemplate postForObject "{params,returnObj}" -x 2
    watch 命令定义了4个观察事件点，即 -b 方法调用前，-e 方法异常后，-s 方法返回后，-f 方法结束后
    观察方法出参和返回值： watch demo.MathGame primeFactors "{params,returnObj}" -x 2
    观察方法入参： watch demo.MathGame primeFactors "{params,returnObj}" -x 2 -b
    同时观察方法调用前和方法返回后 watch demo.MathGame primeFactors "{params,target,returnObj}" -x 2 -b -s -n 2    
    调整-x的值，观察具体的方法参数值： watch demo.MathGame primeFactors "{params,target}" -x 3
    条件表达式的例子：watch demo.MathGame primeFactors "{params[0],target}" "params[0]<0"
    察异常信息的例子： watch demo.MathGame primeFactors "{params[0],throwExp}" -e -x 2
    按照耗时进行过滤： watch demo.MathGame primeFactors '{params, returnObj}' '#cost>200' -x 2
    观察当前对象中的属性： watch demo.MathGame primeFactors 'target'  ，然后使用target.field_name访问当前对象的某个属性 watch demo.MathGame primeFactors 'target.illegalArgumentCount'

trace: 方法内部调用路径，并输出方法路径上的每个节点上耗时,只能跟踪一级方法的调用链路
   trace demo.MathGame run #跟踪run方法
   trace -j demo.MathGame run #过滤掉jdk的函数
   trace demo.MathGame run '#cost > 10' #据调用耗时过滤
   trace -E com.test.ClassA|org.test.ClassB method1|method2|method3 #可以用正则表匹配路径上的多个类和函数，一定程度上达到多层trace的效果

stack: 输出当前方法被调用的调用路径 很多时候我们都知道一个方法被执行，但这个方法被执行的路径非常多，或者你根本就不知道这个方法是从那里被执行了，此时你需要的是 stack 命令  
   stack demo.MathGame primeFactors
   stack demo.MathGame primeFactors 'params[0]<0' -n 2 #据条件表达式来过滤
   stack demo.MathGame primeFactors '#cost>5'  #据执行时间来过滤

tt:  方法执行数据的时空隧道，记录下指定方法每次调用的入参和返回信息，并能对这些不同的时间下调用进行观测，tt看到的值可能不准确   
    tt -t demo.MathGame primeFactors
    tt -l #所有的tt缓存
    tt -s 'method.name=="primeFactors"' #过滤

cat :打印文件内容，和linux里的cat命令类似，可以查看当前所有目录
    cat /tmp/a.txt

pwd :返回当前的工作目录，和linux命令类似

options :全局开关 options save-result true 是否打开执行结果存日志功能，打开之后所有命令的运行结果都将保存到~/logs/arthas-cache/result.log中          

logger ：查看logger信息，更新logger level
    logger --name ROOT --level debug
       默认情况下，logger命令只打印有appender的logger的信息。如果想查看没有appender的logger的信息，可以加上参数--include-no-appender。
    logger --include-no-appender

getstatic :通过getstatic命令可以方便的查看类的静态属性。使用方法为getstatic class_name field_name 案例 getstatic demo.MathGame random
    如果该静态属性是一个复杂对象，还可以支持在该属性上通过ognl表示进行遍历，过滤，访问对象的内部属性等操作

ognl :执行ognl表达式    
    调用静态函数: ognl '@java.lang.System@out.println("hello")'
    获取静态类的静态字段： ognl '@demo.MathGame@random'
    执行多行表达式，赋值给临时变量，返回一个List:
    ognl '#value1=@System@getProperty("java.home"), #value2=@System@getProperty("java.runtime.name"), {#value1, #value2}'

sc : "Search-Class" 的简写，这个命令能搜索出所有已经加载到 JVM 中的 Class 信息
    sc demo.*    

sm : "Search-Method" 的简写，这个命令能搜索出所有已经加载了 Class 信息的方法信息
    sm java.lang.String    

dump: 下载已加载类的 bytecode 到特定目录 用于反编译

heapdump ：类似jmap命令的heap dump功能
    dump到指定文件： heapdump /tmp/dump.hprof
    只dump live对象: heapdump --live /tmp/dump.hprof

jad :反编译指定已加载类的源码
    jad java.lang.String
    jad demo.MathGame main
    jad --source-only demo.MathGame #反编绎时只显示源代码   

classloader: 可以让指定的classloader去getResources，打印出所有查找到的resources的url。对于ResourceNotFoundException比较有用
    classloader -c 1b6d3586 -r java/lang/String.class #也可以尝试查找类的class文件,通过 classloader 命令获取loader的ID     
    classloader -c 3d4eac69 -r META-INF/MANIFEST.MF #使用ClassLoader去查找resource

mc :内存编译器，编译.java文件生成.class   

redefine :加载外部的.class文件，
    redefine jvm已加载的类
    案例: 1. jad命令反编译，然后可以用其它编译器，比如vim来修改源码
          2. mc命令来内存编译修改过的代码
          3. 用redefine命令加载新的字节码
          jad --source-only com.example.demo.arthas.user.UserController > /tmp/UserController.java
          mc /tmp/UserController.java -d /tmp
          redefine /tmp/com/example/demo/arthas/user/UserController.class

monitor ：对匹配 class-pattern／method-pattern的类、方法的调用进行监控
    monitor -c 5 demo.MathGame primeFactors #监控类的某方法 调用次数 成功次数 失败次数等
```
### 4. 实战
#### 4.1 监控某个方法的参数和返回值类似断点功能
进入容器： 
```
docker exec -it 容器名称 /bin/sh -c "java -jar /opt/arthas/arthas-boot.jar"
watch com.A.impl.ItemsServiceImpl gettemDetail "{params,returnObj}" -x 3
watch org.springframework.web.client.RestTemplate postForObject "{params,returnObj}" -x 2
```
#### 4.2 修改系统参数,例如设置正向代理
进入容器： 
```
docker exec -it 容器名称 /bin/sh -c "java -jar /opt/arthas/arthas-boot.jar"
sysprop https.proxyHost 10.1.44.163
sysprop https.proxyPort 89
```
#### 4.3 cpu 接近100%
```
linux下先输入：top ，再按：1，可以看到每个cpu的使用百分比，也可以看到出问题的进程PID
docker top:  容器ID 分别查看容器对应的PID
进入容器： docker exec -it 容器名称 /bin/sh -c "java -jar /opt/arthas/arthas-boot.jar"
thread -b :查看是否有死锁的线程（可能是这个原因，但不一定）
thread -n 3 -i 1000 :指定最忙的3个线程1s种内的cpu占比(一般就是这个问题)：
    这个方法能够看到具体的线程栈，所以也可以看到出问题的代码，一般是死循环导致
```
#### 4.4 内存溢出
```
df -h 发现内存被占满，或者发现程序假死
进入容器： docker exec -it 容器名称 /bin/sh -c "java -jar /opt/arthas/arthas-boot.jar"
dashboard :可以看到JVM各个区占用情况，主要看head区是否被占满
heapdump  :下载当前的线程运行情况，一般是个临时文件比如：/tmp/heapdump2020-06-19-17-267909836835656934257.hprof
复制出线程dump文件到本地并分析:
docker cp 10ed3d52daa1:/tmp/heapdump2020-06-19-17-267909836835656934257.hprof /tmp
下载到window本地： sz /tmp/heapdump2020-06-19-17-267909836835656934257.hprof
打开本地jdk自带工具 C:\Program Files\Java\jdk1.8.0_65\bin\jvisualvm.exe
装入hprof文件，然后分析异常对象即可
```
#### 4.5 反编译文件
`jad java.lang.String`
#### 4.6 方法执行路径
```
trace  com.xx.appmerchantsinfo.system.controller.UgcLiveController liveRank
或者
stack  com.xx.appmerchantsinfo.system.controller.UgcLiveController liveRank
```