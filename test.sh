#!/bin/bash

#read the the paxstore.conf and then we will provide more convenient functions

#firest shoud all the status 
# ls
#	            1(22)    2(23)   3(24)     4(25)    5(26)    6(27)    7(28)
#
#	range 1      ok        ok     ok 
#	range 2                ok     ok        ok
#	range 3                       ok        ok        ok       
#	range 4                                 ok        ok       ok    
#

# recover -range 1   

#restart -range 2 -id 1

#start -range 2 -id 2

#stop -range 2 -id 2
 
#stop -server	2    {"this stop all the instance of one server"



#get the binpath name
#shpath=/home/sjl/project/paxoslog9-multi-test/paxoslog/single.sh
shpath=/home/dyx/project/paxstore/single.sh

#get the binname
binname=$(grep "BINNAME" /etc/paxstore.conf | awk '{print $3}' )

#get server num
numberserver=$(grep "NumServer" /etc/paxstore.conf  | awk  '{print $3}' )
echo "NumServer" $numberserver

#get the server ip info
declare -a severs
for ((num=1; num<=$numberserver; num++))
do
	servername=SERVER${num}_IP
	servers[$num]=$(grep $servername /etc/paxstore.conf | awk '{print $3}')	
	echo ${servers[$num]}
done

#get range_num
rangenumber=$(grep "RANGE_NUM" /etc/paxstore.conf  | awk  '{print $3}' )

#get the range server
declare -a rangenumber
for ((num=1; num<=$rangenumber; num++))
do
	rangename=RANGE${num}_SERVERS
	rangeservers[$num]=$(grep $rangename /etc/paxstore.conf | awk '{print $3}')	
	echo ${rangeservers[$num]}
done


#get the rangerserverid by the range index and array index

rangeserver_index_index(){
	servers=${rangeservers[$1]}	
	serverid=`echo $servers | cut -d, -f$2`	
	#echo $serverid	
	return $serverid
}

printhead(){
	printf "\t"
	for ((num=1; num<=$numberserver; num++ ))	
	do
		serverip=${servers[$num]}
		printf "(id=%d)(%s)  " $num ${serverip##*192.168.3.}
	done
	printf "\n"
}
printcontext()
{
	printindex=$1
	for ((index=1; index<=$numberserver; index++))	
	do
		state=${printindex[$index]}
		if [ $state == 1 ];then
			printf "OK           "
		else
			printf "             "
		fi	
	done		
	printf "\n"
	
}
#show the system status
ls(){	
	declare -a printindex
	printhead	
	for ((num=1; num<=$rangenumber; num++))
	do
		printf "range%d\t" $num	
		each_num=3

		for ((index=1; index<=$numberserver; index++))
		do
			printindex[$index]=0	
		done

		for ((index=1; index<=$each_num; index++))
		do
			rangeserver_index_index $num $index
			serverid=`echo $?`
			#the use the ssh to check remote machine state
			#printf "ssh root@%s ps -ef | grep %s *%d  | grep -v grep | wc -l\n" ${servers[$serverid]} $binname $num
			count=`ssh root@${servers[$serverid]}  ps -ef | grep "$binname *$num" | grep -v "grep" | wc -l`
			if [ "$count" == "0" ];then 
				continue	
			elif [ "$count" == "1" ];then
				printindex[$serverid]=1
			else
				echo "count:" $count
				echo "fuck error"	
			fi
		done		
		printcontext $printindex	
	done
}

start(){
	rangeid=$1
	serverid=$2
	ifrecover=$3
	ssh root@${servers[$serverid]}  $shpath start $rangeid $ifrecover			
}

stop(){
	rangeid=$1
	serverid=$2
	ssh root@${servers[$serverid]}  $shpath stop $rangeid			
}



restart(){
	rangeid=$1
	serverid=$2
	ifrecover=$3
	ssh root@${servers[$serverid]}  $shpath restart $rangeid $ifrecover			
}


startrange(){
	rangeid=$1
	ifrecover=$2
        each_num=3
	for ((num=1; num<=$each_num; num++))
	do 
		rangeserver_index_index $rangeid $num
		serverid=`echo $?`
		ifrecover=0
		ssh root@${servers[$serverid]}  $shpath start $rangeid $ifrecover			
	done
}

stoprange(){
	rangeid=$1
        each_num=3		
	for ((num=1; num<=$each_num; num++))
	do 
		rangeserver_index_index $rangeid $num
		serverid=`echo $?`
		ssh root@${servers[$serverid]}  $shpath stop $rangeid			
	done
}

startall(){
	for (( range_index=1; range_index<=$rangenumber; range_index++ ))	
	do
		ifrecover=0
		startrange $range_index $ifrecover
	done	
}

stopall(){
	for (( range_index=1; range_index<=$rangenumber; range_index++ ))	
	do
		stoprange $range_index	
	done	
}



while true;do
	#printf "==>"
	read -e -p  "==>" cmd
	The1=$(echo $cmd | awk '{print $1}')		
	The2=$(echo $cmd | awk '{print $2}')	
	The3=$(echo $cmd | awk '{print $3}')	
	The4=$(echo $cmd | awk '{print $4}')	
	The5=$(echo $cmd | awk '{print $5}')	
	The6=$(echo $cmd | awk '{print $6}')	
	The7=$(echo $cmd | awk '{print $7}')	
	
	

	case  "$The1" in
		ls )
			ls
			;;
		start )
			if [[ "$The2" != "-range" || "$The4" != "-id" || "$The6" != "-recover" ]];then
				echo "cmd error"
				continue
			else
				echo "fuck"
				start $The3 $The5 $The7
			fi
			;;
		stop )
			
			if [[ "$The2" != "-range" || "$The4" != "-id" ]];then
				echo "cmd error"	
				continue
			else
				stop $The3 $The5
			fi
			;;
		restart )
			
			if [[ "$The2" != "-range" || "$The4" != "-id" || "$The6" != "-recover" ]];then
				echo "cmd error"	
				continue
			else
				restart $The3 $The5 $The7
			fi
			;;
		startrange )
			startrange $The2	
			;;
		stoprange )
			stoprange $The2
			;;
		startall )
			startall	
			;;
		stopall )
			stopall
			;;
		help )
			echo "ls"
			echo "start -range 1 -id 2 -recover 1"	
			echo "stop -range 1 -id 2 "	
			echo "restart -range 1 -id 2 -recover 0"
			echo "startrange 2 -recover 0"
			echo "stoprange 2 "
			echo "startall"
			echo "stopall"
	
			;;
		*)
			printf "others\n"		
	esac
	printf "\n"
done