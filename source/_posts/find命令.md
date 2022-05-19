---
title: find使用小结
date: 2022-05-16 11:50:00
author: Harrison
categories:
  - "Linux"
tags:
  - "Learning"

---
find命令使用总结～
<!-- more -->
### 1、用文件名查找文件
这是find命令的一个基本用法。下面的例子展示了用"test.txt"作为查找名在当前目录及其子目录中查找文件的方法。
```shell
[root@harrison ~]# find -name test.txt
./test.txt
./myFile/test.txt
```
### 2、用文件名查找文件，忽略大小写
这是find命令的一个基本用法。下面的例子展示了用"test.txt"作为查找名在当前目录及其子目录中查找文件的方法，忽略大小写。
```shell
[root@harrison ~]# find -iname TEST.txt
./test.txt
./myFile/test.txt
```
### 3、使用mindepth和maxdepth限定搜索指定目录的深度
+ 在root目录及其子目录下查找passwd文件。
```shell
[root@harrison ~]# find / -name passwd
/etc/pam.d/passwd
/etc/passwd
/var/lib/sss/mc/passwd
/usr/bin/passwd
/usr/share/licenses/passwd
/usr/share/doc/passwd
/usr/share/bash-completion/completions/passwd
```
+ 在root目录及其2层深的子目录中查找passwd
```shell
[root@harrison ~]# find / -maxdepth 2 -name passwd
/etc/passwd
```
+ 在root目录下及其最大3层深度的子目录中查找passwd文件
```shell
[root@harrison ~]# find / -mindepth 3 -name passwd
/etc/pam.d/passwd
/var/lib/sss/mc/passwd
/usr/bin/passwd
/usr/share/licenses/passwd
/usr/share/doc/passwd
/usr/share/bash-completion/completions/passwd
```
+ 在root目录下第3层子目录和第5层子目录之间查找passwd文件
```shell
[root@harrison ~]# find / -mindepth 3 -maxdepth 5 -name passwd
/etc/pam.d/passwd
/var/lib/sss/mc/passwd
/usr/bin/passwd
/usr/share/licenses/passwd
/usr/share/doc/passwd
/usr/share/bash-completion/completions/passwd
```
### 4、在find命令查找到的文件上执行命令
在当前目录下名字为test.txt中搜索'Harrison'，并显示行号；test.txt文案内容：
```
Hello everyone
This is a test.txt
Harrison
```
```shell
[root@harrison ~]# find -name test.txt -exec grep -n 'Harrison' {} +  # +表示分隔符
./test.txt:3:Harrison 
```
更过关于find和exec的相关知识，可查看：[find命令之exec](https://www.cnblogs.com/peida/archive/2012/11/14/2769248.html)
### 5、相反匹配
显示所有的名字不是test.txt的文件或者目录。由于maxdepth是1，所以只会显示当前目录下的文件和目录。
```shell
[root@harrison ~]# find -maxdepth 1 -not -iname "test.txt"
.
./.bash_logout
./.cshrc
./.tcshrc
./.pydistutils.cfg
./.pip
./.cache
./.ssh
./applications
./.config
./myFile
./.m2
./.viminfo
...省略...
```
### 6、使用inode编号查找文件
任何一个文件都有一个独一无二的inode编号，借此我们可以区分文件。创建两个名字相似的文件，例如一个有空格结尾，一个没有。
```shell
[root@harrison ~]# touch "test_file_name"
[root@harrison ~]# touch "test_file_name "
```
通过 `ls -il` 可以查看inode编号
```shell
[root@harrison ~]# ls -il
total 60
 1572008 drwxr-xr-x 7 root root   135 Jan 17 17:01  applications
67272659 drwxr-xr-x 8 root root   240 May 10 01:47  blog
17345430 -rw-r--r-- 1 root root  2525 May 10 00:48  config.yml.hexo
17345429 -rw-r--r-- 1 root root 35386 May 10 00:48  _config.yml.theme
17345428 -rwxr-xr-x 1 root root   268 May 10 00:45  deploy.sh
67427055 drwxr-xr-x 2 root root    22 May 13 18:15  myFile
17287732 -rw-r--r-- 1 root root  2629 May  9 22:24  nginx.conf
    7535 drwxr-xr-x 3 root root    32 May 12 16:18  projects
17098430 -rw-r--r-- 1 root root     0 May 16 10:50  test_file_name
17101023 -rw-r--r-- 1 root root     0 May 16 10:50 'test_file_name '
17402283 -rw-r--r-- 1 root root    43 May 16 10:38  test.txt
```
找到inode编号为17101023的文件并重命名为new_test_file_name
```shell
[root@harrison ~]# find -inum 17101023 -exec mv {} new_test_file_name \;
```
### 7、根据文件权限查找文件
当前myFile目录下的文件及其权限
```shell
[root@harrison myFile]# ls -l
total 0
-rwxrwxrwx 1 root root 0 May 16 11:02 all_for_all
---------- 1 root root 0 May 16 11:09 all_for_nothing
-r--r--r-- 1 root root 0 May 16 11:09 all_for_read
---x------ 1 root root 0 May 16 11:17 only_user_exec
-rw-r--r-- 1 root root 0 May 13 18:15 test.txt
```
查找出当前用户具有写权限的文件
```shell
[root@harrison myFile]# find -perm -u=w
./test.txt
./all_for_all
```
查找出具有组读权限的文件
```shell
[root@harrison myFile]# find -perm -g=r
./test.txt
./all_for_all
./all_for_read
```
查找出当用户可执行的文件（八进制数字表示）
```shell
[root@harrison myFile]# find -perm 100
./only_user_exec
```
### 8、查找当前目录及子目录下所有的空文件（0字节）
```shell
[root@harrison myFile]# find ./ -empty
./all_for_all
./all_for_read
./all_for_nothing
./only_user_exec
```
### 9、使用-type查找指定文件类型的文件
+ 只查找socket文件 `find . -type s`
+ 查找所有的目录 `find . -type d`
+ 查找所有的一般文件 `find . -type f`
+ 查找所有的隐藏文件 `find . -type f -name ".*"`
+ 查找所有的隐藏目录 `find -type d -name ".*"`
### 10、通过文件大小查找文件
使用-size选项可以通过文件大小查找文件。
+ 查找大于100M的文件 `find ~ -size +100M`
+ 查找小于100M的文件 `find ~ -size -100M`
+ 查找等于100M的文件 `find ~ -size 100M`
### 11、查找文件修改时间在某一文件修改后的文件
查询在test.txt文件修改时间后修改的文件
```shell
[root@harrison myFile]# find -newer test.txt
./all_for_all
./all_for_read
./all_for_nothing
./only_user_exec
```


