## 1. 安装

- ##### online

  ```shell
  version=v2.7.1
  wget -c https://github.com/goharbor/harbor/releases/download/$version/harbor-online-installer-$version.tgz -O - | tar –xz -f - -C online
  ```

- ##### offline

  ```shell
  version=v2.7.1
  wget -c https://github.com/goharbor/harbor/releases/download/$version/harbor-offline-installer-$version.tgz -O - | tar –xz -f - -C offline
  ```

```shell
# 镜像下载
cat images.repo | while read image; do docker pull $image; done
```

```shell
# 修改配置
cp harbor.yml.tmpl harbor.yml

# https
openssl req -nodes -new -x509 -newkey rsa:2048 -keyout harbor.key -out harbor.crt
...
# https related config
https:
  # https port for harbor, default is 443
  port: 8443
  # The path of cert and key files for nginx
  certificate: /data/cert/harbor.crt
  private_key: /data/cert/harbor.key
...

# 生成 https 配置
/bin/bash prepare
```

```shell
# 运行
./install.sh
```

------

## 2. 使用

```shell
# login
docker login 10.0.0.1:5000
username: root
password: xxxxxxxx

# push
docker push 10.0.0.1:5000/library/xxx
```

