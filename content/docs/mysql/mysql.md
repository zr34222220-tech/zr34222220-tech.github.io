---

title: "mysql"
weight: 10
date: 2025-12-15
draft: false

---

# MySQL 

详细请看 https://geek-blogs.com/blog/how-to-setup-mysql-on-linux/

### 第一步：彻底清除之前残留的旧源和缓存

为了不让 EL8/EL9 的老配置文件和缓存继续作祟，先执行以下命令：

```bash
# 1. 移除旧的 mysql-release 配置包
sudo dnf remove mysql-release mysql80-community-release -y

# 2. 清理干净所有残留的 repo 文件
sudo rm -f /etc/yum.repos.d/mysql-community*.repo

# 3. 彻底清空 DNF 缓存
sudo dnf clean all && sudo dnf makecache
```



### 第二步：安装 MySQL

```bash
# Windows（Chocolatey）
choco install -y mysql

# Linux（CentOS/RHEL）
yum install mysql-server8.4 -y

# Docker 拉取镜像
docker pull mysql
```



### 第三步：启动并设置开机自启

---

```
sudo systemctl start mysqld
sudo systemctl enable mysqld
```

**查看首次启动的随机临时密码**

```
sudo grep 'temporary password' /var/log/mysqld.log

#8.4版本默认没有密码
```

```sql
sudo mysql -u root  # 无需密码直接登录（Ubuntu/Debian 常见）
mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '你的强密码';
mysql> FLUSH PRIVILEGES;  # 刷新权限
exit  # 退出后重新执行 mysql_secure_installation
```



## 2. 安全加固

#### 2.1 **运行 `mysql_secure_installation` 脚本**

```
sudo mysql_secure_installation
```

流程说明：

1. **验证密码强度插件**：输入 `y` 启用 `validate_password` 插件（推荐），可设置密码强度策略（长度、复杂度）。
2. **设置 root 密码**：若安装时未设置，此处需输入新密码（MySQL 8.0 可能需先通过 `sudo mysql` 登录后修改，见下文补充）。
3. **移除匿名用户**：输入 `y`（匿名用户允许任何人无需密码登录，存在安全隐患）。
4. **禁止 root 远程登录**：输入 `y`（默认仅允许本地登录，如需远程管理需后续手动配置）。
5. **删除 test 数据库**：输入 `y`（默认存在的空数据库，无用且可能被滥用）。
6. **刷新权限表**：输入 `y`（使配置立即生效）。

#### 2.2 常用核心参数优化

不同 Linux 发行版的配置文件路径可能不同：

- **Ubuntu/Debian**：主配置文件 `/etc/mysql/my.cnf`，包含 `!includedir /etc/mysql/conf.d/` 和 `!includedir /etc/mysql/mysql.conf.d/`（推荐在 `conf.d/` 下创建自定义配置文件，如 `my-custom.cnf`）。
- **CentOS/RHEL**：主配置文件 `/etc/my.cnf`，包含 `!includedir /etc/my.cnf.d/`。

建议通过 `mysql --help | grep my.cnf` 查看当前加载的配置文件顺序。



```sql
[mysqld]
# 网络配置
bind-address = 127.0.0.1     # 纯本地访问（需要允许任何 IP 远程访问，请改回 0.0.0.0）
port = 3306

# 编码配置
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 性能优化
max_connections = 1000
innodb_buffer_pool_size = 2G  # 确保你的服务器总内存大于 4G，否则请调小（如 512M）
skip_name_resolve = ON

# 日志配置
slow_query_log = ON
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_error = /var/log/mysql/error.log
```

```sql
sudo systemctl restart mysqld	#重启mysql
```



####  2.3 常用运维查询

```sqlite
-- 建库建表（运维记录用）
CREATE DATABASE ops_db DEFAULT CHARSET utf8mb4;
USE ops_db;
CREATE TABLE t_deploy (
    id INT AUTO_INCREMENT PRIMARY KEY,
    env VARCHAR(20) COMMENT '环境：dev/test/staging/prod',
    version VARCHAR(50) COMMENT '版本号',
    operator VARCHAR(50) COMMENT '操作人',
    status VARCHAR(20) COMMENT 'success/failed/rollback',
    deploy_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE t_server (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(100),
    ip VARCHAR(20),
    role VARCHAR(50) COMMENT '角色：web/db/monitor',
    status VARCHAR(20) DEFAULT 'online'
);

-- 用户权限管理（最小权限原则）
CREATE USER 'appuser'@'192.168.10.%' IDENTIFIED BY 'App@123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ops_db.* TO 'appuser'@'192.168.10.%';
CREATE USER 'readonly'@'%' IDENTIFIED BY 'Read@123';
GRANT SELECT ON ops_db.* TO 'readonly'@'%';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'appuser'@'192.168.10.%';

-- 常用运维查询（每条都要亲手跑一遍，理解输出含义）
SHOW PROCESSLIST;                          -- 查看当前所有连接
SHOW STATUS LIKE 'Threads_connected';      -- 当前连接数
SHOW VARIABLES LIKE 'max_connections';     -- 最大连接数配置
SHOW VARIABLES LIKE 'slow_query%';         -- 慢查询配置
SHOW STATUS LIKE 'Slow_queries';           -- 慢查询累计次数

-- 查看各库占用空间
SELECT table_schema AS '数据库',
       ROUND(SUM(data_length+index_length)/1024/1024, 2) AS '大小(MB)'
FROM information_schema.tables
GROUP BY table_schema ORDER BY 2 DESC;

-- 查看表行数和大小
SELECT table_name, table_rows,
       ROUND(data_length/1024/1024,2) AS 'data_MB',
       ROUND(index_length/1024/1024,2) AS 'index_MB'
FROM information_schema.tables
WHERE table_schema='ops_db';
```



