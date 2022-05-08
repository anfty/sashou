# sashou
Automatic authentication script for campus network
--- 
sashou是一个适用于linux系统的校园网登录工具，目前只是一个刚好能用的小脚本。  
限制了登录数量的校园网建议使用openwrt路由器。

## 项目背景

学校的宽带限制两个设备登录，当其他设备需要网络服务时需要繁琐地在不同设备登录宽带，sashou孕育而生。

## 依赖

纯shell所需工具linux都预装

- sh
- curl
- cut
- grep
- date
- ip


## sashou能做什么

- 通过构建的GET请求登录宽带账号
- 搭配crontab/rclocal可完成无感校园网认证

//建设中
- 实时检测网络状态/断网重连
- gui
- 运行在其他平台

## 如何使用

```
SASHOU automatic authentication script
		-a : 宽带账号
		-p : 宽带密码
		-u : ap分配的ip
		-s : 设置超时时间
		-n : 网卡名
example:
        sashou.sh -a 12345678901 -p 12345678 -u 192.168.8.1 -s 1 -n wlan
```
## 未来

作者想其他学校的校园网认证方式，制作一个全平台的自动登录工具。  
如果这个工具无法帮助到你，请提供你的认证过程流量。
