#!/bin/bash
#此脚本为pxe自动化部署脚本，无需人工干预
#虚拟机必须提前挂载iso镜像否则无法获取到光盘信息
ip=`ifconfig | awk 'NR==2{print $2}'`    #ip地址
nip=`route -n | awk 'NR==4{print $1}'`   #网关地址
mip=`ifconfig | awk 'NR==2{print $4}'`   #子网掩码
gip=`route -n | awk 'NR==3{print $2}'`   #GATEWAY地址
rip=`ifconfig | awk 'NR==2{print $2}' | awk -F. 'END{print $1"."$2"."$3}'`   #ip地址前三位
mount /dev/cdrom /mnt
if [ ! -e /mnt/isolinux ];then	#判断光盘是否挂载
echo "没有挂载iso光盘镜像，请手动挂载"
exit
fi
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
echo "
[development]
name=RHEL 
baseurl=file:///mnt/
enabled=1
gpgcheck=0
" > /etc/yum.repos.d/rhel.repo
yum -y install dhcp &>/dev/null 	#安装dhcp服务，client获取server服务
echo "安装dhcp服务"
yum -y install tftp-server  &>/dev/null	#传送配置文件信息
echo "安装tftp服务"
yum -y install httpd  &>/dev/null 	#获取镜像文件
echo "安装http服务"
yum -y install syslinux  &>/dev/null
echo "安装syslinux服务"
mkdir /var/www/html/centos
mount /dev/cdrom /var/www/html/centos
systemctl restart httpd
if [ $? -eq 0 ];then 	#判断启动是否正常
echo "http启动成功" 
else
echo "http启动失败"
exit
fi
systemctl enable httpd
echo "
subnet $nip  netmask  $mip {
  range $rip.100  $rip.200;
  option routers $gip;
  default-lease-time 600;
  max-lease-time 7200;
  next-server  $ip;  #指定下一个服务器的IP地址
  filename  \"pxelinux.0\";   #指定网卡引导文件的名称
}
" > /etc/dhcp/dhcpd.conf   #写入dhcp配置文件
systemctl restart dhcpd
if [ $? -eq 0 ];then
echo "dhcpd 启动成功"
else
echo "dhcpd 启动失败"
exit
fi
systemctl enable dhcpd
cp /usr/share/syslinux/pxelinux.0  /var/lib/tftpboot/ 	#部署网卡引导文件
mkdir /var/lib/tftpboot/pxelinux.cfg
cp /mnt/isolinux/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default 	#部署光盘菜单文件
cp /mnt/isolinux/{vesamenu.c32,splash.png,vmlinuz,initrd.img} /var/lib/tftpboot/ 	#部署图形模块,背景文件,启动内核，驱动程序
sed -i "/menu label ^Install CentOS 7/a\menu default" /var/lib/tftpboot/pxelinux.cfg/default	 #读秒结束后默认选择
sed -i "65 i append initrd=initrd.img ks=http://$ip\/ks.cfg" /var/lib/tftpboot/pxelinux.cfg/default	#设置ks.cfg应答文件地址 
sed -i "66,999d" /var/lib/tftpboot/pxelinux.cfg/default 	#删除66行之后的参数
echo "
#platform=x86, AMD64, 或 Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --iscrypted $1$fO8034S7$r5P5mDzqYetS7r6H55dsw.
# Use network installation
url --url=\"http://$ip/centos\"
# System language
lang en_US
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use text mode install
text
firstboot --disable
# SELinux configuration
selinux --disabled

# Firewall configuration
firewall --disabled
# Network information
network  --bootproto=dhcp --device=eth0
# Reboot after installation
reboot
# System timezone
timezone Asia/Shanghai
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part / --fstype=\"xfs\" --size=10240
part /home --fstype=\"ext4\" --grow --size=1

%packages
@base
%end

%post 
echo 123 | passwd --stdin root
#sed -i "s/ONBOOT=no/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-$ename
#sed -i "s/dhcp/static/g" /etc/sysconfig/network-scripts/ifcfg-$ename
#sed -i "$ a IPADDR=$ip\nNETMASK=$mip\nGATEWAY=$gip\nDNS1=8.8.8.8" /etc/sysconfig/network-scripts/ifcfg-$ename
#systemctl restart network
%end
" > /var/www/html/ks.cfg  	#写入ks.cfg应答文件模板
echo "kikcstart 配置文件写入成功"
systemctl start tftp
if [ $? -eq 0 ];then
echo "tftp 启动成功"
else
echo "tftp 启动失败"
exit
fi
echo ">>>PXE Server 配置完成<<<"

