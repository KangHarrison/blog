---
title: SpringBoot 、Mybatis 与 websocket 之间的一些问题
author: Harrison
date: 2020-08-15 19:20:33
categories:
  - "Problems"
tags:
  - "Java"
---

SpringBoot 、Mybatis 与 websocket 之间的一些问题，欢迎交流，指正错误。

<!-- more -->

最近在做一个小项目，用到了SpringBoot 和 websocket，先大概讲一下所遇到的问题。

问题：

> 前端JS通过websocket和和服务器中的WebSocketServlet 连接，在WebSocketServlet中注入HeatMapService，这时候出现第一个问题，<font color="red">发现注入的HeatMapService为null，也就是说这个时候Spring容器无法将HeatMapService注入</font>；当时没太在意，想着既然Spring无法注入，那就自己实例化 HeatMapService 就好了，然后就傻乎乎的自己实例化了HeatMapService，到这没啥大问题，至少代码跑起来了。下午准备把数据存到数据库时，出现了第二个问题，<font color="red">在HeatMapServiceImpl中想要注入HeatMapMapper时，发现此时注入的HeatMapMapper居然也为null</font>，自己的第一反应是Mybatis和SpringBoot整合时可能出问题了，检查MainApplication.java上有添加@MapperScanner，对应路径也没有写错，那这是为什么无法注入Mapper呢？



服务端websocket中的<font color="red">部分错误代码</font>：

```java
@ServerEndpoint(value = "/websocket")
@Component
public class WebSocketServlet {
    
    @Autowired
    private HeatMapService heatMapService;

    private boolean flag = false;

    //用来存放每个客户端对应的webSocketSet对象。
    private static CopyOnWriteArraySet<WebSocketServlet> webSocketSet = new CopyOnWriteArraySet<WebSocketServlet>();
    private  Session session=null;

    /**
     * @ClassName: onOpen
     * @Description: 开启连接的操作
     */
    @OnOpen
    public void onOpen(Session session) throws IOException {
       //TODO
    }

}
```



先解决第二个问题：

经过几个小时zz般的排查，依旧没有想清SpringBoot 和 Mybatis整合到底哪出错了，于是准备把整个流程重新捋一遍，当走到WebSocketServlet 时，才发现是自己上午实例化的HeatMapService的问题。<font color = red>由于是自己的手动实例化的，因此实例化的heatMapService对象肯定是不在Spring容器中的，根据Spring的“依赖注入”，自然也无法将HeatMapMapper注入到Spring容器中</font>。知道问题所在，那就把HeatMapService通过Spring的方式注入进容器即可，问题二解决。



问题二解决了，自然问题一又回来了，为什么WebSocketServlet 中无法注入HeatMapService呢 ？<font color = red>原来WebSocket是多例的，而Spring管理的对象默认是单例的，即Spring默认只实例化一次HeatMapService，而WebSocketServlet 每新添加一个连接就会新增一个socket对象，自然无法将每一个socket对象中的HeatMapService进行实例化注入</font>。解决的办法就是将HeatMapService由成员变量，变成类变量即可，让所有的socket对象共享同一个HeatMapService。



问题解决后的WebSocketServlet 代码：

```java
@ServerEndpoint(value = "/websocket")
@Component
public class WebSocketServlet {

    private static HeatMapService heatMapService;

    @Autowired
    public void setHeatMapService(HeatMapService heatMapService){
        WebSocketServlet.heatMapService = heatMapService;
    }

    private boolean flag = false;

    //用来存放每个客户端对应的webSocketSet对象。
    private static CopyOnWriteArraySet<WebSocketServlet> webSocketSet = new CopyOnWriteArraySet<WebSocketServlet>();
    private  Session session=null;

    /**
     * @ClassName: onOpen
     * @Description: 开启连接的操作
     */
    @OnOpen
    public void onOpen(Session session) throws IOException {
      //TODO
    }

    /**
     * @ClassName: onClose
     * @Description: 连接关闭的操作
     */
    @OnClose
    public void onClose(){
        System.out.println("connection is closed...");

    }

    /**
     * @ClassName: onMessage
     * @Description: 从前端接收消息
     */
    @OnMessage
    public void onMessage(String message) {
        //TODO
    }

    /**
     * @ClassName: OnError
     * @Description: 出错的操作
     */
    @OnError
    public void onError(Throwable error){
        System.out.println(error);
    }

    /**
     * 将消息发送给前端
     */
    public void sendMessage(SensorVO sensor){
        //TODO
    }
}
```



参考 ：[spring springboot websocket 不能注入( @Autowired ) service bean 报 null 错误](https://blog.csdn.net/m0_37202351/article/details/86255132)

还是自己code太少了，项目经验太少，这样的错误，希望自己以后不会再犯~
