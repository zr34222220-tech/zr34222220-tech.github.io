---

title: docker
weight: 10 
date: 2025-12-12
draft: false 

---

# docker

### 安装

---

linux：``yum install docker-ce docker-ce-cli containerd.io``

**docker-ce**：Docker守护进程，负责所有的容器管理工作，在 Linux 上依赖另外两个完成工作

**docker-ce-cli** ：用于控制Docker守护进程的 CLI 工具（可以通过CLI工具控制远程 Docker 守护进程）

**containerd.io** ： 守护进程与操作系统之间的接口层，本质上将Docker与操作系统分离

> containerd 可用作 Linux 和 Windows 的守护程序。 它管理其主机系统的完整容器生命周期，从图像传输和存储到容器执行和监督，再到低级存储到网络附件等等

启动docker守护进程

```shell
systemctl start docker
```

查看docker进程状态

```shell
systemctl start docker
```

卸载docker

```shell
yum remove docker-ce #卸载

rm -rf /var/lib/docker #删除镜像、容器、配置文件等内容
```



### 镜像命令

---

**docker images**  查看所有本地的主机上的镜像

```shell
[root@kuangshen /] #docker images
REPOSITORY 	 TAG	  IMAGE ID	       CREATED	     SIZE
hello-world	latest	bf756fblae65	4 months ago	13.3kB

#解释
REPOSITORY	镜像的仓库源
TAG			镜像的标签
IMAGE ID	镜像的id
CREATED		镜像的创建时间
SIZE		镜像的大小

#可选项
	-a,--a11		#列出所有镜像
	-q,--quiet		#只显示镜像的id
```

下载镜像

```shell
# 下载镜像 docker pull 镜像名[:tag]
```

 删除镜像 

```shell
docker rmi -f	#(i是image的意思)
docker rmi -f  容器id 容器id 容器id   #删除多个镜像
docker rmi -f  $(docker images -aq) #删除全部的镜像
```



### 容器命令

---

**说明：我们有了镜像才可以创建容器**
``docker pull centos``
**新建容器并启动**
``docker run[可选参数]image``
#参数说明

```shell
--name="Name"	容器名字
-d				后台方式运行
-it				使用交互方式运行，进入容器查看内容
-p				指定容器的端口 -p 8080:8080
	-p 主机端口：容器端口
	-p 容器端口
	容器端口
-P				随机指定端口

#测试并进入容器
docker -it ubuntu /bin/bash
#从容器退回主机
exit
```

**列出所有的运行的容器**

```shell
# docker ps 命令
-a  #列出当前正在运行的容器+带出历史运行过的容器
-n=?  #显示最近创建的容器
-q  #只显示容器的编号
```

**退出容器**

```shell
exit  #直接容器停止并退出
CTRL + P + Q  #容器不停止退出

#再次进入容器
docker exec -it name/id /bin/bash
```

**删除容器**

```shell
docker rm 容器id			#删除指定容器，不能删除正在运行的容器，如果要强制删除 rm -rf
docker rm -f $(docker ps -aq) #删除所有容器
docker ps-a-q|xargs docker rm #删除所有的容器
```

**启动和停止容器的操作**

```shell
docker start 容器id		#启动容器
docker restart 容器id		#重启容器
docker stop 容器id		#停止当前正在运行的容器
docker kill 容器id		#强制停止当前容器
```



### 常用其他命令

**后台启动**

```shell
#命令docker run -d 镜像名
docker run -d ubuntu

#问题docker ps,发现ubuntu停止了

#常见的坑：docker容器使用后台运行，就必须要有要一个前台进程，docker发现没有应用，就会自动停止

#ngin×,容器启动后，发现自己没有提供服务，就会立刻停止，就是没有程序了
```

**查看日志**

```shell
docker logs -f -t --tail 容器，没有日志

#显示日志
-tf				#显示日志
--tai1 number	#要显示日志条数
docker logs -tf --tail 10 dce7b86171bf
```

**查看容器中的进程信息 **ps

```shell
#命令 docker top 容器id
# docker top eb4f02f782e9
```

**查看镜像的元数据**

