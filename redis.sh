#!/bin/bash
ip=`ifconfig | awk 'NR==2{print $2}'`
port=`ifconfig | awk 'NR==2{print $2}'| awk -F. 'END{print $4}'`
rpm -q ftp
if [ $? -ne 0 ];then
yum -y install ftp
fi
ftp -n <<EOF
open 192.168.4.254  
user anonymous \n 
binary 
cd /share
get redis-4.0.8.tar.gz
bye
EOF
rpm -q gcc
if [ $? -ne 0 ];then
yum -y install gcc
echo "安装gcc编译工具"
fi
tar -xvf redis-4.0.8.tar.gz 
cd redis-4.0.8
make && make install
echo -e "\n" | ./utils/install_server.sh
sed -n '70p' /etc/redis/6379.conf |sed -i "s/127.0.0.1/$ip/g" /etc/redis/6379.conf
sed -i "93s/6379/63$port/" /etc/redis/6379.conf
redis-cli shutdown
/etc/init.d/redis_6379 start
netstat -nultp |grep redis-server
if [ $? -eq 0 ];then
echo "redis服务安装成功"
fi

#ftp -n -u <<! 
#-n意思是不读取默认.netrc文件中的设定
#-u参数可以解决以下报错
#'AUTH GSSAPI': command not understood
#'AUTH KERBEROS_V4': command not understood
#<<重定向文件的导入
#!是即时文件的标志它一般都是成对的出现，用来标识即时文件的开始和结尾
#open
#连接ftp服务器的IP。
#user 用户名 密码
#ftp服务器登录用户、密码。
#binary
#使用二进制传输模式
#lcd $GAMEDIR
#切换本地所在目录
#prompt
#打开prompt模式，一般prompt模式在使用多文件传输中才用到，默认为打开状态。如果prompt模式未打开，命令mput和mget将会传输目录中的所有文件。
#get
#下载文件
#close
#关闭与ftp服务器的连接
#bye
#断开与ftp服务器的连接
