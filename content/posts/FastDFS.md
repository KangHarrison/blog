---
title: 分布式文件系统FastDFS
date: 2020-08-16 23:03:23
author: Harrison
categories:
  - "Java"
tags:
  - "FastDFS"

---

FastDFS知识小结，欢迎交流，指正错误。

<!-- more -->

## 1. FastDFS介绍

>  FastDFS 是以C语言开发的一项开源轻量级分布式文件系统，他对文件进行管理，主要功能有：文件存储，文件同步，文件访问（文件上传/下载）,特别适合以文件为载体的在线服务，如图片网站，视频网站等
>
> 分布式文件系统：
> 基于客户端/服务器的文件存储系统
> 对等特性允许一些系统扮演客户端和服务器的双重角色，可供多个用户访问的服务器，比如，用户可以“发表”一个允许其他客户机访问的目录，一旦被访问，这个目录对客户机来说就像使用本地驱动器一样

#### 1.1. FastDFS构成

>  FastDFS由跟踪服务器(Tracker Server)、存储服务器(Storage Server)和客户端(Client)构成

##### 1.1.1. Tracker server 追踪服务器

追踪服务器负责接收客户端的请求，选择合适的组合storage server ，tracker server 与 storage server之间也会用心跳机制来检测对方是否活着。
 Tracker需要管理的信息也都放在内存中，并且里面所有的Tracker都是对等的（每个节点地位相等），很容易扩展
 客户端访问集群的时候会随机分配一个Tracker来和客户端交互。

##### 1.1.2. Storage server 储存服务器

实际存储数据，分成若干个组（group），实际traker就是管理的storage中的组，而组内机器中则存储数据，group可以隔离不同应用的数据，不同的应用的数据放在不同group里面，

- 优点：
   海量的存储：主从型分布式存储，存储空间方便拓展,
   FastDFS对文件内容做hash处理，避免出现重复文件
   然后FastDFS结合Nginx集成, 提供网站效率

  

##### 1.1.3. 客户端Client

  主要是上传下载数据的服务器，也就是我们自己的项目所部署在的服务器。每个客户端服务器都需要安装Nginx