```shell
docker inspect 容器id

# 测试
[
    {
        "Id": "eb4f02f782e94f72d26a9469268cb71643fee45df12863751f7d43cf44c56206",
        "Created": "2026-03-16T07:31:46.117978975Z",
        "Path": "/bin/bash",
        "Args": [],
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 939674,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": "2026-03-16T07:31:46.156823581Z",
            "FinishedAt": "0001-01-01T00:00:00Z"
        },
        "Image": "sha256:bbdabce66f1b7dde0c081a6b4536d837cd81dd322dd8c99edd68860baf3b2db3",
        "ResolvConfPath": "/var/lib/docker/containers/eb4f02f782e94f72d26a9469268cb71643fee45df12863751f7d43cf44c56206/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/eb4f02f782e94f72d26a9469268cb71643fee45df12863751f7d43cf44c56206/hostname",
        "HostsPath": "/var/lib/docker/containers/eb4f02f782e94f72d26a9469268cb71643fee45df12863751f7d43cf44c56206/hosts",
        "LogPath": "",
        "Name": "/determined_ride",
        "RestartCount": 0,
        "Driver": "overlay2",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "",
        "ExecIDs": null,
        "HostConfig": {
            "Binds": null,
            "ContainerIDFile": "",
            "LogConfig": {
                "Type": "journald",
                "Config": {}
            },
            "NetworkMode": "bridge",
            "PortBindings": {},
            "RestartPolicy": {
                "Name": "no",
                "MaximumRetryCount": 0
            },
            "AutoRemove": false,
            "VolumeDriver": "",
            "VolumesFrom": null,
            "ConsoleSize": [
                37,
                62
            ],
            "CapAdd": null,
            "CapDrop": null,
            "CgroupnsMode": "private",
            "Dns": [],
            "DnsOptions": [],
            "DnsSearch": [],
            "ExtraHosts": null,
            "GroupAdd": null,
            "IpcMode": "private",
            "Cgroup": "",
            "Links": null,
            "OomScoreAdj": 0,
            "PidMode": "",
            "Privileged": false,
            "PublishAllPorts": false,
            "ReadonlyRootfs": false,
            "SecurityOpt": null,
            "UTSMode": "",
            "UsernsMode": "",
            "ShmSize": 67108864,
            "Runtime": "runc",
            "Isolation": "",
            "CpuShares": 0,
            "Memory": 0,
            "NanoCpus": 0,
            "CgroupParent": "",
            "BlkioWeight": 0,
            "BlkioWeightDevice": [],
            "BlkioDeviceReadBps": [],
            "BlkioDeviceWriteBps": [],
            "BlkioDeviceReadIOps": [],
            "BlkioDeviceWriteIOps": [],
            "CpuPeriod": 0,
            "CpuQuota": 0,
            "CpuRealtimePeriod": 0,
            "CpuRealtimeRuntime": 0,
            "CpusetCpus": "",
            "CpusetMems": "",
            "Devices": [],
            "DeviceCgroupRules": null,
            "DeviceRequests": null,
            "MemoryReservation": 0,
            "MemorySwap": 0,
            "MemorySwappiness": null,
            "OomKillDisable": null,
            "PidsLimit": null,
            "Ulimits": [
                {
                    "Name": "nofile",
                    "Hard": 1048576,
                    "Soft": 1048576
                }
            ],
            "CpuCount": 0,
            "CpuPercent": 0,
            "IOMaximumIOps": 0,
            "IOMaximumBandwidth": 0,
            "MaskedPaths": [
                "/proc/asound",
                "/proc/acpi",
                "/proc/interrupts",
                "/proc/kcore",
                "/proc/keys",
                "/proc/latency_stats",
                "/proc/timer_list",
                "/proc/timer_stats",
                "/proc/sched_debug",
                "/proc/scsi",
                "/sys/firmware",
                "/sys/devices/virtual/powercap"
            ],
            "ReadonlyPaths": [
                "/proc/bus",
                "/proc/fs",
                "/proc/irq",
                "/proc/sys",
                "/proc/sysrq-trigger"
            ]
        },
        "GraphDriver": {
            "Data": {
                "ID": "eb4f02f782e94f72d26a9469268cb71643fee45df12863751f7d43cf44c56206",
                "LowerDir": "/var/lib/docker/overlay2/d6d57af9633a037dd370075aafd79b2ad1a86e367f034c56346abc83d3093f58-init/diff:/var/lib/docker/overlay2/bc3595e86754f83707ce0d94ffed323fbd7ce99b13d7c6a1f46c1b7d168f4810/diff",
                "MergedDir": "/var/lib/docker/overlay2/d6d57af9633a037dd370075aafd79b2ad1a86e367f034c56346abc83d3093f58/merged",
                "UpperDir": "/var/lib/docker/overlay2/d6d57af9633a037dd370075aafd79b2ad1a86e367f034c56346abc83d3093f58/diff",
                "WorkDir": "/var/lib/docker/overlay2/d6d57af9633a037dd370075aafd79b2ad1a86e367f034c56346abc83d3093f58/work"
            },
            "Name": "overlay2"
        },
        "Mounts": [],
        "Config": {
            "Hostname": "eb4f02f782e9",
            "Domainname": "",
            "User": "",
            "AttachStdin": true,
            "AttachStdout": true,
            "AttachStderr": true,
            "Tty": true,
            "OpenStdin": true,
            "StdinOnce": true,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ],
            "Cmd": [
                "/bin/bash"
            ],
            "Image": "bbdabce66f1b",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": {
                "org.opencontainers.image.ref.name": "ubuntu",
                "org.opencontainers.image.version": "24.04"
            }
        },
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "081b9b1d6861aa752c157577cdb2f08983261cfc2eced37541200a0b0a242e7b",
            "SandboxKey": "/var/run/docker/netns/081b9b1d6861",
            "Ports": {},
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "dd50aa205dea7bf9fc26cdd6f338c2617d18df363c46cbfc380aad2c85dae10c",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "92:dd:75:58:9a:75",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "MacAddress": "92:dd:75:58:9a:75",
                    "DriverOpts": null,
                    "GwPriority": 0,
                    "NetworkID": "dea7c5c8d4570244c18725b431769ddf3f4c4d81ba9c5744af7040d4edd40e75",
                    "EndpointID": "dd50aa205dea7bf9fc26cdd6f338c2617d18df363c46cbfc380aad2c85dae10c",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "DNSNames": null
                }
            }
        }
    }
]
```

