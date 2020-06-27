xpid=$(ps -ef | grep tomcat | grep -v grep | awk -F ' ' '{print $2}')
if [ -n "${xpid}" ];then
	sudo rm -rf /tmp/lock.file
	kill -9 $xpid
fi
