#!/bin/bash

## 原始url:http://host:801/eportal/?c=Portal&a=login&callback=(dr(new Date()).getTime())&login_method=1&user_account=%2C0%2C12345678901&user_password=12345678&wlan_user_ip=(ip)&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=3.1&_
## callback		dr与当前时间戳的拼接后字符串
## user_account		登录账号
## user_password	登录密码
## wlan_user_ip		ap分配的ip
## _			可缺省
### more		hppt://host/a41?version=(new Date()).valueOf(

## 通常修改网卡与宽带参数即可联网
## account 宽带账号，passwd 宽带账号对应密码
account="account"
passwd="password"

## 网卡
network_card="wlan"

## 自动时间戳
dr="dr"$(date +%s)

## 超时时间s
s="1"

## 获取ap分配的ip
user_ip=$(ip addr|grep $network_card$|cut -d/ -f1|cut -d" " -f6)


# a:account p:passwd u:uip n:network card s:timeout
while getopts ":a:p:u:n:s:" opt
do
	case $opt in
		a)
			if [ "$OPTARG" != "" ] ;then
				account=$OPTARG
			fi
		;;
                p)
                        if [ "$OPTARG" != "" ] ;then
                                passwd=$OPTARG
                        fi
                ;;
                u)
                        if [ "$OPTARG" != "" ] ;then
                                user_ip=$OPTARG
                        fi
                ;;
                s)
                        if [ "$OPTARG" != "" ] ;then
				s=$OPTARG
                        fi
		;;
                n)
                        if [ "$OPTARG" != "" ] ;then
				if [ "$user_ip" == "" ] ;then
					user_ip=$(ip addr|grep $OPTARG$|cut -d/ -f1|cut -d" " -f6)
				fi
                        fi
                ;;
		?)
			echo "	SASHOU automatic authentication script"
			echo "		-a : 宽带账号"
			echo "		-p : 宽带密码"
			echo "		-u : ap分配的ip"
			echo "		-s : 设置超时时间"
			echo "		-n : 网卡名"
			echo "		example sashou.sh -a 12345678901 -p 12345678 -u 192.168.8.1 -s 1 -n wlan"
			echo "		github:https://github.com/anfty"
			exit 1;;
	esac
done



b='http://110.188.66.35:801/eportal/?c=Portal&a=login&callback='$dr'&login_method=1&user_account=%2C0%2C'$account'&user_password='$passwd'&wlan_user_ip='$user_ip'&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=3.1&_='

respans=$(curl -s $b --connect-timeout $s)
echo $respans
