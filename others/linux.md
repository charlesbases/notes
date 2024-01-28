## if

```shell
# 判断对象是否为空
if [ ! "$a" ]; then
  echo "a is null"
else
  echo "a is not null"
fi

# -z 是否为空字符串
# -n 是否不为空
```

```shell
if [ -f "$filename" ]; then
  echo
fi

# -e 对象是否存在
# -d 对象是否存在, 并且为目录
# -f 对象是否存在, 并且为常规文件
# -L 对象是否存在, 并且为符号链接
# -h 对象是否存在, 并且为软链接
# -s 对象是否存在, 并且长度不为0
# -r 对象是否存在, 并且可读
# -w 对象是否存在, 并且可写
# -x 对象是否存在, 并且可执行
# -O 对象是否存在, 并且属于当前用户
# -G 对象是否存在, 并且属于当前用户组
```

---

## nfs

- ##### master

  ```shell
  apt install nfs-kernel-server -y

  # 设置挂载目录
  mkdir -p /data/nfs
  chmod a+w /data/nfs
  cat >> /etc/exports << EOF
  /data/nfs 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
  EOF

  # ro: 以只读方式挂载
  # rw: 赋予读写权限
  # sync: 同步检查
  # async: 忽略同步检查以提高速度
  # subtree_check: 验证文件路径
  # no_subtree_check: 不验证文件路径
  # no_root_squash: (危险项) 客户端 root 拥有服务端 root 权限

  # 启动服务
  sudo sh -c 'systemctl enable rpcbind && systemctl start rpcbind'
  sudo sh -c 'systemctl enable nfs-kernel-server && systemctl start nfs-kernel-server'

  # 查看
  showmount -e
  ```

- ##### node

  ```shell
  apt install nfs-common -y

  # 创建 nfs 共享目录
  sudo mkdir -p /data/nfs

  # 连接 nfs 服务器
  cat >> /etc/fstab << EOF
  # nfs-server
  192.168.1.10:/data/nfs /data/nfs nfs4 defaults,user,exec 0 0
  EOF

  #
  sudo mount -a

  # 启动服务
  sudo sh -c 'systemctl enable rpcbind && systemctl start rpcbind'

  # 查看
  df -h
  ```

---

## ssh

```shell
sudo apt install openssh-server ufw -y
ufw enable
ufw allow ssh

# ssh 密钥生成
ssh-keygen -t rsa -b 2048 -C "zhiming.sun" -f id_rsa

# ssh 免密
ssh-copy-id -i $HOME/.ssh/id_rsa.pub user@ip

# 多密钥管理
cat > $HOME/.ssh/config << EOF
Host 192.168.0.1
  User root
  Hostname 192.168.0.1
  # 服务器向客户端发送空包的时间间隔，以保持连接
  ServerAliveInterval 120
  # 服务端未收到客户端相应的空包的最大次数，就会关闭连接
  # 超时时间为 ServerAliveInterval * ServerAliveCountMax
  ServerAliveCountMax 720
  IdentityFile ~/.ssh/is_rsa
  PreferredAuthentications publickey
EOF
```

- ##### config

  ```shell
  ## ip 匹配
  cat > $HOME/.ssh/config << EOF
  Host 192.168.0.1
    # Port 22
    # User root
    # Hostname 192.168.0.1
    ServerAliveInterval 120
    ServerAliveCountMax 720
    IdentityFile ~/.ssh/is_rsa
    PreferredAuthentications publickey
  EOF

  ## 正则匹配
  cat > $HOME/.ssh/config << EOF
  Host 192.168.0.*
    ServerAliveInterval 120
    ServerAliveCountMax 720
    IdentityFile ~/.ssh/is_rsa
    PreferredAuthentications publickey
  EOF
  ```

---

## tar

```shell
# -c 建立新的备份文件(压缩)
# -x 从备份文件中还原文件(解压)
# -z 通过 gzip 命令处理文件
# -v 显示执行过程
# -f 指定文件
# -C 输出文件夹路径
```

```shell
# 压缩文件

# *.tar
tar -cvf demo.tar.gz demo

# *.tar.gz
tar -zcvf demo.tar.gz demo
```

```shell
# 解压文件

# *.tar
tar -xvf demo.tar

# *.tar.gz | *.tgz
tar -zxvf demo.tar.gz -C demo

# *.tar.bz2
tar -jxvf demo.tar.bz2

# *.tar.Z
tar -Zxvf demo.tar.Z

# *.zip
unzip -d demo demo.zip
```

---

## vim

- ##### ketwords

  ```shell
  # 快捷键

  # G:  跳至文本最后一行
  # gg: 跳至文本首行
  # $:  跳至当前行最后一个字符
  # 0:  跳至当前行首字符
  ```

- ##### [.vimrc](.share/.vimrc)

---

## args

```shell
# $0 # 命令本身
# $1 # 第一个参数
# $# # 参数个数。不包括 "$0"
# $@ # 参数列表。不包括 "$0"
# $* # 不加引号是与 $@ 相同。"$*" 将所有的参数解释成一个字符串，"$@" 是一个参数数组

# ${variable:? msg}  # 如果 variable 为空，则返回 msg 错误输出。eg: arg=${1:? arg cannot be empty}
# ${variable:-value} # 如果 variable 为空，则返回 value。eg: arg=${1:-$(pwd)}
```