![FastDFS系统结构图](https://gitee.com/yuanlu_k/BlogImages/raw/master/FastDFS/FastDFS%E7%B3%BB%E7%BB%9F%E7%BB%93%E6%9E%84%E5%9B%BE.jpg)

<center>FastDFS三方交互图</center>



## 2. 上传下载操作

#### 2.1. 上传文件

写操作的时候，storage会将他所挂载的所有数据存储目录的底下都创建2级子目录，每一级256个总共65536个，新写的文件会以hash的方式被路由到其中某个子目录下，然后将文件数据作为本地文件存储到该目录中。

![FastDFS文件上传流程图](https://gitee.com/yuanlu_k/BlogImages/raw/master/FastDFS/FastDFS%E6%96%87%E4%BB%B6%E4%B8%8A%E4%BC%A0%E6%B5%81%E7%A8%8B%E5%9B%BE.png)

#### 2.2. 下载文件

当客户端向Tracker发起下载请求时，并不会直接下载，而是先查询storage server（检测同步状态），返回storage server的ip和端口，
 然后客户端会带着文件信息（组名，路径，文件名），去访问相关的storage，然后下载文件。



![FastDFS文件下载流程图](https://gitee.com/yuanlu_k/BlogImages/raw/master/FastDFS/FastDFS%E6%96%87%E4%BB%B6%E4%B8%8B%E8%BD%BD%E6%B5%81%E7%A8%8B%E5%9B%BE.png)



## 3. 使用

1. 首先下载fastdfs安装包和依赖包（[sourceforge->fastdfs](https://sourceforge.net/projects/fastdfs/)），

然后解压至/usr/local/下,

```bash
tar -zxvf FastDFS_v6.06.tar.gz -C /usr/local
```

再编译安装，

```bash
cd /usr/local/fastdfs_6.06
   
./make.sh 
./make.sh install  #编译安装
```

   

2. 配置tracker

```bash
sudo cp /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
```

在/home/harrison/目录中创建目录 fastdfs/tracker

```bash
mkdir –p /home/harrison/fastdfs/tracker
```

编辑/etc/fdfs/tracker.conf配置文件

```bash
sudo vim /etc/fdfs/tracker.conf
```

修改 ```base_path=/home/python/fastdfs/tracker```



3. 配置storage

```bash
sudo cp /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
```

在/home/harrison/fastdfs/ 目录中创建目录 storage，这个目录就是实际数据存储的位置

```bash
mkdir –p /home/harrison/fastdfs/storage
```



4. 编辑/etc/fdfs/storage.conf配置文件

```bash
 sudo vim /etc/fdfs/storage.conf
```

修改内容：

```bash
base_path=/home/harrison/fastdfs/storage
store_path0=/home/harrison/fastdfs/storage
tracker_server=tracker所在机器的ip:22122
```



5. 启动tracker和storage

```bash
service fdfs_trackerd start # 开启Tracker Server
service fdfs_storaged start # 开启Storage Server
```

至此，FastDFS服务端以安装完毕。



## 4. 利用FastDFS [Java客户端](https://github.com/tobato/FastDFS_Client)测试

测试源代码在我的[GitHub](https://github.com/kangkanglang/JavaLearning/tree/master/FastDFSTest)上。

1. 根据[FastDFS_Client的文档](https://github.com/tobato/FastDFS_Client)，将FastDFS-Client客户端引入本地化项目的方式非常简单，在SpringBoot项目`/src/[com.xxx.主目录]/conf`当中配置

```java
/**
 * 导入FastDFS-Client组件
 * 
 * @author tobato
 *
 */
@Configuration
@Import(FdfsClientConfig.class)
// 解决jmx重复注册bean的问题
@EnableMBeanExport(registration = RegistrationPolicy.IGNORE_EXISTING)
public class ComponetImport {
    // 导入依赖组件
}
```



2. 在application.yml当中配置Fdfs相关参数

```yaml
# ===================================================================
# 分布式文件系统FDFS配置
# ===================================================================
fdfs:
  so-timeout: 1501
  connect-timeout: 601 
  thumb-image:             #缩略图生成参数
    width: 150
    height: 150
  tracker-list:            #TrackerList参数,支持多个
    - 192.168.xxx.xxx:22122
#    - 192.168.1.106:22122 
```



3. 编写测试类(具体源码在[这里](https://github.com/kangkanglang/FastDFS_Client_Test))

```java
@RunWith(SpringRunner.class)
@SpringBootTest
public class FastDFSTest {
    /**
     * test 1 -- 图片上传
     */
    @Test
    public void testUpload() throws FileNotFoundException {
        //上传图片
        StorePath storePath = this.storageClient.uploadFile(new FileInputStream(file), file.length(), Variables.fileExtName, metaDataSet);
        printlnPath(storePath);
    }
    
    /**
     * 下载文件
     */
    @Test
    public void downLoadFile() {
        DownloadFileWriter callback = new DownloadFileWriter(Variables.filename);
        this.storageClient.downloadFile(Variables.groupName, Variables.path, callback);
    }
    
    /**
     * 删除文件
     */
    @Test
    public void testDel() {
        this.storageClient.deleteFile(Variables.filePath);
    }
    
    /**
     * 查询文件
     */
    @Test
    public void testQuery() {
        FileInfo fileInfo = this.storageClient.queryFileInfo(Variables.groupName, Variables.path);
        System.out.println("图片信息如下：\n" + fileInfo.getCrc32() + "\n" + new Date(fileInfo.getCreateTime()) + "\n" + fileInfo.getFileSize() + "\n" + fileInfo.getSourceIpAddr());
    }
    
}
```



OK, 如果在测试中发现 “com.github.tobato.fastdfs.exception.FdfsConnectException: 无法获取服务端连接资源" 异常，可查看这些[解决方法](https://kangkanglang.github.io/2020/08/15/FastDFS%E9%81%87%E5%88%B0%E7%9A%84%E9%97%AE%E9%A2%98/)。

