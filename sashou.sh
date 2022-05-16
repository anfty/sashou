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
account="1234567890"
passwd="1234567890"

## 网卡
network_card="eth0.2"

## 自动时间戳
dr="dr"$(date +%s)

## 超时时间s
s="1"

## 获取ap分配的ip
user_ip=""

## led status
# tmp
tmp_led_status=""
# true
led_status=""

function get_user_ip(){
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

#路由器状态（led状态）:未获得ip（快速闪烁），断开网络（间隔双闪），正在链接（呼吸闪烁），网络在线（隔一段时间亮灯一次）,对应网络状态0,1，2，3
function route_status_led(){
	if [ "$(uname -a|grep OpenWrt)" != "" ] ;then
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
				(mt1300_led off)
				;;
		esac
	fi
}

# route_log
function route_log(){
	echo "$(date)  info: $1" >> /root/sashou/.route.log
}

#网络状态检测,网络连通返回1，反之返回0
function network_status(){
	#$(ping baidu.com -w 1 -c 1 2>/dev/null | wc -l)
	if [ $(ping baidu.com -w 1 -c 1 2>/dev/null | wc -l) == 6 ] ;then
		return 1
	fi
	return 0
}

function getnetwork(){
	network_status
	if [ $? == 1 ] ;then
		if [ "$led_status" != "off" ] ;then
			led_status="off"
			route_status_led $led_status
		fi
		return 0
	fi
	# network error
	if [ "$led_status" != "connection" ] ;then
		tmp_led_status="connecting"
		route_status_led $tmp_led_status
	fi

	url='http://110.188.66.35:801/eportal/?c=Portal&a=login&callback='$dr'&login_method=1&user_account=%2C0%2C'$account'&user_password='$passwd'&wlan_user_ip='$user_ip'&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=3.1&_='

	rep=$(curl -s $url --connect-timeout $s|grep -o '{.*}')
	if [ "$rep" == '{"result":"0","msg":"","ret_code":2}' ] ;then
		# 已经在线
		route_log "已经在线"
		tmp_led_status="off"
		return 0
	elif [ "$rep" == '{"result":"1","msg":"\u8ba4\u8bc1\u6210\u529f"}' ] ;then
		# 登录成功
		if [ "$tmp_led_status" != "off" ] ;then
			tmp_led_status="off"
		fi
		route_log "登录成功"
		return 1
	elif [ "$rep" == '{"result":"0","msg":"aW51c2UsIGxvZ2luIGFnYWluLCBwYyBPTG5vIDEgPj0gMQ==","ret_code":4}' ] ;then
		# 已在其他设备登录
		route_log "已在其他设备登录"
		return 2
	elif [ "$rep" == "" ] ;then
		get_user_ip
		if [ $? == 0 ] ;then
			if [ "$tmp_led_status" != "ip_drops" ] ;then
				tmp_led_status="ip_drops"
			fi
			route_log "error_ct ap失联丢失"
			return 3
		fi
		if [ "$tmp_led_status" != "ap_drops" ] ;then
				tmp_led_status="ap_drops"
		fi
		route_log "error_ap ap网络异常"
		return 4
	fi
	if [ "$tmp_led_status" != "error" ] ;then
			tmp_led_status="error"
	fi
	return 5
}



# main

while [ "66" == "66" ]
do
	route_status=2
	getnetwork
	route_status=$?
	if [ $route_status == 5 ] ;then
		route_log "error 出现未知异常"
		sleep 5m
		continue
	fi
	if [ "$tmp_led_status" != "$led_status" ] ;then
		led_status=$tmp_led_status
		route_status_led $led_status
	fi
	sleep 5s
done