---

## curl

```shell
curl [optins] <url>

# options
#
# -X  HTTP Method. eg: `-X POST`
# -H  HTTP Header. eg: `-H "Content-Type: application/json"`
# -d  Request Param. eg: `-d '{"username": "user", "password": "password"}'`
# -k, --insecure  不验证 ssl 证书
# -s, --silent    静默模式，不显示其他信息
```

---

## date

```shell
# %Y 年份. 2006
# %m 月份. 01-12
# %d 日期. 01-31
# %H 小时. 00-23
# %M 分钟. 00-60
# %S 秒.   00-60
# %j 一年中的第几天. (001-366)
# %U 一年中的第几周. 从周日开始计算. (00-53)
# %W 一年中的第几周. 从周一开始计算. (00-53)
# %s 从 1970-01-01 00:00:00 UTC 起的秒数
```

```shell
# date +"%Y-%m-%d %H:%M:%S"
# date +"%Y%m%d%H%M%S"
```

---

## eval

```shell
# 将参数作为命令进行解释并执行
command="echo Hello, Word"
eval $command
```

---

## find

```shell
# 递归显示文件夹下所有子文件夹及其目录
find . -print

# 只显示文件夹
find . -type d -print

# 只显示文件
find . -type f -print

# 排除文件夹
find -name .git -prune -o -type f -print
find -name .git -prune -o -name .idea -prune -o -type f -print

# `-print`  显示匹配项到标准输出
# `-type d` 显示文件夹
# `-type f` 显示文件
# `-name .git -prune` 排除名称为 '.git' 的文件夹
# `-o` 或，用于连接多个表达式
```

---

## loop

- ##### for

- ##### while

  ```shell
  # shell 中管道 '|' 会创建子 shell，导致变量作用域改变
  # 若要在 `while read` 循环中，修改外部变量

  # 1. here-string
  index=0
  while read line; do
    index=$[index+1]
  done <<< $(cat $file)
  ```

---

## opts

- ##### select

  ```shell
  # 简单菜单的控制结构

  # select 菜单的提示语，会在展示菜单后打印
  PS3="请选择一个选项: "

  select opt in "a" "b" "c" "quit"; do
    case $opt in
      "a")
        echo "a"
        break
      ;;
      "b")
        echo "b"
        break
      ;;
      "c")
        echo "c"
        break
      ;;
      "quit")
        exit
      ;;
      *)
        echo "invalid input"
        exit
      ;;
    esac
  done
  ```

- ##### getopts

  ```shell
  while getopts ":a:bc" opt; do
    case $opt in
      a)
      echo $OPTARG
      ;;
      b)
      echo "b"
      ;;
      c)
      echo "c"
      ;;
      ?) # 其他参数
      echo "invalid input"
      ;;
    esac
  done

  # 该命令可以识别 '-a -b -c' 选项。其中 '-a' 需要设置 value，'-b -c' 不需要 value
  # getopts 每次调用时，会将下一个 'opt' 放置在变量中，$OPTARG 可以从 '$*' 中拿到参数值。$OPTARG 是内置变量
  # 第一个 ':' 表示忽略错误
  # a: 表示该 'opt' 需要 value
  # b  表示该 'opt' 不需要 value

  # 去除 options 之后的参数, 可以在后面的 shell 中进行参数处理
  shift $(($OPTIND - 1))
  echo $1
  ```

---

## root

```shell
vim /etc/ssh/sshd_config

···
PermitRootLogin yes
···

#
sh -c 'echo "PermitRootLogin yes" >> /etc/ssh/sshd_config'

# 取消倒计时
sed -i -s "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/g" /etc/default/grub

update-grub2 && reboot
```

---

## text

```shell
# shell 文本处理函数
```

### 1. tr

```shell
# 替换相同数量的字符

# 将 ' ' 替换为 '\n'
echo 'hello world' | tr ' ' '\n'
```

### 2. awk

- ##### variable

  ```shell
  # $0  : 当前行内容
  # $1, $2 ... $NF : 当前行的第 1, 2 ... NF 列内容
  # FILENAME       : 当前处理的文件名
  # NR  : 当前行号。注意，当处理多个文件时，'NR' 是累加的
  # FNR : 当前文件的行号
  # NF  : 当前行的列数
  # RS  : 输入记录行分隔符(default: '\n')
  # FS  : 输入记录列分隔符(default: ' ')
  # ORS : 输出记录行分隔符(default: '\n')
  # OFS : 输出记录列分隔符(default: ' ')
  ```

#### 2.1. examples

##### 2.1.1. print

```shell
# 打印第一行
cat demo.txt | awk 'NR==1'

# 打印最后一行
cat demo.txt | awk 'END {print}'

# 打印第一行第一列
cat demo.txt | awk 'NR==1 {print $1}'

# 打印第一列和第三列
cat demo.txt | awk '{print $1,$3}'

# 打印最后一列
cat demo.txt | awk '{print $NF}'

# 打印行号
cat demo.txt | awk '{print NR}'

# 打印行数
cat demo.txt | awk 'END {print NR}'
```

