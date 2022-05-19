---
title: Linux下bin的区别
date: 2022-05-09 13:29:00
author: Harrison
categories:
  - "Linux"
tags:
  - "Learning"

---
Linux下bin的区别~
<!-- more -->
### /bin,/sbin,/usr/bin,/usr/sbin,/usr/local/bin,/usr/local/sbin的区别

主要区别是：

+ /bin 主要存放所有用户都可以用的系统程序，即普通的基本命令，如：cat, mkdir,touch,ls

+ /sbin 主要存放超级用户才能使用的系统程序，即基本的系统命令，如：poweroff,reboot

+ usr/bin 存放所有用户都可用的应用程序，一般是已安装软件的运行脚本，如：free、make、wget

+ /usr/sbin 存放超级用户才能使用的应用程序 ，一般是与服务器软件程序命令相关的，如：dhcpd、 httpd、samba等。

+ /usr/local/bin 存放所有用户都可用的第三方软件程序,如mysql

+ /usr/local/sbin 存放超级用户才能使用的第三方软件,如nginx

一般来说我们下载的第三方软件可以放在/usr/local/bin/里面，就不用设置环境变量了，在任何路径都可以运行

