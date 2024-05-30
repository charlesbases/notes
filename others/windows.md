## 1. applications

- ##### chrome

  ```shell
  # other version
  https://google-chrome.en.uptodown.com
  ```

  ```shell
  # --incognito
  # 隐身模式启动

  # --ignore-certificate-errors
  # 忽略证书错误

  # --disable-background-networking
  # 禁用版本检查
  ```

- ##### docker

  ```shell
  # version
  4.11.1
  ```

---

## 2. networks

- 刷新 dns 缓存

  ```shell
  # cmd
  ipconfig /flushdns
  
  # powershell
  Clear-DnsClientCache
  ```

- 禁用网卡

  ```shell
  netsh interface set interface "INTERNAL" disable
  ```

- 启用网卡

  ```shell
  netsh interface set interface "EXTERNAL" enable
  ```

---

## 3. mkilnk

```shell
# 注意：需要手动创建目标路径
# cmd
mklink /D "[链接名称]" "[目标路径]"

# google
mklink /D "C:\Program Files\Google" "D:\Google"

# docker
mklink /D "C:\Program Files\Docker" "D:\Docker"

# CCleaner
mklink /D "C:\Program Files\CCleaner" "D:\CCleaner"
```

## ——————

## others

- translate.google.com

  ```shell
  # 解决国内 google 翻译被墙

  cat >> 'C:\Windows\System32\drivers\etc\hosts' << EOF
  108.177.97.100 translate.google.com
  108.177.97.100 translate.googleapis.com
  EOF
  ```

- 在文件资源管理器中打开当前路径

  ```shell
  start "" .

  # alias open='start ""'
  ```

- 在 GoLand 中打开当前路径

  ```shell
  start "" "D:\JetBrains\GoLand\bin\goland64.exe" .

  # alias goland='start "" "D:\JetBrains\GoLand\bin\goland64.exe"'
  ```

- ping

  ```shell
  for ip in {1..254}; do ping -n 1 -w 30 10.112.27.$ip; done
  ```

- msftconnecttest.com

  ```shell
  # 关闭微软网络连接测试
  
  regedit:
  	"计算机\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\NlaSvc\Parameters\Internet"
  	EnableActiveProbing -> 0
  ```