##### 2.1.2. delimiter

```shell
# RS
# awk 读取文件时的行分隔符
echo '1,2,3' | awk '{print $1}'
···
1,2,3
···
echo '1,2,3' | awk -v RS="," '{print $1}'
···
1
2
3
···

# ORS
# awk 输出时的行结束符
seq 3 | awk '{print $1}'
···
1
2
3
···
seq 3 | awk -v ORS="," '{print $1}'
···
1,2,3,
···

# FS (-F)
# awk 读取文件时的列分隔符
echo '1,2,3' | awk -F , '{print $1}'      # 1
echo '1,2,3' | awk -v FS="," '{print $1}' # 1
# 注意: 使用 'FS' 时，'print $0' 本身没任何改变, 需改变 '$0'
echo '1,2,3' | awk -v FS="," '{$1=$1; print}'

# OFS
# awk 输出时的列分隔符
echo '1 2 3' | awk '{print $0}'                  # 1 2 3
echo '1 2 3' | awk -v OFS="," '{print $1,$2}'    # 1,2
# 打印 '$0' 时，为使 'OFS' 生效，需要改变 '$0'，实际上 '$0' 本身没任何改变
echo '1 2 3' | awk -v OFS="," '{$1=$1;print $0}' # 1,2,3
```

##### 2.1.3. matching

```shell
# 打印匹配字符行
awk '/image: / print}' calico.yaml

# 去除 'image:'
awk '/image: / {sub(/image:/, ""); print}' calico.yaml
awk '/image: / {sub(/image:/, ""); gsub(/ /, ""); print}' calico.yaml

# sub 替换一次
# gsub 全部替换
```

```shell
# 打印匹配字符所在行号
awk '/^kind: Namespace/ {print FILENAME":"NR} ' tekton.yaml
# `/^kind: Namespace/ {print FILENAME":"NR}`: 当匹配到 '^kind: Namespace' 时，执行 '{print FILENAME":"NR}', 注意 ':' 需要添加引号

# 打印匹配字符，并且未注释的行号
awk '!/^#/ && /name: argocd-notifications/ {print FILENAME":"NR}' argocd.yaml
# `/xxx/` 为一个筛选条件，`{xxx}` 为执行的语句，可类比 if 语句
```

```shell
# 打印俩个匹配字符之间的内容。包含匹配行
awk '/^data/,/^kind/' secret.yaml

# 打印俩个匹配字符之间的内容。不包含匹配行
awk '/^data/,/^kind/ { if (!/^data/ && !/^kind/) print }' secret.yaml
```

```shell
# k8s.yaml 文件中，打印 "image" 信息，若镜像带有 hash 值，则根据 '@' 进行字段分割
awk '!/#/ && /image: / {gsub(/ /, ""); sub(/image:/, ""); split($1, arr, "@"); print arr[1]}' k8s.yaml | sort | uniq
# 将匹配到的第一个字段，以 '@' 进行分割，存入变量 'arr'，并打印 'arr' 第一个字段
```

```shell
# 在 k8s 的 多个资源类型 yaml 中，找到匹配字符所在的模块.(打印最近的 '---' 所在行)
awk '/^---/ {if (mark) { print FILENAME":"above; print FILENAME":"NR}; above=NR; focus=""; next} /^kind: Namespace/ {mark=NR}' tekton.yaml
# 在匹配到 '^kind: Namespace' 时，标记 'mark'，在下次匹配到 '^---' 时，打印上次匹配到的 '^---' 行，并且打印本次匹配到的行
# 注意：print 时，'print above NR' 实际效果为 'aboveNR', 'print above" "NR' 实际效果为 'above NR', 'print above, NR' 实际效果为 'above NR'

# 在 k8s 的 多个资源类型 yaml 中，找到匹配字符所在的模块, 并注释相关代码
awk '/^---/ {if (focus) { print above","NR}; above=NR; focus=""; next} /^kind: Namespace/ {focus=NR}' tekton.yaml | while read line; do sed -i "$line {/^[^#]/ s/^/# /}" tekton.yaml; done
```

#### 2.2. commands

```shell
# docker images
docker images | awk -v OFS=":" '{print $1,$2}'

# docker images (一行展示)
docker images | awk 'BEGIN{ORS=" ";OFS=":"}{print $1,$2}'
```

### 3. cut

```shell
# 以单字符作为列分隔符
# -d: 分隔符。注意：cut 只支持单字符作为列分隔符
# -f: 指定输出的字段

# 以 ':' 为分隔符，打印第二个字段
echo 'a:b:c:d:e:f' | cut -d: -f2

# 以 ':' 为分隔符，打印第二至最后一个字段
echo 'a:b:c:d:e:f' | cut -d: -f2-

# 以 ':' 为分隔符，打印第二至第三个字段
echo 'a:b:c:d:e:f' | cut -d: -f2-3
```

### 4. sed

- ##### options

  ```shell
  # -n:  不输出默认内容。在没有这个选项时，sed 会默认输出每一行内容到终端
  ```

#### 4.1. trim

