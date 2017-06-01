# 调度系统
### 基础依赖安装

初始化 ssh key
```
ansible-plabook -i inventory playbook/init/main.yml
```

安装 mysql
```
ansible-plabook -i inventory playbook/mysql/main.yml
```

安装 postgresql
```
ansible-plabook -i inventory playbook/postgresql/main.yml 
```

安装 rabbitmq
```
ansible-plabook -i inventory playbook/rabbitmq/main.yml
```

安装 redis
```
ansible-plabook -i inventory playbook/redis/main.yml
```

安装 etcd
```
ansible-plabook -i inventory playbook/etcd/main.yml
```

### airflow

安装 airflow
```
ansible-plabook -i inventory playbook/airflow/main.yml
```

安装完成后，配置文件都放在 `/root/airflow` 下。目前的配置使用了 `postgresql`作为后端存储，并使用 `rabbitmq` 作为 `celery broker`。

所有的服务需要手工启动。

启动 airflow

* 服务端
  ```
  启动 airflow flower
  $ airflow flower &

  启动 airflow scheduler
  $ airflow scheduler &

  启动 airflow webserver
  $ airflow webserver --debug &
  ```

* 工作端
  ```
  启动 airflow worker
  $ airflow worker
  ```

* 数据库初始化、还原命令
  ```
  初始化库
  $ airflow initdb
  清空库
  $ airflow resetdb
  ```
  数据库配置成功后，可以用这两个命令轻松对数据库进行初始化和还原


说明
* `airflow` 使用 sqlachemy 作为 orm 工具，然而因为很多字段长度过大（长度为2000的字符串），导致使用mariadb时经常出现 `out of index` 一类的错误。解决办法除了修改 `innodb_file_format` 等参数以外，还必须将默认字符集改为 `latin1`。

* `cellry` 可以使用 `rabbitmq` 和 `redis` 作为 `broker`。在使用 `rabbitmq`时，会遇到驱动的问题。问题描述：[Received and deleted unknown message. Wrong destination issue](https://github.com/celery/celery/issues/3675)。解决办法，卸载 librabbitmq 驱动，安装 pyamqp 驱动。

* `scheduler` 异常或崩溃。在使用 `rabbitmq` 作为 `broker`时，`scheduler` 启动异常。或者说在 `1.8.x` 的版本里启动直接崩溃；在 `1.7.1.3`里可以启动，但是会报错。
问题描述：[](https://issues.apache.org/jira/browse/AIRFLOW-342)

* `dag` 的同步。服务器上的 `dag`，需要同步到各个工作节点。服务器可以将要执行的 `dag` 转成二进制编码保存到数据库中，然后将任务编号下发到工作端，工作端根据编号从数据库中读取 `dag` 二进制编码，然后转成 `python` 编码执行。听起来很厉害，但是`pickle`的过程貌似现在有问题，在`backfill`命令里，遇到过`pickle`失败的问题，解决办法是使用 `donot_pickle` 参数。

### luigi

安装 luigi
```
ansible-plabook -i inventory playbook/luigi/main.yml
```

安装完成后，配置文件都放在 `/root/luigi` 下。

手工启动程序。

* 服务端
  ```
  启动 `central scheduler`
  $ LUIGI_CONFIG_PATH=/root/luigi/luigi.cfg luigid
  ```

* 工作端
  ```
  开启任务
  $ luigi --module examples.foo examples.Foo --workers 2
  ```
说明：
* 在工作端上要设置 `PYTHONPATH`，所有要执行的任务要存放 `PYTHONBPATH` 下。

### dkron

安装 dkron
```
ansible-plabook -i inventory playbook/dkron/main.yml
```

安装完成后，配置文件都放在 `/root/dkron/config` 下。

启动
```
$ cd /root/dkron
$ ./dkron agent -server
```

通过 `restful` 接口访问 `api`

* 获取 `agent` 状态
  ```
  curl -X GET http://node1:8080/v1/?pretty=true
  ```

* 获取 `leader` 信息
  ```
  curl -X GET http://node2:8080/v1/leader?pretty=true
  ```

* 获取成员列表
  ```
  curl -X GET http://node2:8080/v1/members?pretty=true
  ```

* 添加任务
  ```
  curl -H "Content-Type: application/json" -X POST -d '{"name":"job_name","command":"/bin/true","schedule":"@every 2m"}' http://node1:8080/v1/jobs?pretty=true
  ```

* 获取任务列表
  ```
  curl -X GET http://node1:8080/v1/jobs?pretty=true
  ```
* 获取单个任务
  ```
  curl -X GET http://node1:8080/v1/jobs/job_name?pretty=true
  ```

* 获取任务执行信息
  ```
  curl -X GET http://node1:8080/v1/executions/job_name?pretty=true
  ```

* 删除任务
  ```
  curl -X DELETE http://node1:8080/v1/jobs/job_name?pretty=true
  ```

### 
