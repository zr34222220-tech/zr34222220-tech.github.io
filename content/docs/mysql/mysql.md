---

title: "mysql"
weight: 10
date: 2025-12-15
draft: false

---

# MySQL 

## 1. 安装 MySQL
```bash
# Windows（Chocolatey）
choco install -y mysql

# Linux（CentOS/RHEL）
yum install mysql-server

# Docker 拉取镜像
docker pull mysql
```

## 2. 连接与进入数据库
```sql
USE game;
```
作用：切换到 `game` 数据库，后续建表和查询都在这个库里执行。

## 3. 建表与基础数据操作（CRUD）
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

## 4. 表结构修改（DDL）
```sql
DESC player;

ALTER TABLE player MODIFY level INT DEFAULT 1;
ALTER TABLE player MODIFY COLUMN name VARCHAR(200);
ALTER TABLE player CHANGE COLUMN name nick_name VARCHAR(200);

ALTER TABLE player ADD COLUMN last_login DATETIME;
ALTER TABLE player DROP COLUMN last_login;

DROP TABLE player;
```

## 5. 条件查询与排序
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

## 6. 聚合与分组统计
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

## 7. 子查询与结果复用
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

## 8. 连接查询（JOIN）
```sql
-- 常见类型：INNER JOIN / LEFT JOIN / RIGHT JOIN

SELECT * FROM player
RIGHT JOIN skill ON player.id=skill.id;

-- 旧写法（等价于内连接）
SELECT * FROM player p, equip e
WHERE p.id=e.id;
```

## 9. 索引
```sql
CREATE INDEX id_index ON player(id);
SHOW INDEX FROM player;
DROP INDEX id_index ON player;
```

## 10. 视图
```sql
CREATE VIEW top10 AS
SELECT * FROM player ORDER BY level DESC LIMIT 10;

SELECT * FROM top10;

DROP VIEW top10;
```

## 11. 完整命令
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

## 12.权限管理

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



## 13.数据备份与恢复

**逻辑备份工具-mysqldump**

* 使用mysqldump可以导出数据库结构
  和数据，生成SQL语句，便于数据迁
  移和备份。