```shell
# str='   fmt.Println("Hello Word")    '

# 移除开头空格
echo $str | sed 's/^ *//'

# 移除结尾空格
echo $str | sed 's/ *$//'

# 移除头尾空格
# echo $str | sed 's/^ *//; s/ *$//'
echo $str | sed 's/\(^ *\)\(.*[^ ]\)\( *$\)/\2/'
# `\(^ *\)`:    第一个子表达式, 匹配从其实位置开始的 0+ 个空格字符
# `\(.*[^ ]\)`: 第二个子表达式, 匹配任意字符, 并且确保末尾不是空格字符. `[^ ]` 匹配一个非空字符, `[^abc]` 匹配一个不为 a、b、c 的字符
# `\( *$\)`:    第三个子表达式, 匹配字符串末尾的 0+ 个空格字符
# `\2`:         替换部分只引用第二个子表达式捕获的子串

# Hello Word
echo $str | sed 's@.*"\(.*\)".*@\1@'
# `\(.*\)` 表示一个子表达式, `\` 为转义, `\1` 表示表一个子表达式所捕获的字符串

# 知识点
# ^ 表示从字符串起始位置开始, $ 表示至字符串结尾
# * 表示前一个字符匹配 0+ 次, '[0-9]*' 表示 0-9 匹配 0+ 次
# . 表示匹配任意字符, .* 表示匹配任务字符 0+ 次
```

#### 4.2. append

```shell
# 在每一行后面追加一行 "New Line"
sed -i 'a New Line' file.txt
# 注: 追加内容时, 'a New Line' 不管 'a' 后面的 ' ' 多少, 'New Line' 都会从下一行第一个字符开始。
#     若要在行开头添加 ' ', 使用 'a\ New Line'.

# 在匹配行后面追加一行 "New Line"
sed -i '/nginx/a New Line' file.txt

# (正则)在匹配行后面追加一行 "  New Line"
sed -i "/^[[:space:]]nginx/a\  New Line" file.txt
## [[:space:]]  表示匹配空格
## [[:space:]]* 表示匹配任意空格

# 在匹配行前面追加一行 "New Line"
sed -i '/nginx/i New Line' file.txt

# 添加首行
sed -i '1i # hello word' file.txt

# 在第 10 行追加 new.txt 文件内容
sed -i '20r new.txt' file.txt

# a 在匹配行后面追加一行
# i 在匹配行前面插入一行
# r 在匹配行后面追加文件内容
```

#### 4.3. delete

```shell
# 删除包含匹配字符的行
sed -i '/pattern/d' file.txt

# 删除指定行
sed -i '5d' file.txt

# 删除指定范围的行
sed -i '10,20d' file.txt
```

#### 4.4. replace

```shell
# old 全字符匹配(首个)
sed -i -s 's/old/new/' file.text

# 正则匹配
sed -i -s 's/.*old.*/new/g' file.text

# 匹配 '/'
sed -i -s 's|/var/lib/kubelet|/munt/kubelet|g' file.text

# 匹配多条
sed -i -e 's/1/2/g' -e 's/3/4/g' file.text

# 在每一行开头添加字符 '#'
# '&' 表示匹配到的字符
sed -i 's/^/#&/g' file.text

# 在每一行末尾添加字符 '#'
sed -i 's/^/&#/g' file.text

# 在第1-9行行首添加字符 '# '
sed -i '1,9 s/^/# /' file.text

# 在第1-9行，并且不以 '#' 开头的行行首添加字符 '# '
sed -i '1,9 {/^[^#]/ s/^/# /}' file.text

# 查看第 100 行内容
sed -n '100p' file.txt
# -n   禁止输出所有内容
# 100p 打印第 100 行

# g  全局替换
# -i 用修改结果直接替换源文件内容
# -s 字符串替换 's/old/new/g' 或 's@old@new@g' 、's|old|new|g'
```

#### 4.5. matching

```shell
echo 'fmt.Println("hello word")' | sed 's/.*"\([^"]*\)".*/\1/'
# hello word
# 注意，该命令在未匹配到字符串时，会默认打印模式空间的全部内容，推荐使用下面俩种方法
echo 'fmt.Println("hello word")' | sed 's/.*"\([^"]*\)".*/\1/;t;d'
# ';t': 若前面的命令替换成功，则跳转到脚本末尾，绕过默认的打印行为（打印匹配行）
# ';d': 删除模式空间的内容，即不打印任何内容
echo 'fmt.Println("hello word")' | sed -n 's/.*"\([^"]*\)".*/\1/p'
# '-n': 禁止自动打印模式空间的内容
# '/p': 显示匹配行

# 输出 image 列表
sed -n '/image:/ s/image://p' calico.yaml
# -n:             取消默认打印行为
# '/image:/':     行筛选
# 's/image://p':  替换命令。(s=substitute) 将 'image:' 替换为 ''，'p' 为打印替换后的结果
```

### 5. grep

```shell
# -i 忽略大小写
# -v 反转匹配
# -n 显示匹配模式的行号
# -o 只显示匹配子串

# -- 停止解析选项参数。匹配 '--root-dir' 时使用。eg: grep -- --root-dir
```

