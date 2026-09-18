#!/usr/bin/env bash
# ============================================================
# 芊芯教育官网 · 阿里云 ECS 一键部署脚本
# 服务器：39.96.213.249（Alibaba Cloud Linux 3）
# 域名：qianxinedu.cn / www.qianxinedu.cn
# 用法：sudo bash deploy.sh
# 重复执行也安全（会重新拉取最新代码并重载 Nginx）
# ============================================================
set -e

REPO="zhai117/wangwenjia-workbench"
WEBROOT="/var/www/wangwenjia"
CONF="/etc/nginx/conf.d/qianxinedu.conf"

echo ""
echo "=================================================="
echo " 芊芯教育官网部署开始"
echo "=================================================="

echo "==> 1/6 安装 Nginx / Git"
if command -v dnf >/dev/null 2>&1; then
  dnf install -y nginx git curl >/dev/null
else
  yum install -y nginx git curl >/dev/null
fi
echo "    完成"

echo "==> 2/6 拉取网站代码到 $WEBROOT"
rm -rf "$WEBROOT"
mkdir -p /var/www
OK=0
for U in \
  "https://github.com/${REPO}.git" \
  "https://ghfast.top/https://github.com/${REPO}.git" \
  "https://gh-proxy.com/https://github.com/${REPO}.git" \
  "https://ghproxy.net/https://github.com/${REPO}.git" ; do
  echo "    尝试：$U"
  if git clone --depth 1 "$U" "$WEBROOT" >/dev/null 2>&1; then OK=1; break; fi
  rm -rf "$WEBROOT"
done
if [ "$OK" != "1" ]; then
  echo "    !! 代码拉取失败：服务器连不上 GitHub。"
  echo "    请把这一行截图发给翟老师处理。"
  exit 1
fi
echo "    完成，文件数：$(find "$WEBROOT" -type f | wc -l)"

echo "==> 3/6 写 Nginx 配置 $CONF"
cat > "$CONF" <<'NGINXCONF'
server {
    listen 80;
    server_name www.qianxinedu.cn qianxinedu.cn 39.96.213.249;

    root /var/www/wangwenjia;
    index index.html;
    charset utf-8;

    gzip on;
    gzip_min_length 1k;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/qianxinedu.access.log;
    error_log  /var/log/nginx/qianxinedu.error.log;
}
NGINXCONF
echo "    完成"

echo "==> 4/6 启动 Nginx 并设为开机自启"
systemctl enable --now nginx >/dev/null 2>&1
echo "    完成"

echo "==> 5/6 检查配置并重载"
nginx -t
systemctl reload nginx
echo "    完成"

echo "==> 6/6 本机自检"
C1=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/ || echo "000")
C2=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/app/yinsichen/ || echo "000")
C3=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/app/wangwenjia/ || echo "000")
echo "    官网首页           HTTP $C1"
echo "    尹思辰保研工作台   HTTP $C2"
echo "    王文佳学员规划台   HTTP $C3"

echo ""
echo "=================================================="
echo " 部署完成"
echo "--------------------------------------------------"
echo " 服务器自测地址：http://39.96.213.249/"
echo " 域名地址（解析生效后）：http://www.qianxinedu.cn/"
echo "--------------------------------------------------"
echo " 以后网站内容有更新，只需在服务器执行："
echo "   cd /var/www/wangwenjia && sudo git pull"
echo "=================================================="
echo ""
