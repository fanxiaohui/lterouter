#!/bin/bash

#脚本实现功能：
#1.初始化gpio
#2.启动模组
#
#
GpioDir=/sys/class/gpio
PowerOn=121
Reset=123
NetLed=122
WakeupIn=1
WakeupOut=30
SleepSta=3

logFile=/var/log/messages

letrouter=/opt/init/lterouter
routerweb=/opt/web/bin/router-web

#udhcpd /etc/udhcpd.conf &

#导出各gpio
InitGpio(){
    cd $GpioDir
    if [ -e gpio$PowerOn ]
    then
        echo "gpio$PowerOn done!" >> $logFile
    else
        echo $PowerOn > export
    fi
    if [ -e gpio$Reset ]
    then
        echo "gpio$Reset done!" >> $logFile
    else
        echo $Reset > export
    fi
    if [ -e gpio$NetLed ]
    then
        echo "gpio$NetLed done!" >> $logFile
    else
        echo $NetLed > export
    fi
    if [ -e gpio$WakeupIn ]
    then
        echo "gpio$WakeupIn done!" >> $logFile
    else
        echo $WakeupIn > export
    fi
    if [ -e gpio$WakeupOut ]
    then
        echo "gpio$WakeupOut done!" >> $logFile
    else
        echo $WakeupOut > export
    fi
    if [ -e gpio$SleepSta ]
    then
        echo "gpio$SleepSta done!" >> $logFile
    else
        echo $SleepSta > export
    fi
}

TurnOn(){
    cd $GpioDir/gpio$PowerOn
    echo out > direction
    echo 0 > value;sleep 2;echo 1 > value;sleep 5
}

TurnOff(){
    cd $GpioDir/gpio$PowerOn
    echo out > direction
    echo 0 > value;sleep 4;echo 1 > value;sleep 10
}

Reboot(){
	cd $GpioDir/gpio$Reset
	echo out > direction
	echo 0 > value;sleep 1;echo 1 > value;sleep 15 
}
#系统重启时硬件重启模组
InitModule(){
    echo "start to Detect" >> $logFile
    ret=`DetectDev`
    if [ $ret -eq 0 ]
    then
        echo "Dev Ok,reboot module!" >> $logFile
		Reboot
    else
        echo Turn on Module! >> $logFile
        TurnOn
    fi
}

DetectLterouter(){
	ps -fe|grep "lterouter" |grep -v grep
	if [ $? -ne 0 ]
	then
		echo 0
	else
		echo 1
	fi
	if [ `ps | grep lterouter | wc -l` -eq 1 ]
	then
		echo 0 #进程未启动
	else
		echo 1
	fi
}

DetectRouterweb(){
	if [ `ps | grep router-web | wc -l` -eq 1 ]
	then
		echo "router-web 进程未启动" >> $logFile
		echo 0 #进程未启动
	else
		echo 1
	fi
}

DetectDev(){
    cd /dev/
    ret=`ifconfig -a | grep usb0`

	#检查usb0网卡及虚拟串口是否存在
    if [ $? -eq 0 ] && [ -e  ttyem300 ]
    then
        echo 0
    else
        echo 1
    fi
#	echo 0
}
#lterouter启动前杀死udhcpd
killdhcpd(){
	ret=`pidof udhcpd`
	nohup kill $ret > /dev/null 2>&1 &
}

runDtu(){
	if [ -e /opt/config/startDtu ]
	then
		ps -fe|grep "suyi_dtu" |grep -v grep >> /dev/null
		if [ $? -ne 0 ]
		then
			echo "startDtu!!!!!!" >> $logFile 
ill -9 $ret &
			nohup /opt/dtu/suyi_dtu >/dev/null 2>&1 &
		fi
	else
		ret=`pidof suyi_dtu`
		nohup kill -9 $ret > /dev/null 2>&1 &
	fi

}

checkSecurityLib(){
	echo "do nari init" >> $logFile
	
	if [ -e "/lib/libnari.so" ]
	then
		echo "do nothing" >> $logFile
	else
		echo "do nariinit.sh" >> $logFile
		cd /opt/security;
		./nariinit.sh
	fi
	
}

runSecurity(){
	if [ -e /opt/config/startSecurity ]
	then
		ps -fe|grep "naripcaccess" |grep -v grep >> /dev/null
		if [ $? -ne 0 ]
		then
			echo "startSecurity!!!!!!!!" >> $logFile 
			nohup /opt/security/naripcaccess /opt/security/naripcaccess.conf >/dev/null 2>&1 &
		fi
	else
		ret=`pidof naripcaccess`
		nohup kill -9 $ret > /dev/null 2>&1 &
		echo > /opt/log/SecurityLog
	fi

}

InitWork(){
    echo "start to work" >> $logFile
	while [ `DetectDev` -eq 0 ]
	do
		ps -fe|grep "router-web" |grep -v grep >> /dev/null
		if [ $? -ne 0 ]
		then
			echo "router-web start!!" >> $logFile
			nohup /opt/web/bin/router-web > /dev/null 2>&1 &
#		else
#			echo "router-web done!"
		fi
		sleep 1
		#echo "dev ok"
		ps -fe|grep "lterouter" |grep -v grep >> /dev/null
		if [ $? -ne 0 ]
		then
			echo "lterouter start!!" >> $logFile
			killdhcpd
			nohup /opt/init/lterouter > /dev/null 2>&1 &
#		else
#			echo "lterouter done!"
		fi
		sleep 1
		runSecurity
		sleep 1;
		runDtu
		
	done

	echo "dev not found" >> $logFile
	echo "Reboot system!!!" >> $logFile
	cp /var/log/messages /opt/log/syslog

	sleep 10
	#`reboot`
	#shutdown -r now	#当设备挂载失败时重启系统
}

InitGpio
InitModule
checkSecurityLib
InitWork
#/opt/init/lterouter &
#/opt/web/webroot/bin/router-web &