```shell
# 开头匹配
cat file.txt | grep '^kind: PrometheusRule'

# 打印匹配字段所在行
grep -n 'apiVersion' tekton.yaml | awk -F ':' '{print $1}'
# 只打印第一行
grep -n -m 1 'apiVersion' tekton.yaml | awk -F ':' '{print $1}'
# 注意: `grep -m 1` 为最多匹配 1 行
# 若要显示第 3 行, 使用 `grep -m 3 xxx | tail -n 1`, 表示从前三行中选择最后一行
# 或者使用 `awk`
```

```shell
# 字符串搜索
grep -nr 'sync.Once' "$(dirname $(which go))/../src"
# -n 打印行
# -r 递归地搜索指定目录中的文件和子目录

# 统计行
grep -nr 'sync.Once' "$(dirname $(which go))/../src" | wc -l
```

- ##### regexp

  ```shell
  # 根据正则输出匹配子串
  # [{"id":1},{"id":12},{"id":123}]
  echo '[{"id":1},{"id":12},{"id":123}]' | grep -o '"id":[0-9]*'
  # "id":1
  # "id":12
  # "id":123

  # 'fmt.Println("https://www.google.com")'
  grep -o 'https://[^"]*'
  # https://www.google.com
  ```

### 3. sort

```shell
# 按 ASCII 正序
echo "a c b" | tr ' ' '\n' | sort

# 按 ASCII 倒叙
echo "a c b" | tr ' ' '\n' | sort -r

# 按字符串长度排序, 二级排序方式为 ASCII
echo "a bbb cc ddd" | tr ' ' '\n' | awk '{print length($1), $1}' | sort
```

### 4. uniq

```shell
# uniq 只能去除相邻字符串的重复，所以需要先使用 `sort` 进行排序

demo="""
a
b
a
b
"""

cat $demo | sort | uniq
```

### x. summary

#### 1. trim

```shell
filename=abc.tar.gz

# 从最后一次出现 '.' 开始，截取左边所有字符
echo "${filename%.*}" # abc.tar

# 从首次出现 '.' 开始，截取左边所有字符
echo "${filename%%.*}" # abc

# 从首次出现 '.' 开始，截取右边所有字符
echo "${filename#*.}" # tar.gz

# 从最后一次出现 '.' 开始，截取右边所有字符
echo "${filename##*.}" # gz

# 以 '.' 为分隔符输出数组
echo ${filename//./ } # abc tar gz
```

#### 2. split

```shell
# 'a,b,c,d,e,f'

1. `cut -f1 -d,`
# -f1 打印第一个字段
# -d, 以 ',' 为分隔符

2. `awk -F , '{print $1}'`
```

#### 3. replace

```shell
# 替换相同数量的字符
echo 'hello world' | tr ' ' '\n'

# 只替换首次
echo ${string/substring/replacement}

# 全部替换
echo ${string//substring/replacement}
```

#### 4. matching

```shell
# 'a,b,c,d,e,f'
# 只替换一个字符时, 使用 `tr ',' '.'`
# a.b.c.d.e.f

# 'aabbccddeedd'
# 字符串替换时, 显示替换后的字符串, 使用 `sed 's/[^a]/a/g'`
# aaaaaaaaaaaa
```

```shell
# 'fmt.Println("https://www.google.com")'
# 匹配已知的前缀和后缀使用 `grep -o 'https://[^"]*'`
# https://www.google.com
```

```shell
# 'fmt.Println("hello word")'
# 匹配未知的前缀和后缀使用 `sed 's/.*"\(.*\)".*/\1/'`
# hello word
```

#### 5. commands

```shell
# 去除首尾空格

# '    space    '
# 去除字符串首尾空格, 使用 `sed 's/^ *//; s/ *$//'`
# space
```

```shell
# 行、列处理

# 'aaa,bbb,ccc'
# 字符串行、列处理, 使用 `awk -v RS=',' 'NR==1 {print}'`
# aaa
```

---

## swap

```shell
# 临时禁用
sudo swapoff -a

# 临时启用
sudo swapon -a

# 永久禁用
sudo vim /etc/fstab
···
# /mnt/swap swap swap defaults 0 0
···
reboot

# 或
sed -ri 's/.*swap.*/# &/' /etc/fstab

# 查看分区状态
free -m
```

---

## user

```shell
# 所有用户
cat /etc/passwd
# getent passwd

# 添加用户
sudo useradd -G root,docker -s /bin/zsh -d /home/user -m user

# 删除用户
sudo userdel -r user
```

- ##### groups

  ```shell
  # 当前用户所属组
  groups

  # 添加用户组
  sudo groupadd usergroup

  # 删除用户组
  sudo groupdel usergroup

  # 添加用户至 root 组
  sudo gpasswd -a $USER root

  # 从 root 组删除用户
  sudo gpasswd -d $USER root

  # 更新 root 用户组
  newgrp usergroup
  ```

- ##### sudoers

  ```shell
  sudo vim /etc/sudoers

  # 添加 sudo 权限
  username ALL=(ALL:ALL) ALL

  # 普通用户 sudo 免密
  username ALL=(ALL) NOPASSWD:ALL
  ```