## 3.连接与进入数据库

```sql
mysql -u root -p
USE game;
```
作用：切换到 `game` 数据库，后续建表和查询都在这个库里执行。



## 4. 建表与基础数据操作（CRUD）
```sql
CREATE TABLE player (
  id INT,
  name VARCHAR(100),
  level INT,
  exp INT,
  gold DECIMAL(10,2)
);

INSERT INTO player(id,name,level,exp,gold) VALUES (1,'张三',1,1,1);
INSERT INTO player (id,name) VALUES (2,'李四'),(3,'王五');
INSERT INTO player (id,name) VALUES (4,'赵四');

SELECT * FROM player;

UPDATE player SET level=1 WHERE name='李四';
UPDATE player SET level=1 WHERE name='王五';
UPDATE player SET exp=0,gold=0;

DELETE FROM player WHERE gold=0;
```

## 5. 表结构修改（DDL）
```sql
DESC player;

ALTER TABLE player MODIFY level INT DEFAULT 1;
ALTER TABLE player MODIFY COLUMN name VARCHAR(200);
ALTER TABLE player CHANGE COLUMN name nick_name VARCHAR(200);

ALTER TABLE player ADD COLUMN last_login DATETIME;
ALTER TABLE player DROP COLUMN last_login;

DROP TABLE player;
```

## 6. 条件查询与排序
```sql
SELECT * FROM player WHERE level > 1;
SELECT * FROM player WHERE level > 1 AND level < 5;
SELECT * FROM player WHERE level IN (1,3,5);

SELECT * FROM player WHERE name LIKE '王%';
SELECT * FROM player WHERE name LIKE '王__';

SELECT * FROM player WHERE email REGEXP '^zhangsan';
SELECT * FROM player WHERE email REGEXP '^a|^b|^c';
SELECT * FROM player WHERE email REGEXP 'net$';
SELECT * FROM player WHERE email IS NULL OR email='';
SELECT * FROM player WHERE email IS NOT NULL;

SELECT * FROM player ORDER BY level DESC;
SELECT * FROM player ORDER BY level DESC, exp;
```

## 7. 聚合与分组统计
```sql
SELECT COUNT(*) FROM player;
SELECT AVG(exp) FROM player;

SELECT sex, COUNT(*) FROM player GROUP BY sex;
SELECT level, COUNT(level) FROM player GROUP BY level HAVING COUNT(level) > 4;
SELECT level, COUNT(level) FROM player GROUP BY level HAVING COUNT(level) > 4 ORDER BY COUNT(level) DESC;

SELECT name, COUNT(*) FROM player GROUP BY name HAVING name REGEXP '^.' ORDER BY COUNT(*) DESC;

SELECT SUBSTR(name,1,1), COUNT(SUBSTR(name,1,1))
FROM player
GROUP BY SUBSTR(name,1,1)
HAVING COUNT(SUBSTR(name,1,1)) >= 5
ORDER BY COUNT(SUBSTR(name,1,1)) DESC
LIMIT 2,3;

SELECT DISTINCT sex FROM player;
```

## 8. 子查询与结果复用
```sql
SELECT * FROM player WHERE level > (SELECT AVG(level) FROM player);

SELECT level,
       ROUND((SELECT AVG(level) FROM player)) AS average,
       level - ROUND((SELECT AVG(level) FROM player)) AS diff
FROM player;

CREATE TABLE new_table AS
SELECT * FROM player WHERE level < 5;

INSERT INTO new_table
SELECT * FROM player WHERE level BETWEEN 6 AND 10;

SELECT EXISTS(SELECT * FROM player WHERE level > 10);
```

## 9. 连接查询（JOIN）
```sql
-- 常见类型：INNER JOIN / LEFT JOIN / RIGHT JOIN

SELECT * FROM player
RIGHT JOIN skill ON player.id=skill.id;

-- 旧写法（等价于内连接）
SELECT * FROM player p, equip e
WHERE p.id=e.id;
```

