#!/bin/sh

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
passwd="passwd"

## 网卡
network_card="wan"

## 自动时间戳
dr="dr"$(date +%s)

## 超时时间s
s="1"

## 获取ap分配的ip
user_ip=""

## led status
# tmp


function get_user_ip(){
	# 获取网卡对应ip
	tmp=$(ip addr|grep $network_card$|cut -d/ -f1|cut -d" " -f6)
	if [ "$tmp" == "" ] ;then
		return 0
	fi
	user_ip=$tmp
	return 1
}

# a:account p:passwd u:uip n:network card s:timeout
# 获取输入参数
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




# 其他设备已在线
# {"result":"0","msg":"aW51c2UsIGxvZ2luIGFnYWluLCBwYyBPTG5vIDEgPj0gMQ==","ret_code":4}
# 登录成功
# {"result":"1","msg":"\u8ba4\u8bc1\u6210\u529f"}
# 已在线
# {"result":"0","msg":"","ret_code":2}


function route_status_led(){
	if [ "$led_status" == "$1" ] ;then
		return 0
	else
		led_lock=1
		if [ "$1" == "off" ] ;then
			led_lock=0
		fi
		led_status=$1
		# route led status
		if [ "$(uname -a|grep 'GL-MT1300')" != "" ] ;then
			case $1 in
				connecting )
					(mt1300_led blue_flash fast)
					;;
				ap_drops )
					(mt1300_led blue_flash normal)
					;;
				ip_drops )
					(mt1300_led white_flash normal)
					;;
				error )
					(mt1300_led blue_breath)
					;;
				off )
					(/etc/init.d/led stop)
					;;
			esac
		fi
	fi
}


# route_log
function route_log(){
	# 存储日志 建议修改路径
	echo "$(date)  info: $1" >> /root/sashou/.route.log
}


function network_status(){
	#网络状态检测,网络连通返回1，反之返回0 182.254.225.219
	if [ $(timeout 1 ping baidu.com -w 1 -c 1 2>/dev/null | wc -l) == 6 ] ;then
		return 1
	elif [ $(timeout 1 ping 182.254.225.219 -w 1 -c 1 2>/dev/null | wc -l) == 6 ] ;then
		return 1
	fi
	return 0
}



function getnetwork(){
	url='http://110.188.66.35:801/eportal/?c=Portal&a=login&callback='$dr'&login_method=1&user_account=%2C0%2C'$account'&user_password='$passwd'&wlan_user_ip='$user_ip'&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=3.1&_='
	# 登录请求
	rep=$(curl -s $url --connect-timeout $s|grep -o '{.*}')
	if [ "$rep" == '{"result":"0","msg":"","ret_code":2}' ] ;then
		# 已经在线
		return 0
	elif [ "$rep" == '{"result":"1","msg":"\u8ba4\u8bc1\u6210\u529f"}' ] ;then
		# 登录成功
		return 1
	elif [ "$rep" == '{"result":"0","msg":"aW51c2UsIGxvZ2luIGFnYWluLCBwYyBPTG5vIDEgPj0gMQ==","ret_code":4}' ] ;then
		# 已在其他设备登录
		return 2
	elif [ "$rep" == "" ] ;then
		# ap网络异常
		return 3
	fi
	# 未知错误error
	return 4
}



# main
led_lock=0
led_status="tmp"

while [ "66" == "66" ]
do
	# 获取网络状态，网络连接失败
	network_status
	if [ $? == 0 ] ;then
		# 仅有led_status为off才会触发
		if [ $led_lock == 0 ] ;then
			# set led to connecting
			route_status_led 'connecting'
		fi
		# 获取当前网卡ip，ip不存在return 0
		get_user_ip
		if [ $? == 0 ] ;then
			route_status_led 'ip_drops'
			sleep 1s
			continue
		fi
		# 登录账号，return code：1 to 5
		getnetwork
		tmp_status=$?
		route_log $tmp_status
		if [ $tmp_status -le 2 ] ;then
			continue
		elif [ $tmp_status == 3 ] ;then
			route_status_led 'ap_drops'
			sleep 2s
			continue
		elif [ $tmp_status == 4 ] ;then
			route_status_led 'error'
			sleep 5m
			continue
		fi
	fi
	route_status_led 'off'
	sleep 5s
done
