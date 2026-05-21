---
title: "mysql多实例部署"
weight: 30
date: 2025-12-15
draft: false


---

# MySQL 多实例部署：独立 systemd 服务

> 适用系统：OpenCloudOS 8 / 9（及 RHEL/CentOS 8+ 系列）
> MySQL 版本：8.0+
> 部署目标：在同一台服务器上运行 3 个独立 MySQL 实例（端口 3306 / 3307 / 3308）

---

## 目录

1. [方案原理](#1-方案原理)
2. [环境准备](#2-环境准备)
3. [目录规划](#3-目录规划)
4. [编写各实例配置文件](#4-编写各实例配置文件)
5. [创建 systemd 模板服务](#5-创建-systemd-模板服务)
6. [初始化数据目录](#6-初始化数据目录)
7. [启动实例并修改密码](#7-启动实例并修改密码)
8. [日常管理命令](#8-日常管理命令)
9. [注意事项与最佳实践](#9-注意事项与最佳实践)

---

## 1. 方案原理

核心思路是：**共用同一套 MySQL 二进制文件，每个实例拥有独立的数据目录、配置文件、端口和 socket。**

systemd 提供了「模板服务」机制，文件名中的 `@` 符号后面留空，启动时通过 `mysqld@3306` 这样的方式将端口号传入，服务文件内部用 `%i` 占位符接收。因此只需维护**一个** `.service` 文件，三个实例即可共用，差异全部收敛到各自的 `my.cnf` 中。

相比 `mysqld_multi`，systemd 方案的优势：

- 崩溃后自动重启（`Restart=on-failure`）
- 日志统一写入 journald，可用 `journalctl` 集中查询
- 每个实例天然处于独立 cgroup，支持资源限制
- 与系统服务管理体系完全一致，运维更规范

---

## 2. 环境准备

### 2.1 安装 MySQL

若尚未安装，参考以下步骤（使用清华镜像源）：

```bash
# 配置 MySQL 8.0 YUM 源
cat > /etc/yum.repos.d/mysql-community.repo << 'EOF'
[mysql80-community]
name=MySQL 8.0 Community Server
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-8.0-community-el9-x86_64/
enabled=1
gpgcheck=0

[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-connectors-community-el9-x86_64/
enabled=1
gpgcheck=0
EOF

# 安装
dnf clean all
dnf install -y mysql-community-server
```

### 2.2 确认二进制路径

```bash
which mysqld
# 预期输出：/usr/sbin/mysqld 或 /usr/local/mysql/bin/mysqld

mysqld --version
# 预期输出：/usr/sbin/mysqld  Ver 8.0.x ...
```

> **注意**：后续配置文件中的 `ExecStart` 路径需与实际路径一致。

---

## 3. 目录规划

每个实例拥有独立的数据目录和日志目录，结构如下：

```
/data/mysql/
├── 3306/
│   ├── data/          # 实例 1 数据目录
│   ├── logs/          # error / slow / binlog
│   └── my.cnf         # 实例 1 专属配置
├── 3307/
│   ├── data/
│   ├── logs/
│   └── my.cnf
└── 3308/
    ├── data/
    ├── logs/
    └── my.cnf
```

一键创建所有目录并设置权限：

```bash
mkdir -p /data/mysql/{3306,3307,3308}/{data,logs}
chown -R mysql:mysql /data/mysql
chmod 750 /data/mysql
```

---

## 4. 编写各实例配置文件

### 4.1 实例 1（端口 3306）

```bash
cat > /data/mysql/3306/my.cnf << 'EOF'
[client]
port            = 3306
socket          = /tmp/mysql_3306.sock
default-character-set = utf8mb4

[mysqld]
# ── 基础 ──────────────────────────────────
user            = mysql
port            = 3306
socket          = /tmp/mysql_3306.sock
basedir         = /usr
datadir         = /data/mysql/3306/data
pid-file        = /data/mysql/3306/mysql.pid
bind-address    = 0.0.0.0

# ── 字符集 ────────────────────────────────
character-set-server        = utf8mb4
collation-server            = utf8mb4_unicode_ci

# ── 主从复制标识（全局唯一）────────────────
server-id       = 1

# ── 日志 ──────────────────────────────────
log_error               = /data/mysql/3306/logs/error.log
slow_query_log          = 1
slow_query_log_file     = /data/mysql/3306/logs/slow.log
long_query_time         = 1
log_bin                 = /data/mysql/3306/logs/binlog
binlog_format           = ROW
binlog_expire_logs_seconds = 604800

# ── 内存（按实际物理内存调整）──────────────
innodb_buffer_pool_size = 4G
innodb_buffer_pool_instances = 4
max_connections         = 300
EOF
```

### 4.2 实例 2（端口 3307）

```bash
cat > /data/mysql/3307/my.cnf << 'EOF'
[client]
port            = 3307
socket          = /tmp/mysql_3307.sock
default-character-set = utf8mb4

[mysqld]
user            = mysql
port            = 3307
socket          = /tmp/mysql_3307.sock
basedir         = /usr
datadir         = /data/mysql/3307/data
pid-file        = /data/mysql/3307/mysql.pid
bind-address    = 0.0.0.0

character-set-server        = utf8mb4
collation-server            = utf8mb4_unicode_ci

server-id       = 2

log_error               = /data/mysql/3307/logs/error.log
slow_query_log          = 1
slow_query_log_file     = /data/mysql/3307/logs/slow.log
long_query_time         = 1
log_bin                 = /data/mysql/3307/logs/binlog
binlog_format           = ROW
binlog_expire_logs_seconds = 604800

innodb_buffer_pool_size = 2G
innodb_buffer_pool_instances = 2
max_connections         = 200
EOF
```

### 4.3 实例 3（端口 3308）

```bash
cat > /data/mysql/3308/my.cnf << 'EOF'
[client]
port            = 3308
socket          = /tmp/mysql_3308.sock
default-character-set = utf8mb4

[mysqld]
user            = mysql
port            = 3308
socket          = /tmp/mysql_3308.sock
basedir         = /usr
datadir         = /data/mysql/3308/data
pid-file        = /data/mysql/3308/mysql.pid
bind-address    = 0.0.0.0

character-set-server        = utf8mb4
collation-server            = utf8mb4_unicode_ci

server-id       = 3

log_error               = /data/mysql/3308/logs/error.log
slow_query_log          = 1
slow_query_log_file     = /data/mysql/3308/logs/slow.log
long_query_time         = 1
log_bin                 = /data/mysql/3308/logs/binlog
binlog_format           = ROW
binlog_expire_logs_seconds = 604800

innodb_buffer_pool_size = 1G
innodb_buffer_pool_instances = 1
max_connections         = 100
EOF
```

> **各实例必须不同的配置项**：`port`、`socket`、`datadir`、`pid-file`、`server-id`，以及所有日志路径。

---

## 5. 创建 systemd 模板服务

创建模板服务文件，文件名中的 `@` 是关键：

```bash
cat > /etc/systemd/system/mysqld@.service << 'EOF'
[Unit]
Description=MySQL Instance %i
After=network.target
After=syslog.target

[Service]
User=mysql
Group=mysql

# %i 在运行时自动替换为实例端口号（如 3306）（这里要按照实际情况，其他全部复制！！！！）
ExecStart=/usr/sbin/mysqld \
    --defaults-file=/data/mysql/%i/my.cnf

ExecStop=/usr/bin/mysqladmin \
    --defaults-file=/data/mysql/%i/my.cnf \
    -u root shutdown

# 崩溃后自动重启
Restart=on-failure
RestartSec=5s

# 文件描述符限制
LimitNOFILE=65535

# 启动超时
TimeoutStartSec=120
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF
```

重载 systemd 使配置生效：

```bash
systemctl daemon-reload
```

---

## 6. 初始化数据目录

每个实例需要单独初始化，`--initialize` 会在日志中生成一个临时 root 密码：

```bash
# 初始化实例 1
/usr/sbin/mysqld \
--defaults-file=/data/mysql/3306/my.cnf \
--initialize \
--user=mysql

# 初始化实例 2
/usr/sbin/mysqld \
--defaults-file=/data/mysql/3307/my.cnf \
--initialize \
--user=mysql

# 初始化实例 3
/usr/sbin/mysqld \
--defaults-file=/data/mysql/3308/my.cnf \
--initialize \
--user=mysql
```

初始化完成后，从各实例的错误日志中获取临时密码：

```bash
grep 'temporary password' /data/mysql/3306/logs/error.log
grep 'temporary password' /data/mysql/3307/logs/error.log
grep 'temporary password' /data/mysql/3308/logs/error.log
```

输出示例：

```
2024-01-01T10:00:00.000000Z 6 [Note] [MY-010454] A temporary password is generated for root@localhost: Abcd1234!xyz
```

将三个临时密码记录下来，启动后立即修改。

---

## 7. 启动实例并修改密码

### 7.1 启动所有实例

```bash
systemctl start mysqld@3306
systemctl start mysqld@3307
systemctl start mysqld@3308
```

### 7.2 设置开机自启

```bash
systemctl enable mysqld@3306
systemctl enable mysqld@3307
systemctl enable mysqld@3308
```

### 7.3 确认运行状态

```bash
systemctl status mysqld@3306
systemctl status mysqld@3307
systemctl status mysqld@3308

# 或一条命令查看全部
systemctl list-units 'mysqld@*'
```

### 7.4 修改各实例 root 密码

通过 socket 文件连接各实例（推荐，避免端口混淆）：

```bash
# 修改实例 1 密码
mysql -u root -p'<实例1临时密码>' \
    -S /tmp/mysql_3306.sock \
    --connect-expired-password \
    -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourNewPass3306!';"

# 修改实例 2 密码
mysql -u root -p'<实例2临时密码>' \
    -S /tmp/mysql_3307.sock \
    --connect-expired-password \
    -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourNewPass3307!';"

# 修改实例 3 密码
mysql -u root -p'<实例3临时密码>' \
    -S /tmp/mysql_3308.sock \
    --connect-expired-password \
    -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourNewPass3308!';"
    
    
mysql -u root -p'joL(qH%27m>H' \
    -S /tmp/mysql_3306.sock \
    --connect-expired-password \
    -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';"
```

### 7.5 安全加固（可选但推荐）

```bash
# 以实例 1 为例，删除匿名用户和 test 库
mysql -u root -p'YourNewPass3306!' -S /tmp/mysql_3306.sock << 'SQL'
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL
```

---

## 8. 日常管理命令

### 连接实例

```bash
# 通过 socket 连接（推荐）
mysql -u root -p -S /tmp/mysql_3306.sock
mysql -u root -p -S /tmp/mysql_3307.sock
mysql -u root -p -S /tmp/mysql_3308.sock

# 通过端口连接
mysql -u root -p -h 127.0.0.1 -P 3306
mysql -u root -p -h 127.0.0.1 -P 3307
mysql -u root -p -h 127.0.0.1 -P 3308
```

### 服务控制

```bash
# 启动 / 停止 / 重启单个实例
systemctl start   mysqld@3306
systemctl stop    mysqld@3307
systemctl restart mysqld@3308

# 查看运行状态
systemctl status mysqld@3306

# 查看所有 MySQL 实例
systemctl list-units 'mysqld@*'
```

### 日志查看

```bash
# 通过 journalctl 查看（实时）
journalctl -u mysqld@3306 -f
journalctl -u mysqld@3307 -f

# 查看错误日志文件
tail -f /data/mysql/3306/logs/error.log

# 查看慢查询日志
tail -f /data/mysql/3306/logs/slow.log
```

### 备份单个实例

```bash
# 使用 mysqldump 备份实例 1
mysqldump -u root -p \
    -S /tmp/mysql_3306.sock \
    --single-transaction \
    --routines --triggers \
    --all-databases \
    | gzip > /backup/mysql_3306_$(date +%Y%m%d).sql.gz
```

---

## 9. 注意事项与最佳实践

### 9.1 各实例必须唯一的配置项

| 配置项 | 说明 |
|--------|------|
| `port` | 端口号，不可重复 |
| `socket` | socket 文件路径，不可重复 |
| `datadir` | 数据目录，完全隔离 |
| `pid-file` | PID 文件路径，不可重复 |
| `server-id` | 参与主从复制时全局唯一，不可为 0 |
| `log_error` / `log_bin` | 各自独立的日志路径 |

### 9.2 内存规划原则

所有实例的 `innodb_buffer_pool_size` 之和不应超过物理内存的 **70%**，否则可能触发 OOM，导致实例被系统强制杀掉。

建议按以下比例分配（以 16G 内存为例）：

| 实例 | buffer_pool | 说明 |
|------|-------------|------|
| 3306（主业务） | 6G | 约 37% |
| 3307（只读从库） | 3G | 约 19% |
| 3308（测试） | 1G | 约 6% |
| 系统 + OS 缓存 | 6G | 保留 38% |

### 9.3 防火墙配置

若实例需要对外提供服务，记得放行对应端口：

```bash
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --permanent --add-port=3307/tcp
firewall-cmd --permanent --add-port=3308/tcp
firewall-cmd --reload
```

### 9.4 mysqld 路径差异

不同安装方式的 `mysqld` 路径可能不同：

| 安装方式 | mysqld 路径 |
|----------|-------------|
| YUM/DNF 安装 | `/usr/sbin/mysqld` |
| 二进制包解压 | `/usr/local/mysql/bin/mysqld` |
| 编译安装 | `/usr/local/mysql/bin/mysqld` |

修改 `mysqld@.service` 中的 `ExecStart` 路径以匹配实际环境。
