# vagrantcluster

vagrant 启动虚拟机的时候，将hosts文件同步到各个虚拟机。所以在ansible的配置中，可以直接使用主机而不是 ip 地址.

hadoop配置了HA，所以namenode的个数至少是2个

貌似journalnode 必须是在datanode上。如果datandoe为2个，那么即使journalnode里配置了3个，最后也会启动2个。

namenode format 之前貌似需要启动jounalnode，可能会有数据传递

secondary namenode 貌似手动启动是最靠谱的，而且好像也不需要执行bootstrap那个命令了

关于lzo，最后还是从 github 上 clone 了 twitter 的代码，然后编译了一份，编译结果放在share里，希望能够重用。
lzo的支持需要两部分，一部分是 java实现的 jar 包，另一部分是 c 实现的 native 库。
jar 需要放到 $HADOOP_HOME/share/hadoop/common 里。
native 需要放到 $HADOOP_HOME/lib/native 里。

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

然后修改 


参考文章：  
http://www.cnblogs.com/julyme/p/5196797.html  
http://blog.csdn.net/dockj/article/details/53122054  