**进入当前正在运行的容器**

```shell
#命令1
docker exec -it 容器id  /bin/bash
# 进入容器后开启一个新的终端，可以在里而操作（常用）
#命令2
docker attach 容器id  /bin/bash
# 进入容器正在执行的终端，不会启动新的进程！
```

**从容器内拷贝文件到主机上**

```shell
docker cp 容器id:容器内路径  目的的主机路径
docker cp eb4f02f782e9:/home/zrzr.txt /root/

```



### 作业练习

> docker 安装nginx

```shell
#1、搜索镜像
#2、下载镜像	pull
#3、运行测试
docker run -d --name nginx01 -p 3344:80 nginx
# -d	后台运行
# --name	给容器命名
# -p	宿主机端口：容器内部储口
```

---



### commit镜像

---

```shell
docker commit 提交容器成为一个副本

#命令和git原理类似
docker commit -m=“提交的描述信息” -a=“作者” 容器id 目标镜像名，[TAG]

docker commit -a="zr" -m="add webapps" bcc57c8214e9 tomcat02:1.0
```

``如果你想要保存当前容器的状态，就可以通过commit:来提交，获得一个镜像,相当于linux的快照``



### 容器数据卷

---

 **总结一句话：容器的持久化和同步操作！容器间也是可以数据共享的！**



#### 使用数据卷

---

> 方式一：直接使用命令来挂载  -v

```shell
docker run -it -v /home/cesh:/home centos /bin/bash

-v  本机目录:容器里的目录
```

每次启动时都要输入-v来挂载文件，不然docker关闭后文件也会消失

**好处：**我们以后修改只需要在本地修改即可，容器内会自动同步！



### 实战：安装Mysql

MYSQL的数据持久化的问题！

```shell
#获取镜像
docker pull mysql:lasted

#运行容器，需要做数据挂载！#安装启动mysq1,需要配置密码的，这是要注意点！
#官方测试：docker run --name some-mysq1    -e MYSQL_RO0T_PASSWORD=my-secret-pw -d mysql:tag

#启动
-d 后台运行
-p 端口映射
-V 卷挂载
-e 环境配置
-name 容器名字
# docker run -d -p 3310:3306 -v /home/mysql/conf:/etc/mysql/conf.d -v /home/mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --name mysql01 mysql
```



### 具名和匿名挂载

```shell
# 匿名挂载
-V 容器内路径！
docker run -d-p --name nginx01-v/ect/nginx nginx
#查看所有的vo1ume的情况
# docker volume 1s
local           9f38292179faa178afcce54d80be99d4ddd68c91d2a68870bcece72d2b7ed061

# 这里发现，这种就是匿名挂载，我们在-V只写了容器内的路径，没有写容器外的路径！

# 具名挂载
# docker run -d-p --name nginx02 -v juming-nginx:/etc/nginx nginx

# docker volume ls
DRIVER		VOLUME NAME
local		juming-nginx
# 通过-V	   卷名：容器内路径
```

所有的docker容器内的卷，没有指定目录的情况下都是在
/var/lib/docker/volumes/xxxx/_data



我们通过具名挂载可以方便的找到我们的一个卷，大多数情况在使用的`具名挂载`

```shell
#如何确定是具名挂载还是匿名挂载，还是指定路径挂载！
-V 容器内路径	 	  #匿名挂载
-V 卷名：容器内路径		#具名挂载
-v /宿主机路径:/容器内路径	#指定路径挂载！
```

```shell
#通过 -v 容器内路径：ro rw改变读写权限
ro readOnly
rw readWrite

#一旦设置了容器权限，容器对我们挂载出的内容就有限定了！
docker run -d -P --name nginx02 -v juming-nginx:/etc/nginx:ro nginx
docker run -d -P --name nginx02 -v juming-nginx:/etc/nginx:rw nginx

# ro 只能通过宿主机进行操作，容器内无法操作！
```

