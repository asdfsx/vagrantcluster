# vagrantcluster

### 启动虚拟机
vagrant up 初次启动虚拟机的时候，会尽可能的用 apt 安装依赖软件。

初次启动之后，最好直接创建备份 `vagrant snapshot push`，方便之后回退。

启动虚拟机时，将hosts文件同步到各个虚拟机。所以在ansible的配置中，可以直接使用主机而不是 ip 地址。

启动虚拟机时，会将 share/authorized_keys 的内容添加到各个虚拟机上。所以启动后可以直接`ssh ubuntu@node1`。但是注意要根据情况清空宿主机上 ~/.ssh/known_hosts 中的内容。

### 初始化环境
启动之后，使用 `ansible-playbook -i inventory playbook/init/main.yml` 给每个机器做个 ssh-key 的初始化，让服务器之间可以直接用ssh登录。清除 /etc/hosts 中 127.0.0.1 的配置。更新 maven 的远程库配置。

### 安装 zookeeper
`ansible-playbook -i inventory playbook/zookeeper/main.yml`

### 安装 hadoop
hadoop配置了HA，所以namenode的个数至少是2个

貌似journalnode 必须是在datanode上。如果datandoe为2个，那么即使journalnode里配置了3个，最后也会启动2个。

namenode format 之前貌似需要启动jounalnode，可能会有数据传递。

启动流程大概是这样的
启动journalnodes -> format 主namenode -> 启动主namenode -> bootstrapStandby 从namenode -> 启动从 namenode -> 启动 datanode

如果这个时候不启动 zkfc 的话，会发现两个 namenode 都是 standby 。启动 zkfc 以后，其中一个会 active。

为了支持 hue，启动 webhdfs。单独启动 webhdfs 的服务原因是 增加 ha 的支持以后，active 节点会自动漂，所以不能直接使用 node1:50070 这样的配置。
启动的时候，指定配置文件所在的路径 `HTTPFS_CONFIG="/root/hadoop-2.7.3/conf" sbin/httpfs.sh start`
可以用 `http://node1:14000/webhdfs/v1/user/root?op=GETFILESTATUS&user.name=root&doas=root` 这个地址来测试一下 httpfs 是否正常。
不过在测试之前要在 hdfs 上创建 `/user/root` 目录

都完成之后，可以用 stop-all.sh、start-all.sh 来重启所有服务，再次验证配置。

关于lzo，最后还是从 github 上 clone 了 twitter 的代码，然后编译了一份，编译结果放在share里，希望能够重用。
lzo的支持需要两部分，一部分是 java实现的 jar 包，另一部分是 c 实现的 native 库。
jar 需要放到 $HADOOP_HOME/share/hadoop/common 里。
native 需要放到 $HADOOP_HOME/lib/native 里。

### 安装 mysql
`ansible-playbook -i inventory playbook/mysql/main.yml`

### 安装 hive
`ansible-playbook -i inventory playbook/hive/main.yml`
初始化的那些命令，可能还是手动执行比较好

启动metastore `nohup bin/hive --service metastore &`


测试 lzo
```
create table lzo(
id int,
name string)
STORED AS INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat';
```


### 安装 spark
`ansible-playbook -i inventory playbook/spark/main.yml`
spark 配置好以后，用下边的命令进行测试

```
./bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn --deploy-mode cluster --executor-memory 512m --executor-cores 1 examples/jars/spark-examples_2.11-2.1.0.jar 10


./bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn --deploy-mode client --executor-memory 512m --executor-cores 1 examples/jars/spark-examples_2.11-2.1.0.jar 10
```

启动 spark sql 需要先安装 hive。相当于 spark sql 是 hive 的一个查询引擎。spark sql 通过 hive 的metastore 来获取hive的元数据。

hive 安装并测试好以后，在hive-site.xml 中增加 hive.metastore.uris 的配置。
增加 hive.metastore.uris 的配置以后，hive 也需要通过 metastore 来获取元数据。如果 metastore 没有启动，那么 hive 也会失败。
启动metastore

```
bin/hive --service metastore
```

这个时候 hive 也可以正常启动了。
当 lzo 正确配置以后，用下边的 sql 进行测试。

```
create table lzo(
id int,
name string)
STORED AS INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat';
```


然后是 spark sql ，以下为个人猜测。
由于 spark 内置的 hive 客户端为 1.2.1，而我这里用的 hive 是2.1。可能新版本里有很多配置项是老版没有的，导致读取最新版的 hive-site 失败。
解决办法是，spark 中新建一个 hive-site，而不是将 hive 中的 hive-site 直接 copy 过来。新建的 hive-site 中，只有一个配置就是 hive.metastore.uris。

```
<configuration>
  <property>
  <name>hive.metastore.uris</name>
  <value>thrift://node1:9083</value>
  </property>
</configuration>
```

之后就可以启动 spark sql 了。但是貌似目前还不能支持 lzo。需要将之前编译好的 jar 包 copy 到 $SPARK_HOME/jars 中。现在 lzo 也 ok 了。


# 安装hue
没有编译好之后的，只能自己编译～～～FUCK

安装 编译工具

```
apt-get install -y ant gcc g++ libkrb5-dev libffi-dev libmysqlclient-dev libssl-dev libsasl2-dev libsasl2-modules-gssapi-mit libsqlite3-dev libtidy-0.99-0 libxml2-dev libxslt-dev make libldap2-dev maven python-dev python-setuptools libgmp3-dev
```

编译
PREFIX=/root/hue-3.12.0 make install


建表
CREATE DATABASE if not exists `hue_meta` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

同步数据
build/env/bin/hue syncdb
build/env/bin/hue migrate

启动hue
./build/env/bin/hue runserver 0.0.0.0:8888

supervisor 命令的启动方式总是失败，原因可能是因为没有配置 aws ，导致连接失败。

连接 hive
首先启动 metastore 和 hiveserver2

```
nohup bin/hive --service metastore &
nohup bin/hive --service hiveserver2 &
```

注意如果要让 hue 支持 namenode ha，需要单独启动一个 httpfs 服务

安装编译 livy，它是 hue 和 spark 的一个桥梁。
花了4个小时，依赖项太多。
编译完成后，配置到 hue 中，然后启动服务。


参考文章：  
http://www.cnblogs.com/julyme/p/5196797.html  
http://blog.csdn.net/dockj/article/details/53122054  