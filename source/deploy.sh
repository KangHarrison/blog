#!/bin/sh

rm -rf /root/blog/source/_posts
mv /root/blog/source/blogs /root/blog/source/_posts
/usr/local/bin/hexo clean
/usr/local/bin/hexo g
