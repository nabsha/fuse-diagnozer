#!/bin/bash
 
HOSTNAME=localhost
PORT=8181
HOST=${HOSTNAME}:${PORT}
USER=admin
PASS=admin
 
FOLDER=diagnostics-${HOSTNAME}-$(date '+%Y-%m-%d-%H-%M-%S')
FOLDER_PATH=/tmp/${FOLDER}
 
# Do not change anything below this line
 
CWD=$(pwd)
 
mkdir -p ${FOLDER_PATH}
cd ${FOLDER_PATH}
 
echo "Collecting vmstat..."
vmstat 1 20 > vmstat.txt &
 
echo "Collecting iostat..."
iostat 1 20 > iostat.txt &
 
echo "Taking heap dump"
sudo -u fuse /bin/bash -c 'jmap -dump:format=b,file=/tmp/jvm.`cat /opt/fuse-esb/data/fuse-esb.pid`.hprof `cat /opt/fuse-esb/data/fuse-esb.pid` &'
echo "Collecting cpuspecs..."
cat /proc/cpuinfo > cpuspecs.txt
 
echo "Identifying linux distribution..."
cat /etc/*-release > linuxdistro.txt
 
echo "Collecting rpms..."
rpm -qa > rpms.txt
 
echo "Copying hosts file..."
cp /etc/hosts .
echo "Collecting available memory..."
free > free.txtcat /proc/meminfo >> free.txt
 
echo "Collecting jvm stats..."
 
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/java.lang:type=Memory > memory.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/java.lang:type=ClassLoading > classloading.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/java.lang:type=GarbageCollector,name=* > gc.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/java.lang:type=OperatingSystem > os.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/java.lang:type=Runtime > runtime.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/java.lang:type=Threading > threading.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/org.apache.activemq:type=Broker,brokerName=amq > amq.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/org.apache.activemq:type=Broker,brokerName=amq,destinationType=Queue,destinationName=* > queues.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/org.apache.activemq:type=Broker,brokerName=amq,destinationType=Topic,destinationName=* > topics.txt
curl -u ${USER}:${PASS} http://${HOST}/jolokia/read/org.apache.camel:context=*,type=routes,name=* > routes.txt
 
echo "Compressing configurations..."
tar -pczf config.tar.gz /opt/fuse-esb/etc
 
echo "Compressing logs..."
tar -pczf logs.tar.gz /opt/fuse-esb/data/log/
 
echo "Waiting for data collection to finish..."
wait # wait for background processes to complete
cd ..
 
echo "Compressing files..."
cd ${CWD}
tar -pczf ${FOLDER}.tar.gz ${FOLDER_PATH}