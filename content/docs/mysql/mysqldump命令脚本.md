---
title: "mysqldump"
weight: 20
date: 2025-12-15
draft: false
---

## mysqldump 生产环境实用命令

### 基础备份

```bash
# 备份单个数据库
mysqldump -u root -p dbname > backup.sql

# 备份多个数据库
mysqldump -u root -p --databases db1 db2 db3 > backup.sql

# 备份所有数据库
mysqldump -u root -p --all-databases > all_backup.sql

# 备份单张表
mysqldump -u root -p dbname tablename > table_backup.sql
```

### 生产环境推荐参数

```bash
# InnoDB 热备（不锁表，生产最常用）
mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --hex-blob \
  dbname > backup.sql

# MyISAM 表备份（需要锁表）
mysqldump -u root -p \
  --lock-tables \
  --flush-logs \
  dbname > backup.sql
```

关键参数说明：

| 参数                   | 作用                        |
| ---------------------- | --------------------------- |
| `--single-transaction` | 开启事务快照，InnoDB 不锁表 |
| `--events`             | 备份定时任务（事件调度器）  |
| `--flush-logs`         | 备份前刷新 binlog           |
| `--routines`           | 备份存储过程和函数          |
| `--triggers`           | 备份触发器                  |
| `--hex-blob`           | BLOB 字段用十六进制，防乱码 |

### 压缩备份（节省磁盘）

```bash
# 直接压缩输出
mysqldump -u root -p --single-transaction dbname | gzip > backup_$(date +%F).sql.gz

# 恢复压缩备份
gunzip < backup_2025-01-01.sql.gz | mysql -u root -p dbname
```

### 主从复制场景

```bash
# 主库备份 + 记录 binlog 位点
mysqldump -u root -p \
  --single-transaction \
  --master-data=2 \
  --flush-logs \
  --all-databases > master_backup.sql

# 查看位点（备份文件头部注释中）
head -30 master_backup.sql | grep "MASTER_LOG"
```

### 仅结构 / 仅数据

```bash
# 仅导出表结构（不含数据）
mysqldump -u root -p --no-data dbname > schema.sql

# 仅导出数据（不含建表语句）
mysqldump -u root -p --no-create-info dbname > data.sql

# 忽略特定表
mysqldump -u root -p dbname \
  --ignore-table=dbname.logs \
  --ignore-table=dbname.tmp > backup.sql
```

### 定时自动备份脚本

```bash
#!/bin/bash
BACKUP_DIR="/data/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
DB="production_db"
USER="backup_user"
PASS="yourpassword"

mkdir -p $BACKUP_DIR

mysqldump -u$USER -p$PASS \
  --single-transaction \
  --routines --triggers \
  $DB | gzip > $BACKUP_DIR/${DB}_${DATE}.sql.gz

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "备份完成: ${DB}_${DATE}.sql.gz"
```

加入 crontab：

```bash
# 每天凌晨 2 点执行
0 2 * * * /bin/bash /scripts/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1
```

### 恢复操作

```bash
# 恢复到指定数据库
mysql -u root -p dbname < backup.sql

# 恢复时忽略错误继续执行
mysql -u root -p --force dbname < backup.sql

# 远程恢复
mysql -h remote_host -u root -p dbname < backup.sql
```

### 注意事项

- 生产 InnoDB 必用 `--single-transaction`，避免锁表影响业务
- 建议创建专用备份账号，仅授予 `SELECT, LOCK TABLES, SHOW VIEW, TRIGGER, EVENT` 权限
- 大库（>10GB）建议改用 **XtraBackup** 进行物理备份，速度更快
- 备份文件务必异地存储，本机备份意义有限