- ##### password

  ```shell
  # 修改当前用户密码
  sudo passwd

  # 修改其他用户密码
  sudo passwd sun
  ```

---

## wget

```shell
wget [optoins] <url>

# options
#
# -O  指定保存下载文件名
# -P  指定保存下载文件夹
# -c  断点续传
# -q  静默模式，减少输出信息

# 将文件内容下载并保存到管道
wget -O - <url>
```

---

## fdisk

```shell
# 查看已有分区
sudo fdisk -l

# 操作磁盘
sudo fdisk /dev/sda

# m: command help
# d: 删除磁盘分区
# n: 添加磁盘分区
# w: 保存并退出

# 格式化分区
sudo mkfs -t ext4 /dev/sda3

# 分区挂载
cat >> /etc/fstab << EOF
/dev/sda3 /mnt/sda3 ext4 defaults 0 0
EOF

reboot
```

---

## nohup

```shell
# 后台启动
nohup ./script.sh > /opt/log/output.log 2>&1 &

# PID
ps aux | grep "./script.sh"
```

---

## rsync

```shell
# 本地同步
rsync -a source destination

# 远程同步
rsync -a source user@remote:destination

# -a 递归；保存文件信息，包括时间、权限等
# -r 递归
# -z 传输时使用数据传输
# --delete 从 'destination' 删除 'source' 中不存在的文件
```

---

## sysctl

```shell
# 内核优化
cat > /etc/sysctl.conf << EOF
# maximum number of open files/file descriptors
fs.file-max = 4194304

# use as little swap space as possible
vm.swappiness = 0

# prioritize application RAM against disk/swap cache
vm.vfs_cache_pressure = 50

# minimum free memory
vm.min_free_kbytes = 1000000

# follow mellanox best practices https://community.mellanox.com/s/article/linux-sysctl-tuning
# the following changes are recommended for improving IPv4 traffic performance by Mellanox

# disable the TCP timestamps option for better CPU utilization
net.ipv4.tcp_timestamps = 0

# enable the TCP selective acks option for better throughput
net.ipv4.tcp_sack = 1

# increase the maximum length of processor input queues
net.core.netdev_max_backlog = 250000

# increase the TCP maximum and default buffer sizes using setsockopt()
net.core.rmem_max = 4194304
net.core.wmem_max = 4194304
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.core.optmem_max = 4194304

# increase memory thresholds to prevent packet dropping:
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 65536 4194304

# enable low latency mode for TCP:
net.ipv4.tcp_low_latency = 1

# the following variable is used to tell the kernel how much of the socket buffer
# space should be used for TCP window size, and how much to save for an application
# buffer. A value of 1 means the socket buffer will be divided evenly between.
# TCP windows size and application.
net.ipv4.tcp_adv_win_scale = 1

# maximum number of incoming connections
net.core.somaxconn = 65535

# maximum number of packets queued
net.core.netdev_max_backlog = 10000

# queue length of completely established sockets waiting for accept
net.ipv4.tcp_max_syn_backlog = 4096

# time to wait (seconds) for FIN packet
net.ipv4.tcp_fin_timeout = 15

# disable icmp send redirects
net.ipv4.conf.all.send_redirects = 0

# disable icmp accept redirect
net.ipv4.conf.all.accept_redirects = 0

# drop packets with LSR or SSR
net.ipv4.conf.all.accept_source_route = 0

# MTU discovery, only enable when ICMP blackhole detected
net.ipv4.tcp_mtu_probing = 1

EOF

sysctl -p

# transparent_hugepage = madvise
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
```

---

## corndns

```shell
# 禁用 systemd-resolve
# 解决服务器的 53 端口占用
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# docker
docker pull coredns/coredns:1.10.0
```

```shell
# sudo mkdir /etc/coredns
cat > /etc/coredns/start.sh << EOF
docker run -d -p 53:53/udp -v /etc/coredns/Corefile:/Corefile --name coredns --restart always  coredns/coredns:1.10.0
EOF
```

- ##### Corefile

  ```
  .:53 {
    hosts {
      192.168.1.1 coredns.com

      ttl 5
      fallthrough
    }

    # 未匹配的域名转发到上游 DNS 服务器
    forward . 192.168.1.1

    errors
    log stdout

    cache 60
    reload 3s
  }
  ```

---

## mirrors

- ##### apt

  ```shell
  sudo apt update
  sudo apt upgrade -y
  sudo apt install vim git zsh wget curl make htop lsof tree expect net-tools -y
  ```

  - ##### debain

    ```shell
    # 备份
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

    ···
    # cqu
    http://mirrors.cqu.edu.cn

    # ustc
    http://mirrors.ustc.edu.cn

    # aliyun
    http://mirrors.aliyun.com

    # tsinghua
    http://mirrors.tuna.tsinghua.edu.cn
    ···

    ··· Debian 11
    deb http://mirrors.aliyun.com/debian/ bullseye main
    # deb-src http://mirrors.aliyun.com/debian/ bullseye main
    deb http://mirrors.aliyun.com/debian/ bullseye-updates main
    # deb-src http://mirrors.aliyun.com/debian/ bullseye-updates main
    deb http://mirrors.aliyun.com/debian/ bullseye-backports main
    # deb-src http://mirrors.aliyun.com/debian/ bullseye-backports main
    deb http://mirrors.aliyun.com/debian-security bullseye-security main
    # deb-src http://mirrors.aliyun.com/debian-security bullseye-security main
    ···

    apt update -y
    ```

