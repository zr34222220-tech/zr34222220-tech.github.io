---
title: "文件查找、打包压缩与软件安装"
weight: 6
---

---

> 💡 本部分解决三个核心问题：
>  **文件在哪？怎么打包？软件怎么装？**

------

## 一、文件查找

### 1. which —— 查找命令位置

```
which ls
```

作用：

- 查找命令所在路径
- 只针对 **命令**

------

### 2. locate —— 快速文件查找

```
locate 文件名
```

说明：

- 依赖数据库
- 第一次使用前需更新数据库：

```
updatedb
```

------

### 3. find —— 强大的文件查找（重点）

基本语法：

```
find 路径 选项 条件 动作
```

------

#### （1）按文件名查找

```
find /etc -name "11.txt"
find /etc -iname "hosts"
```

说明：

- `-name`：区分大小写
- `-iname`：忽略大小写

------

#### （2）按文件大小查找

```
find /etc -size +5M
```

说明：

- `+5M`：大于 5M
- `-5M`：小于 5M
- `5M`：等于 5M

------

#### （3）按目录深度查找

```
find / -maxdepth 3 -a -name "ifcfg-en*"
```

说明：

- `-maxdepth`：最大目录深度
- `-a`：逻辑与（AND）

------

#### （4）按属主 / 属组查找

```
find /home -user jack
find /home -group hr
```

------

#### （5）按文件类型查找

```
find /dev -type f
```

------

#### （6）按权限查找

```
find . -perm 644 -ls
```

删除查找到的文件：

```
find . -perm 644 -delete
```

------

#### （7）find + 动作（高级用法）

```
find /etc -name "ifcfg*" -ok cp -rvf {} /tmp \;
```

说明：

- `{}`：表示前面查找到的文件
- `\;`：结束符

------

## 二、打包与压缩

### 1. tar 基本格式

```
tar 选项 压缩包名 源文件
```

------

### 2. 常用打包命令

#### 仅打包（不压缩）

```
tar -cf etc.tar /etc
```

------

#### gzip 压缩

```
tar -czf etc-gzip.tar.gz /etc
```

参数说明：

- `c`：create
- `z`：gzip 压缩
- `f`：指定文件

------

### 3. 解压缩

```
tar xf 111
```

解压到指定目录：

```
tar -xvf etc2.tar.bz2 -C /tmp
```

------

## 三、软件安装

## 1. yum 包管理（重点）

### （1）yum 配置目录

```
/etc/yum.repos.d/
```

------

### （2）备份并移除官方 yum 源

```
mv /etc/yum.repos.d/* /tmp
```

------

### （3）配置本地 yum 源（DVD）

```
vim /etc/yum.repos.d/dvd.repo
```

内容示例：

```
[dvd]
name=dvd
baseurl=file:///mnt/cdrom
gpgcheck=0
```

------

### （4）挂载光盘

```
mkdir /mnt/cdrom
mount /dev/cdrom /mnt/cdrom
```

可写入开机自动挂载：

```
vim /root/.bashrc
```

------

### （5）yum 常用命令

```
yum -y install httpd      # 全新安装
yum -y reinstall httpd   # 重新安装
yum -y update httpd      # 升级
yum -y remove httpd      # 卸载
```

------

## 四、rpm 包管理

### 1. 安装 rpm 包

```
rpm -ivh 包名.rpm
```

参数说明：

- `-i`：安装
- `-v`：显示信息
- `-h`：进度条

------

### 2. 查询 rpm 包

```
rpm -q 包名
```

------

### 3. 卸载 rpm 包

```
rpm -evh 包名
```

> ⚠️ 注：
>  rpm **不解决依赖问题**

------

## 五、源码包安装（了解）

```
tar xvf tengine-2.2.0.tar.gz
cd tengine-2.2.0
./configure
make
make install
```

流程说明：

1. 解压
2. 配置
3. 编译
4. 安装