---
title: "用户、组与权限管理"
weight: 3
---

---

## 一、用户相关配置文件

### 1. `/etc/passwd` —— 用户信息文件

> 使用 **冒号 : 分隔，共 7 列字段**

示例：

```
root:x:0:0:root:/root:/bin/bash
```

字段说明：

1. **用户名**：登录系统的名字
2. **x**：密码占位符（真实密码不在此）
3. **UID**：用户 ID（身份证号）
4. **GID**：用户的基本组 ID
5. **描述信息**
6. **HOME**：用户家目录
7. **Shell**：登录后使用的命令解释器

> 💡 注：
>
> - UID = 0 → root 用户
> - 普通用户 UID 通常 ≥ 1000

### 2. `/etc/shadow` —— 用户密码文件

- 存放 **加密后的密码**
- 只有 root 可读

------

### 3. `/etc/group` —— 组信息文件

> 四列字段：

```

组名:组密码:GID:组成员
```

### 4. 用户组关系查看

- 查看用户基本组：

```
cat /etc/passwd
```

- 查看用户附加组：

```
cat /etc/group
```

- 综合查看（推荐）：

```
id 用户名
```

------

## 二、用户管理命令

### 1. 创建用户：`useradd`

```
useradd -g 用户组 用户名
```

注：不加-g则默认新增一组，与用户名同名

常用参数：

- `-u`：指定 UID
- `-d`：指定家目录
- `-g`：指定组名

示例：

```
useradd -u 2001 -d /home/test test
useradd -g wudang zwj
```

------

### 2. 查询用户信息

```
id 用户名
```

------

### 3. 设置 / 修改密码

```
passwd 用户名
```

------

### 4. 删除用户

```
userdel 用户名
```

删除用户并同时删除家目录：

```
userdel -r 用户名
```

## 三、组管理

### 1. 添加组

```
groupadd 组名
```

示例：

```
groupadd net01 -g 2000
```

说明：

- 组名只能由 **字母和数字** 组成
- `-g`：指定 GID（组 ID）

------

### 2.修改用户组

```usermod  -g  用户组  用户名 ``` 

### 3. 查询组信息

```
grep hr /etc/group
```

### 4. 组相关参数说明

- `-g`：指定 **基本组**
- `-G`：指定 **附加组**

> 💡 注：
>
> - 基本组：用户创建文件默认所属组
> - 附加组：额外权限来源

------

### 5. 删除组

```
groupdel net01
```

------

### 6. 移除组成员

```
gpasswd -d AAA BBB
```

含义：

- 将用户 **AAA** 从 **BBB** 组中移除

## 四、提权（权限提升）

### 1. 使用 `su` 切换 root（永久提权）

```
su - root
```

说明：

- 需要 **root 密码**
- 切换后拥有完整 root 权限

------

### 2. 使用 `sudo` 临时提权（推荐）

```
sudo -i
```

说明：

- 输入 **当前用户密码**
- 临时获得 root 权限

------

### 3. sudo 配置文件

```
vim /etc/sudoers
```

常见配置：

```
%wheel  ALL=(ALL)  ALL
```

说明：

- `wheel` 组内用户可以使用 `sudo`

## 五、文件权限模型（重点）

### 1. 三类对象

- `u`：属主（user）
- `g`：属组（group）
- `o`：其他人（other）
- `a`：所有人（u + g + o）

------

### 2. 三种权限

| 权限 | 含义 | 数值 |
| ---- | ---- | ---- |
| r    | 读   | 4    |
| w    | 写   | 2    |
| x    | 执行 | 1    |

示例：

- `7 = 4 + 2 + 1` → 读 + 写 + 执行

------

### 3. chmod —— 修改权限

```

chmod u+w file
chmod a=rx file
chmod o= file
```

## 六、属主与属组

### 1. 修改属主和属组：`chown`

```
chown user:group 文件
```

示例：

```
chown user01.hr /tmp/file1.txt
```

递归修改：

```
chown -R user01.hr /tmp/dir1/
```

------

### 2. 修改属组：`chgrp`

```
chgrp hr /tmp/file1.txt
```

------

## 七、ACL 扩展权限（了解 + 实用）

### 1. 设置 ACL 权限

```
setfacl -m u:alice:rw /home/test.txt
```

设置其他人权限：

```
setfacl -m o::rw /home/test.txt
```

------

### 2. 查看 ACL 权限

```
getfacl 文件
```

> 💡 注：`ls -l` 出现 `+` 号，说明存在 ACL

------

### 3. 删除 ACL 权限

```
setfacl -x u:alice /home/test.txt
```

删除所有扩展权限：

```
setfacl -b 文件
```

------

## 八、特殊权限与文件属性

### 1. SUID

```
chmod u+s 文件
```

作用：

- 运行文件时，临时具备 **属主权限**

------

### 2. 文件属性：`chattr`

```

chattr +i file1   # 锁定文件，不能删除
chattr -i file1   # 解锁
chattr +a file1   # 只允许追加
```

> ⚠️ 注：
>  `+i` 对 root 也生效