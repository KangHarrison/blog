---
title: MySQL 索引（二）
date: 2020-08-08 23:32:54
author: Harrison
categories:
  - "MySQL"
tags:
  - "Learning"
  - "索引"
---
MySQL索引相关知识小结，欢迎交流，指证错误。
<!-- more -->

## 0. 前言
MyISAM和InnoDB是MySQL最常用的两个存储引擎，本文将进行详尽的介绍和对比。

本文会图解两种引擎的索引结构区别，然后讲解索引的原理，理解本文内容，就能够理解索引优化的各种原则的背后原因。

## 1. MyISAM与InnoDB的索引差异

在[MySQL 索引 B-/+树](https://kangkanglang.github.io/2020/07/30/MySQL%E7%B4%A2%E5%BC%95B+%E6%A0%91) 中介绍了B+树，它是一种非常适合用来做数据库索引的数据结构：

> (1)很适合磁盘存储，能够充分利用局部性原理，磁盘预读；
> (2)很低的树高度，能够存储大量数据；
> (3)索引本身占用的内存很小；
> (4)能够很好的支持单点查询，范围查询，有序性查询；


### 1.1. MyISAM的索引

MyISAM的***索引***与***行记录***是分开存储的，叫做***非聚集索引***（UnClustered Index）。

> 其主键索引与普通索引没有本质差异：
> + 有连续聚集的区域单独存储行记录
> + 主键索引的叶子节点，存储主键与对应行记录的指针
> + 普通索引的叶子结点，存储索引列与对应行记录的指针
> 
> tips：MyISAM的表可以没有主键。

主键索引与普通索引是两棵独立的索引B+树，通过索引列查找时，先定位到B+树的叶子节点，再通过指针定位到行记录。

例如：在MyISAM引擎下有一表t_user(id, name, sex, flag)
表中有4条记录（id为主键，name为普通索引）


|  id   | name  | sex  | flag  |
|  :--:  | :--:  | :--:  | :--:  |
| 1  | sj | m | A |
| 3  | zs | m | A |
| 5  | ls | m | A |
| 9  | ww | f | B |


则MyISAM构建的B+树如下图所示：

![MyISAM](https://gitee.com/yuanlu_k/BlogImages/raw/master/MySQL%E7%B4%A2%E5%BC%95/MyISAM.png)

上图可知：
> 行记录单独存储
> id为Primary Key(Primary Index)，有一棵id的索引树，叶子指向行记录
> name为Key(Secondary Index)，有一棵name的索引树，叶子也指向行记录


### 1.2. InnoDB的索引

InnoDB的***主键索引***与***行记录***是存储在一起的，故叫做***聚集索引***（Clustered Index）：
> 没有单独区域存储行记录
> 主键索引的叶子节点，存储主键，与对应行记录（而不是指针）
> tips：因此，InnoDB的PK查询是非常快的。

因为这个特性，InnoDB的表必须要有聚集索引：
> (1)如果表定义了PK，则PK就是聚集索引；
> (2)如果表没有定义PK，则第一个非空unique列是聚集索引；
> (3)否则，InnoDB会创建一个隐藏的row-id作为聚集索引；
聚集索引，也只能够有一个，因为数据行在物理磁盘上只能有一份聚集存储

InnoDB的普通索引可以有多个，它与聚集索引是不同的：
- 普通索引的叶子节点存储主键（也不是指针）,再通过主键进行查找，因此普通索引要经过二次查找。

对于InnoDB表，这里的启示是：
> (1)不建议使用较长的列做主键，例如char(64)，因为所有的普通索引都会存储主键，会导致普通索引过于庞大；
> (2)建议使用自动递增的key做主键，由于数据行与索引一体，这样不至于插入记录时，有大量索引分裂，行记录移动；

再InnoDB下，t_user表构成的B+树如下图所示：

![InnoDB](https://gitee.com/yuanlu_k/BlogImages/raw/master/MySQL%E7%B4%A2%E5%BC%95/InnoDB.png)


### 1.3. Innodb与MyISAM的区别
- 存储结构
MyISAM存储表分为三个文件frm（表结构）、MYD（表数据）、MYI（表索引），而Innodb如上文所说，根据存储方式不同，存储结构不同。
- 事务务支持
MyISAM不支持事务，而Innodb支持事务，具有事务、回滚和恢复的事务安全。
- 外键和主键
MyISAM不支持外键，而Innodb支持外键。MyISAM允许没有主键，但是Innodb必须有主键，若未指定主键，会自动生成长度为6字节的主键。
- 锁
MyISAM只支持表级锁，而Innodb支持行级锁，具有比较好的并发性能，但是行级锁只有在where子句是对主键筛选才生效，非主键where会锁全表
- 索引
MyISAM使用B+树作为索引结构，叶节点保存的是存储数据的地址，主键索引key值唯一，辅助索引key可以重复，二者在结构上相同。Innodb也是用B+树作为索引结构，数据表本身就是按照b+树组织，叶节点key值为数据记录的主键，data域为完整的数据记录，辅助索引data域保存的是数据记录的主键。
