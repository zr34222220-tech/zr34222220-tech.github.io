---

title: "Nginx常用配置"
weight: 60
date: 2025-12-15
draft: false

---

1. 全局性能调优模块

这些参数通常全行业通用，配一次管一辈子，不需要背。

```nginx
基础运行参数：
user nginx;
worker_processes auto; 
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
events {
    worker_connections 1024;
    use epoll;
}
静态资源加速与压缩 (Gzip)：

sendfile on;
tcp_nopush on;
tcp_nodelay on;
keepalive_timeout 65;

gzip on;
gzip_vary on;
gzip_min_length 1k;
gzip_comp_level 6;
gzip_types text/plain text/css text/javascript application/json application/javascript application/x-javascript text/xml application/xml+rss+xml;
```

2. 安全与 HTTPS 固定套件 

这一长串加密算法和协议组合，连 10 年经验的架构师也不会去背它。

```nginx
SSL 安全参数：

ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

强制跳转 HTTPS (Rewrite)：
Nginx

rewrite ^(.*)$ https://$host$1 permanent;
```

3. 跨域通行证 (CORS)

这段代码解决浏览器报错，直接复制到 location 块中即可。
```Nginx
add_header Access-Control-Allow-Origin *;
add_header Access-Control-Allow-Methods GET,POST,PUT,DELETE,OPTIONS;
add_header Access-Control-Allow-Headers Content-Type,Authorization;
if ($request_method = OPTIONS) {
    return 204;
}
```

4. 反向代理

只要用 proxy_pass，就必须带上这几行，防止后端服务器变“瞎”。

```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

5. 常见功能代码块

    前端 History 模式适配：
    ```Nginx
    location / {
        try_files $uri $uri/ /index.html;
    }
    ```

    防盗链配置：
    ```Nginx
    valid_referers none blocked server_names *.nginx-demo.com;
    if ($invalid_referer) {
        return 403;
    }
    ```

    缓存定义路径：
    ```Nginx
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:100m max_size=10g inactive=7d use_temp_path=off;
    ```
    
    
    
    