- ##### yum

---

## ohmyzsh

```shell
# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"

sed -i -s "s/robbyrussell/ys/g" $HOME/.zshrc && source $HOME/.zshrc
```

- ##### dircolors

  ```shell
  dircolors >> ~/.zshrc

  sed -s -i 's/ow=34;42/ow=34/' ~/.zshrc

  # 修改 ow=34;42 ==> ow=34
  # 30: 黑色前景
  # 34: 蓝色前景
  # 42: 绿色背景
  ```

- ##### .zshrc

  ```shell
  cat >> ~/.zshrc << EOF
  if [ -d $HOME/.profile.d ]; then
    for i in `ls $HOME/.profile.d | grep .sh`; do
      if [ -r $HOME/.profile.d/$i ]; then
        . $HOME/.profile.d/$i
      fi
    done
    unset i
  fi

  # export
  set completion-ignore-case on
  export TERM=xterm-256color
  export TIME_STYLE="+%Y-%m-%d %H:%M:%S"

  # alias
  alias l="ls -lh"
  alias la="ls -Alh"
  alias his="history -i"

  EOF
  ```

---

## openssl

![ssl](.share/openssl.png)

- ##### full

  ```shell
  # 完整版
  # 模拟 HTTPS 厂商生产 HTTPS 证书过程，HTTPS 证书厂商一般都会有一个根证书（3、4、5），实际申请中，该操作用户不可见。通常用户只需将服务器公钥与服务器证书申请文件交给 HTTPS 厂商即可，之后 HTTPS 厂商会邮件回复一个服务器公钥证书，拿到这个服务器公钥证书与自生成的服务器私钥就可搭建 HTTPS 服务

  # 1. 生成服务器私钥
  openssl genrsa -out server.key 2048

  # 2. 生成服务器证书申请文件
  openssl req -new -key server.key -out server.csr

  # 3. 生成 CA 机构私钥
  openssl genrsa -out ca.key 2048

  # 4. 生成 CA 机构证书请求文件
  openssl req -new -key ca.key -out ca.csr

  # 5. 生成 CA 机构根证书（自签名证书）
  openssl x509 req -signkey ca.key -in ca.csr -out ca.crt

  # 6. 生成服务器证书（公钥证书）
  openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -in server.csr -out server.crt
  ```



- ##### simplify

  ```shell
  # 精简版
  # 本地 HTTPS 测试，既是用户角色也是 HTTPS 厂商角色

  # 1. 生成服务器私钥
  openssl genrsa -out server.key 2048

  # 2. 生成服务器证书申请文件
  openssl req -nodes -noout -new -key server.key -out server.csr

  # 3. 生成服务器证书
  openssl x509 -req -signkey server.key -in server.csr -out server.crt -days 3650
  ```

  ```shell
  # 生成本地服务器证书
  openssl req -nodes -new -x509 -newkey rsa:2048 -keyout server.key -out server.crt
  ```

- ##### mkcert

  ```shell
  ```

---

## service

```shell
sudo cat > /etc/systemd/system/myservice.service << EOF
[Unit]
Description=MyService
After=network-online.target

[Service]
Type=notify

User=root
Group=root

Restart=on-failure

# exec
ExecStart=start command
ExecStop=stop command
# ExecReload=restart command

[Install]
WantedBy=multi-user.target
EOF

# daemon-reload
sudo systemctl daemon-reload

# enable
sudo systemctl enable myservice

# start
sudo systemctl start myservice

# status
sudo systemctl status myservice
```

