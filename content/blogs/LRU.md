---
title: LRU算法的实现
date: 2020-08-11 18:34:52
author: Harrison
categories:
  - "Java"
tags:
  - "LRU"
  - "Learning"
---
LRU算法的实现，欢迎交流，指正错误。
<!-- more -->

LRU是Least Recently Used的缩写，即最近最少使用，常用于页面置换算法，是为虚拟页式存储管理服务的。

> LRU 算法的***设计原则***是：如果一个数据在最近一段时间没有被访问到，那么在将来它被访问的可能性也很小。也就是说，当限定的空间已存满数据时，应当把最久没有被访问到的数据淘汰。

### 实现方案：

```java

import java.util.Deque;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;

/**
 * LRU 手动实现
 * LRU 每次淘汰最近最少使用的缓存value
 *
 * 思路：
 * 1、用HashMap作为缓存，实现添加缓存值和更新值
 * 2、通过一个双向链表记录缓存值的使用记录， 最近有使用的放入表头，最近最少使用的放在表尾
 * 3、HashMap中 key 即为搜索查询使用的 key ； value 是双向链表的结点 node
 */
public class LRUCache {

    private static class Node{
        int key;
        int value;
        Node pre;
        Node next;

        public Node(){

        }

        public Node(int key, int value){
            this.key = key;
            this.value = value;
        }

    }

    private Map<Integer, Node> cache = new HashMap<>();
    private int capacity;
    private int count;
    private Node head, tail;

    public LRUCache(int capacity){
        this.capacity = capacity;
        this.count = 0;
        this.head = new Node();
        this.tail = new Node();

        head.pre = null;
        head.next = tail;
        tail.pre = head;
        tail.next = null;
    }

    /**
     * 从缓存中取值
     * @param key 取值的key
     * @return 若key所对应的值存在则返回，否则返回-1
     */
    public int get(int key){
        Node node = cache.get(key);
        if(node != null){
            moveToHead(node);
            return node.value;
        }else{
            return -1;
        }
    }

    /**
     * 往缓存中添加（更新）值
     * @param key 值对的key
     * @param value 缓存值
     */
    public void put(int key, int value){
        Node node = cache.get(key);
        // 未在缓存中，添加至缓存
        if(node == null){
            node = new Node(key, value);
            cache.put(key, node);
            addNode(node);
            ++count;
            if(count > capacity){ //超出容量
                popTail();
                --count;
            }
        }else{ // 在缓存中， 更新缓存值
            node.value = value;
            moveToHead(node);
        }

    }

    /**
     * 将链表中最后一个节点移除。同时也从缓存中移除
     */
    private void popTail() {
        Node node = tail.pre;
        removeNode(node);
        cache.remove(node.key);
    }

    /**
     * 将节点移动至链表的头部，表示该节点刚添加 或 刚更新 。
     * @param node 节点
     */
    private void moveToHead(Node node) {
        removeNode(node);
        addNode(node);
    }

    /**
     * 添加节点
     * @param node 节点
     */
    private void addNode(Node node) {
        node.pre = head;
        node.next = head.next;
        head.next = node;
        node.next.pre = node;
    }

    /**
     * 移除指定节点
     * @param node 节点
     */
    private void removeNode(Node node) {
        node.pre.next = node.next;
        node.next.pre = node.pre;
    }

}


```