## 10. 索引
```sql
CREATE INDEX id_index ON player(id);
SHOW INDEX FROM player;
DROP INDEX id_index ON player;
```

## 11. 视图
```sql
CREATE VIEW top10 AS
SELECT * FROM player ORDER BY level DESC LIMIT 10;

SELECT * FROM top10;

DROP VIEW top10;
```

## 12. 完整命令
```sql
USE game;

DROP TABLE IF EXISTS player;

CREATE TABLE player (
  id INT PRIMARY KEY,
  name VARCHAR(100),
  sex CHAR(1),
  level INT DEFAULT 1,
  exp INT DEFAULT 0,
  gold DECIMAL(10,2) DEFAULT 0,
  email VARCHAR(100)
);

INSERT INTO player(id,name,sex,level,exp,gold,email) VALUES
(1,'张三','M',1,10,20.00,'zhangsan@abc.net'),
(2,'李四','M',2,50,10.00,'lisi@test.com'),
(3,'王五','M',5,80,30.00,'wangwu@abc.net'),
(4,'赵六','F',3,60,0.00,NULL),
(5,'王小明','M',4,90,45.00,'wxm@site.com');

SELECT * FROM player;

UPDATE player SET level=level+1 WHERE id=1;
DELETE FROM player WHERE gold=0;

SELECT * FROM player WHERE level IN (2,3,4,5);
SELECT * FROM player WHERE name LIKE '王%';
SELECT * FROM player WHERE email REGEXP 'net$';
SELECT * FROM player ORDER BY level DESC, exp DESC;

SELECT COUNT(*) AS total_players FROM player;
SELECT AVG(exp) AS avg_exp FROM player;
SELECT sex, COUNT(*) AS cnt FROM player GROUP BY sex;

CREATE INDEX id_index ON player(id);
SHOW INDEX FROM player;

CREATE OR REPLACE VIEW top10 AS
SELECT * FROM player ORDER BY level DESC LIMIT 10;
SELECT * FROM top10;
```

---

## 13.权限管理

**一.创建用户**
语法：

CREATE USER ‘用户名’ @ ‘主机地址’ IDENTIFIED BY ‘密码’；

**创建本地登录用户**

CREATE USER  ‘dev’ @ ‘localhost’ IDENTIFIED BY ‘P@ssw0rd!’；

**创建远程登录用户（允许任意IP访问)**
注意事项：

* 主机地址可以是1oca1host（仅本地）、%（任意IP）或具体IP（如192.168.1.100）。
* 密码需符合安全策略（8位以上，含大小写字母、数字、符号。 

```sql
#创建账号
CREATE USER 'dev'@'192.168.241.%'      IDENTIFIED BY 'P@SSW0rd!' ;

CREATE USER 'dev'@'127.0.0.1' IDENTIFIED BY 'P@SSW0rd!‘ ;

flush privileges ;		#刷新
```

**二. 授予用户权限**

* 语法格式：
  GRANT 权限列表 ON 数据库 .表 TO ‘用户名' @ '主机地址'；

* 全局权限

  ```sql
  GRANT ALL PRIVILEGES ON \*.* TO 'admin' @ '%' ;                
  #所有数据库和表的所有权限
  ```

* **数据库级权限 (一般做到这个级别)**

  ```sql
  GRANT SELECT, INSERT ON mydb.*  To 'dev' @ 'localhost';
  
  GRANT SELECT,INSERT,UPDATE,DELETE ON 库名.* TO '用户'@'IP';
  ```

* 表级权限

  ```sql
  GRANT UPDATE, DELETE ON mydb.orders To 'user1'@'192.168.1.100';
  ```

* 列级权限

  ```sql
  GRANT SELECT
  (id,name) , UPDATE (price)ON mydb.products  To 'audit '@'%' ; 
  ```

* 常用权限列表：
  SELECT(查询)、INSERT(插入)、UPDATE(更新)、DELETE(删除)、CREATE(创建表)、ALTER(修改表)、DROP(删除表)、INDEX(管理索引)

---

**撤回权限**

```sql
REVOKE ALL PRIVILEGES ON linux.* FROM 'dev'@'192.168.241.%';
REVOKE ALL PRIVILEGES ON linux.* FROM 'dev'@'127.0.0.1';
flush privileges ;		#刷新
```

---

**删除账号**

```sql
DROP USER 'dev'@'192.168.241.%' ;

DROP USER 'dev'@'127.0.0.1' ；
```

---

### 权限总结

1. **最小权限原则**：给够用的，不给多余的
2. **授权级别：库级别 > 表级别 > 全局级别**
3. **普通账号只给单库的 增删改查**
4. **root 不外放，不远程，不写进项目配置**

---



## 14.数据备份与恢复

**逻辑备份工具-mysqldump**

* 使用mysqldump可以导出数据库结构
  和数据，生成SQL语句，便于数据迁
  移和备份。
