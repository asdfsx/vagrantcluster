# vagrantcluster

vagrant 启动虚拟机的时候，将hosts文件同步到各个虚拟机。所以在ansible的配置中，可以直接使用主机而不是 ip 地址.

hadoop配置了HA，所以namenode的个数至少是2个
