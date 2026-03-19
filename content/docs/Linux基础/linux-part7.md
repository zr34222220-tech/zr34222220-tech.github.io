---
title: "计划任务、日志与网络管理"
weight: 7
---

---

> 💡 本部分解决三个问题：
>  **任务怎么自动跑？系统出了问题看哪？网络怎么配？**

------

## 一、计划任务（Task Schedule）

## 1. at —— 一次性任务

```
at now+1min
```

说明：

- 执行一次
- 适合临时任务

------

## 2. cron —— 周期性任务（重点）

### （1）创建计划任务

```
crontab -e
```

基本格式：

```
* * * * * command
```

含义（从左到右）：

```
分  时  日  月  周
```

------

### （2）常见时间表达式（原笔记保留）

```
*/5 * * * *     每 5 分钟执行一次
* 5 * * *       无实际意义
```

```
0 2 1,4,6 * *   每月 1、4、6 日 2 点
0 2 5-9 * *     每月 5～9 日 2 点
* * * * *       每分钟执行
0 * * * *       整点执行
0 2 * * *       每天 2 点
0 2 14 * *      每月 14 日 2 点
0 2 * * 5       每周五 2 点
```

> 💡 注：
>  不写“月、日”，仅写“周”，按周生效

------

### （3）查看与删除任务

```
crontab -l
crontab -r
```

管理员可管理其他用户：

```
crontab -u 用户名 -e
```

------

## 二、日志管理（Log）

### 1. 查看系统日志

```
tail -10 /var/log/messages
tail -f /var/log/messages
```

说明：

- `-f`：实时查看日志（锁定）

------

### 2. rsyslog 服务

```
rpm -qc rsyslog
```

说明：

- `-c`：查看配置文件

主配置文件：

```
/etc/rsyslog.conf
```

------

### 3. rsyslog 日志规则

```
authpriv.*    /var/log/secure
```

说明：

- **facility**：设备
- **level**：级别
- **file**：存放位置

> 💡 注：
>  rsyslog 是一个 **进程 / 程序**，负责日志收集

------

## 三、日志轮转（logrotate）

### 1. 全局配置文件

```
/etc/logrotate.conf
```

常见配置项：

```
weekly        # 每周轮转
rotate 4      # 保留 4 份
create        # 轮转后创建新文件
dateext       # 使用日期作为后缀
#compress     # 压缩（注释表示关闭）
missingok     # 日志不存在不报错
```

------

### 2. 子配置目录

```
/etc/logrotate.d/
```

示例（局部设置）：

```
/var/log/wtmp {
    minsize 1M
    create 0664 root utmp
    rotate 1
}
```

说明：

- `wtmp`：用户登录日志
- 可为单个日志文件单独设置规则

------

## 四、网络管理

## 1. 网络管理

```
systemctl status NetworkManager
```

------

## 2. nmcli（推荐）

网卡配置文件目录：

```
/etc/NetworkManager/system-connections/
```

关键参数说明：

```
ONBOOT=yes        是否开机启用
BOOTPROTO=dhcp   自动获取
BOOTPROTO=none   手动
BOOTPROTO=static 静态
```

------

### 新版写法

```
ipv4.method manual
ipv4.addresses 192.168.64.100/24
ipv4.gateway 192.168.64.2
ipv4.dns 114.114.114.114;8.8.8.8
connection.autoconnect yes
```

------

## 3. 主机名管理

查看主机名：

```
hostname
```

修改主机名：

```
hostnamectl set-hostname xxxxxx
```

配置文件：

```
cat /etc/hostname
```

重启系统：

```
reboot
```

------

## 4. 网络测试命令

```
ip a
ip route
ss -tnl
```

说明：

- `ip a`：查看 IP
- `ip route`：查看路由 / 网关
- `ss -tnl`：查看监听端口