```shell
# .service 文件说明，"*" 为必要参数

# [Uint] 启动顺序与依赖关系
[Uint]
# *Description 描述
Description=[txt]
# Documentation 文档位置
Documentation=[url|fullpath]

# 启动顺序，多个服务用空格分隔
# *After 当前服务在指定服务之后启动
After=network-online.target
# Before 当前服务在指定服务之前启动
Before=network-online.target

# 依赖关系
# Wants 弱依赖关系服务，指定服务发生异常不影响当前服务
Wants=network-online.target
# Requires 强依赖关系服务，指定服务发生异常，当前服务必须退出
Requires=network-online.target

# [Service] 启动行为
[Service]
# EnvironmentFile 环境变量文件
EnvironmentFile=[fullpath]
# *ExecStart 启动服务时执行的命令
ExecStart=[shell]
# *ExecStop 停止服务时执行的命令
ExecStop=[shell]
# ExecReload 重启服务时执行的命令
ExecReload=[shell]
# ExecStartPre 启动服务之前执行的命令
ExecStartPre=[shell]
# ExecStartPost 启动服务之后执行的命令
ExecStartPost=[shell]
# ExecStopPost 停止服务之后执行的命令
ExecStopPost=[shell]

# Type 启动类型
#   simple(default):ExecStart字段启动的进程为主进程
#   forking: ExecStart字段将以fork()方式启动，此时父进程将会退出，子进程将成为主进程
#   oneshot: 类似于simple，但只执行一次，Systemd 会等它执行完，才启动其他服务
#   dbus: 类似于simple，但会等待 D-Bus 信号后启动
#   notify: 类似于simple，启动结束后会发出通知信号，然后 Systemd 再启动其他服务
#   idle: 类似于simple，但是要等到其他任务都执行完，才会启动该服务。一种使用场合是为让该服务的输出，不与其他服务的输出相混合
Type=simple

# KillMode 如何停止服务
#   control-group(default): 当前控制组里面的所有子进程，都会被杀掉
#   process: 只杀主进程
#   mixed: 主进程将收到 SIGTERM 信号，子进程收到 SIGKILL 信号
#   none: 没有进程会被杀掉，只是执行服务的 stop 命令。
KillMode=control-group

# 重启方式
# no(default): 退出后不会重启
# on-success: 只有正常退出时（退出状态码为0），才会重启
# on-failure: 非正常退出时（退出状态码非0），包括被信号终止和超时，才会重启
# on-abnormal: 只有被信号终止和超时，才会重启
# on-abort: 只有在收到没有捕捉到的信号终止时，才会重启
# on-watchdog: 超时退出，才会重启
# always: 不管是什么退出原因，总是重启
Restart=no
# RestartSec 重启服务之前等待的秒数
RestartSec=3

# [Install]
[Install]
# Target（服务组）说明
# 例：WantedBy=multi-user.target
# 执行 sytemctl enable **.service命令时，**.service的一个符号链接，就会放在/etc/systemd/system/multi-user.target.wants子目录中
# 执行systemctl get-default命令，获取默认启动Target
# multi-user.target组中的服务都将开机启动
# 常用Target，1. multi-user.target-多用户命令行；2. graphical.target-图形界面模式
WantedBy=[表示该服务所在的Target]
```

---

## hostname

```shell
sudo hostnamectl set-hostname athena
```

---

## redirect

```shell
# > : 用于将标准输出重定向到文件 eg: date >/dev/null
# >&: 用于将一个文件描述符重定向到另一个文件描述符 eg: date 2>&1
# &>: 用于将标准输入和标准输出重定向到文件 eg: date &>/dev/null
# >>: 用于将标准输出追加到文件 eg: date >> a.txt

# < : 用于将文件作为命令的标准输入 eg: cat < bash.bashrc
# | : 管道。用于将上一个命令的标准输出作为下一个命令的标准输入 eg: date | cat

# <(command): 使用进程替换，将命令的输出作为文件传递给另一个命令 eg: cat <(date)

# <<< : here-string. 允许将一个字符串作为上一个命令的标准输入 eg: grep -o Hello <<< "Hello, World"
```

---

## timezone

- ##### debain

  ```shell
  sudo sh -c "apt install ntp -y && ntpd time.windows.com && timedatectl set-timezone 'Asia/Shanghai'"
  ```

- ##### ubuntu

- ##### contos

  ```shell
  sudo sh -c "yum install ntp -y && ntpdate time.windows.com && timedatectl set-timezone 'Asia/Shanghai'"
  ```

```shell
# 方案一
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 方案二
export TZ="Asia/Shanghai"
```

---

## firewalld

```shell
# 查看防火墙状态
sudo systemctl status firewalld

# 安装服务
apt install firewalld -y

# 开启服务
systemctl start firewalld

# 关闭服务
systemctl stop firewalld

# 查看状态
systemctl status firewalld

# 开机启动
systemctl enable firewalld

# 开机禁用
systemctl disable firewalld

# 开放端口
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=8080-9090/tcp --permanent

# 关闭端口
firewall-cmd --zone=public --remove-port=8080/tcp --permanent

# 查看端口列表
firewall-cmd --zone=public --list-ports
```

---

## resources

- ##### cpu

  ```shell
  # cpu 核心数
  nproc

  # cpu 详细信息
  lscpu
  ```

---

## bash-completion

- ##### macos

- ##### linux

  ```shell
  # 下载 completion 脚本
  sudo apt install -y bash-completion

  cat >> ~/.bashrc << EOF
  # completions
  source /usr/share/bash-completion/bash_completion
  source /usr/share/bash-completion/completions/git
  # 执行 `kubectl completion bash` 生成的命令补全脚本
  source <(kubectl completion bash)

  EOF
  ```

- ##### windows

  ```shell

  ```

---

## ——————————

## scripts

- ##### [remote](.share/scripts/remote.sh)

  ```shell
  cat >> $HOME/.zshrc << EOF
  alias r="$HOME/.scripts/remote.sh"
  EOF

  source $HOME/.zshrc
  ```

- ##### [watchers](.share/scripts/watchers.sh)

  ```shell
  crontab -e

  # 每分钟执行
  * * * * * /root/.scripts/watchers.sh
  ```

- ##### [docker-cleaner](.share/scripts/docker-cleaner.sh)

  ```shell
  cat >> $HOME/.zshrc << EOF
  alias d="$HOME/.scripts/docker-cleaner.sh"
  EOF

  source $HOME/.zshrc
  ```
