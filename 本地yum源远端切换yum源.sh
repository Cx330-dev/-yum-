#!/bin/bash
#function:本地yum源仓库搭建
#author:Mr.xie 
#############root判断###############
if
  [  "$USER"  != "root"   ]
then
   echo "错误：非root用户，权限不足！"
  exit  0
fi
###############防火墙及SElinux############
systemctl stop firewalld && systemctl disable firewalld  &> /dev/null
sed -i 's/SELINUX=.*/SELINUX=disabled/g'  /etc/selinux/config   &> /dev/null


############# 本地yum源 #############
function bendiyum(){
# 判断光盘是否挂载
df -h | grep "/dev/sr0" &>/dev/null
if [ $? ==  0 ]
then
	echo "光盘已经挂载"
else
	echo "光盘未挂载，请挂载光盘"
    exit
fi	   
# 挂载光盘
mkdir /mnt/cdrom
df /mnt/cdrom &>/dev/null
mount /dev/cdrom /mnt/cdrom
# 将CentOS-Base.repo和CentOS-Debuginfo.repo改名或者移动，绕过网络安装，以便使用本地安装
mv /etc/yum.repos.d/CentOS-Debuginfo.repo /etc/yum.repos.d/CentOS-Debuginfo.repo.bak
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
# 编辑文件
cat >> /etc/yum.repos.d/local.repo <<EOF
[local]
name=local
baseurl=file:///mnt/cdrom
enabled=1
gpgcheck=0
EOF
# 清除缓存
yum clean all
# 生成新的缓存 
yum makecache
if [ $? ==  0 ]
then
	echo "本地yum源部署完成！！"
else
	echo "本地yum源部署失败！！"
    exit 2
fi	  
}


############# 远端yum源 #############
function yuanduan(){
function xuanze(){
# 备份原系统yum源配置文件 
mv /etc/yum.repos.d /etc/yum.repos.d.bak
# 下载阿里的CentOS-Base.repo 
mkdir /etc/yum.repos.d
cd /etc/yum.repos.d
wget -O /etc/yum.repos.d/CentOS-Base.repo $yuan
if [ $? ==  0 ]
then
	echo "下载成功"
else
	echo "下载失败"
    exit 2
fi	
# 清除缓存
yum clean all
# 生成新的缓存 
yum makecache
# 测试 
yum -y install vim
if [ $? ==  0 ]
then
	echo "yum源切换成功！！"
	exit
else
	echo "yum源切换失败！！"
    exit 2
fi
}
PS3="请选择远端yum源提供商:"
select source in 阿里云 网易 华为 exit
do
    case $source in
        阿里云)
        # 下载阿里云的源配置文件
        yuan=https://mirrors.aliyun.com/repo/Centos-7.repo    
        xuanze      
        eixt 
        ;;
        网易)
        # 下载网易的源配置文件
        yuan=http://mirrors.163.com/.help/CentOS7-Base-163.repo
        xuanze
        eixt
        ;;
        华为)
        # 下载华为的源配置文件
        yuan=https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo
        xuanze
        eixt
        ;;
        exit)
        echo "EXIT........."
        exit
    esac
done

}


############# 局域网yum源 #############
function wangluoyum(){
ip=$(hostname -I | awk -F ' ' '{print $1}' | awk -F '.' '{print $1"."$2"."$3"."$4}')
# 安装http服务
yum -y install httpd
# 启动http服务
systemctl start httpd
if [ $? ==  0 ]
then
	echo "http服务启动成功"
else
	echo "http服务启动失败"
    exit 2
fi
# 创建目录
mkdir -p /var/www/html/centos/7/os/x86_64
# 判断光盘是否挂载
df -h | grep "/dev/sr0" &>/dev/null
if [ $? ==  0 ]
then
	echo "光盘已经挂载"
else
	echo "光盘未挂载，请挂载光盘"
    exit 2
fi	   
# 挂载
mount /dev/sr0 /var/www/html/centos/7/os/x86_64/ 
if [ $? ==  0 ]
then
	echo "挂载成功"
	echo "请前往客户端主机修改yum配置文件,指向本台服务器 http://$ip/centos/7/os/x86_64/ "
	exit
else
	echo "挂载失败"
    exit 2
fi
}


PS3="请你选择需要安装的服务:"
select i in 本地yum源 远端yum源切换 局域网yum源 exit
do

case $i in
    本地yum源)
    bendiyum 
    ;;
    远端yum源切换)
    yuanduan
    ;;
    局域网yum源)
    wangluoyum
    ;;
    exit)
    echo "EXIT........."
    exit
esac

done


#mv /etc/yum.repos.d /etc/yum.repos.d.bak
#mkdir /etc/yum.repos.d
#cat > /etc/yum.repos.d/remote.repo << EOF
#[remote]
#name=remote.repo
#baseurl=http://192.168.42.131/centos/7/os/x86_64/
#enabled=1
#gpgcheck=0
#EOF
