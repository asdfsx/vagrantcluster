# {{ ansible_managed }}

export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre"

export HADOOP_OPTS="-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=8 -XX:+ExplicitGCInvokesConcurrent -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:{{ log_dir }}/hadoop-hdfs/hadoop-hdfs-gc.log"
