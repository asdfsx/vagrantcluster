# {{ ansible_managed }}

export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.131-3.b12.el7_3.x86_64"
export HADOOP_LOG_DIR={{log_dir}}
export HADOOP_PREFIX={{hadoop_dir}}
export HADOOP_OPTS="-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=8 -XX:+ExplicitGCInvokesConcurrent -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:{{ log_dir }}/hadoop-hdfs/hadoop-hdfs-gc.log"
