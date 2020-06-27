#! /bin/bash

function checkLogDir() {
	if [ -d "${logFileRoot}/$1}" ];then
		mkdir -p "${logFileRoot}/$1"
	fi 
}

function initScriptData() { # 初始化脚本数据
	
	# source /etc/profile
	# source ~/.bash_profile

	export serviceFlag="tomcat" # 进程标识
	export serviceStartScript="/home/achui/apache-tomcat-8.5.56/bin/startup.sh" # 服务启动脚本
	export serviceEndScript="" # 服务停止脚本
	export logFileRoot="" # 日志存放根目录
	export logFileDir=("" "" "" "jmap") # 日志二级细分目录名（数据的形式给出）
	export flagFile="/tmp/lock.file" # 脚本临时标识文件名（用于脚本运行时数据的临时交换，禁止填写不稳定路径，如tmp）
	# export scriptWorkDir=$(dirname $(readlink -f $1))
	export scriptWorkDir="/home/achui/serviceManger.sh" # 脚本工作路径 （绝对路径包含脚本名）
	export crontabFile="/home/achui/testcron"

	for i in ${logFileDir[@]}
	do
		checkLogDir $1
	done 
	
}

function getCrash() {
	echo "get Crash log"
}

function creatScriptFlag() {
	servicePID=$(ps -aux | grep ${serviceFlag} | grep -v "grep" | awk -F ' ' '{print $2}')
	echo ${servicePID} > ${flagFile}
}

function setCrontab() {
	flockCommand="sh -x ${scriptWorkDir} healthcheck' >> /tmp/test 2>&1"
	crontab -l > ${crontabFile}
	sed -i '/healthcheck/d' ${crontabFile}
	echo "* * * * * flock -xn ${flagFile} -c '${flockCommand}" >> ${crontabFile}
	crontab ${crontabFile}
}

function unsetCrontab() {
	sed -i '/healthcheck/d' ${crontabFile} #将定时任务取消
	crontab ${crontabFile}
}

function startServiceFromScript() {
	cd $(dirname ${serviceStartScript})
	${serviceStartScript}
    creatScriptFlag
    setCrontab
}

function healthcheck() {
	countServiceProgress=$(ps -aux | grep ${serviceFlag} | grep -v "grep" | awk -F ' ' '{print $2}' | wc -l)
	if [ ${countServiceProgress} -eq 0 ];then
		echo "未查到该进程信息"
		if [ -f ${flagFile} ];then
			# 文件存在证明进程是被异常杀死的
			flagPid=$(cat ${flagFile})
			getCrash ${flagPid}
			startServiceFromScript
			echo "service restart from exception"
		else
			# 首次启动或者正常调用stop后，再次启动
			startServiceFromScript
			echo "service start normal"
		fi
	elif [ ${countServiceProgress} -eq 1 ];then
		
		echo "进程已经启动"
	elif [ ${countServiceProgress} -gt 1 ];then
		echo "多进程异常"
	fi
}

function startService() { # 服务开启脚本
	healthcheck
}

function main() {
	
	if [ -n "$2" ];then # 确保脚本接收到正确的调用参数
		
		paramsSet=("start" "stop" "healthcheck")  # 脚本数据初始化
		if echo "${paramsSet[@]}" | grep -w "$2" &>/dev/null; then
			initScriptData $2
		fi
		
		case "$2" in  # 脚本功能调用
    		"start")
      			startService
    			;;
  			"stop")
    			stopService
    			;;
  			"healthcheck")
    			healthcheck
    			;;
  			*)
    			echo "please input true param, your input ${2}, param in (start stop healthcheck)"
    			;;
		esac
	else
		echo "please input param, param in (start stop healthcheck)"
	fi
}

main $0 $1
