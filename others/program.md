## lua

### 1. random

```lua
-- math.random
-- 问题：
-- 1：第一个随机数总是固定；
-- 2：如果 seed 很小或者变化很小，产生的随机序列仍然很相似；
-- 3：如果很短时间内执行多次，结果几乎不变

-- 设置种子
math.randomseed(tostring(os.time()) .. tostring(os.clock()))
-- 生成随机数 [1, 10000]
math.random(1, 10000)
```

---

## rust

```shell
# 安装
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 换源
vim .cargo/config.toml

···
[net]
  git-fetch-with-cli = true

[source.crates-io]
  repository = "https://github.com/rust-lang/crates.io-index"
  replace-with = 'tuna'

[source.tuna]
  repository = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
···

# 清除缓存
rm ~/.cargo/.package-cache

# 更新
rustup update

# 卸载
rustup self uninstall
```

---

## golang

```shell
# download
wget -c https://golang.google.cn/dl/go1.20.10.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local

# environment
cat >> ~/.zshrc << EOF
export GOHONE="/usr/local/go"
export GOPATH="/opt/go"
export GOPROXY="https://goproxy.io,direct"
export GO111MODULE="on"
EOF

# add to path
cat >> ~/.zshrc << EOF
export PATH="$PATH:$GOHOME/bin:$GOPATH/bin"
EOF

#
sudo mkdir -p $GOPATH/{bin,pkg,src}
```

### tips

```shell
# 运算符优先级
# '.' > '&' = '*' > '--' = '++'
#   p := &t.x <=> p := &(t.x)
#   *p++      <=> (*p)++
```

### 1. go test

```shell
# 运行当前目录下所有测试函数
# -v: 将缓冲区内容输出到终端
go test -v .

# 禁用 test 缓存
go test -v -count 1 .

# 运行指定函数
# 注意：-run 是运行正则匹配的测试用例
go test -v -run TestName .
```

#### 1.1. cover

```shell
# 简略信息
go test -cover

# 详细信息
go test -coverprofile=cover.out && go tool cover -html=cover.out -o cover.html
```

#### 1.2. benchmark

- args

  ```shell
  # -test.bench=.
  # 运行性能测试
  
  # -test.bench=BenchmarkFunc
  # 运行匹配的性能测试用例
  
  # -test.benchtime=10x [30s]
  # 性能测试运行10次，或者30s
  
  # -test.benchmem
  # 统计内存分配次数
  ```

```shell
go test -test.bench=. -test.count=1 -test.benchmem .
```

##### 1.2.1. pprof

```shell
# document
# https://zhuanlan.zhihu.com/p/396363069
```

- graphviz

  ```shell
  # download
  # https://graphviz.org/download
  ```

- ###### benchmark

  ```shell
  go test -test.bench=. -memprofile=mem.out .
  go tool pprof -http=:8080 mem.out
  ```

### 2. go build

- args

  ```shell
  # -o <output> 执行生成的可执行文件的名称和路径
  # -i       显示相关的依赖包，但不构建可执行文件
  # -v       显示构建过程中的详细信息，包括编译的文件和依赖的包
  # -x       显示构建过程中的详细信息，包括执行的编译命令
  # -race    启用数据竞争检测，用于检查并发程序中的数据竞争问题
  # -ldflags 为链接器提供额外的标志参数，如设置程序的版本信息等
  ```

- goos

  ```shell
  # windows
  CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build .
  
  # linux
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build .
  
  # max
  CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build .
  ```

- -ldflags

  ```shell
  # 减小编译后体积
  go build -ldflags "-s -w" -o main main.go
  # -s 忽略符号表和调试信息
  # -w 忽略 DWARFv3 调试信息，使用该选项后将无法使用 gdb 进行调试
  
  # 使用当前时间作为版本号
  go build -ldflags "-s -w -X main.version=$(date +'%Y%m%d%H%M%S')" -o main main.go
  # 使用当前 git-hash 作为版本号
  go build -ldflags "-s -w -X main.version=$(git rev-parse --short HEAD)" -o main main.go
  ```

### 3. tools

#### 3.1. golds

```shell
# 文档查看
go install go101.org/golds@latest

# use
# `golds std`: 查看标准库文档 
```

#### 3.2. goimports

```shell
# 代码格式化工具
go install golang.org/x/tools/cmd/goimports@latest

# use
goimports -w [filepath]
```

### 9. external

#### github.com/urfave/cli

```shell
# go get
go get -u github.com/urfave/cli/v2
```

#### github.com/spf13/cobra

```shell
# go get
go get -u github.com/spf13/cobra
```

```go
package main

import (
	"errors"

	"github.com/spf13/cobra"
)

// validate .
func validate(args []string) error {
	if len(args) == 0 {
		return errors.New("args cannot be empty")
	}
	return nil
}

func main() {
	app := &cobra.Command{
		Use:   "root",         // Usage
		Short: "root command", // command 说明
		// 在 -h 显示的 Usage 中，不自动在 Use 中追加 [flags]，可用于自定义 Usage 显示
		// eg:
		//   flase: root [flags]
		//   true: root
		// DisableFlagsInUseLine: true,
		// Execute 执行失败后，不打印 help 信息
		SilenceUsage: true,
		// Execute 执行失败后，不打印 error 信息
		SilenceErrors: true,
		// 不建议直接使用 cobra.MinimumNArgs(1) 解析 args。因为不可对 args 进行判断，以及进行必要的说明
		// 推荐在 RunE 中实现 validate(args []string) error 进行输入参数判断
		// Args:  cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := validate(args); err != nil {
				return err
			}
			return nil
		},
	}

	sub := &cobra.Command{
		Use:   "sub",
		Short: "sub command",
		RunE: func(cmd *cobra.Command, args []string) error {
			return nil
		},
	}

	// 子命令添加 flags
	sub.Flags().StringP("field", "f", "default", "input field")

	// 添加子命令
	app.AddCommand(sub)

	// 执行命令
	if err := app.Execute(); err != nil {
		// Command 中使用 RunE 时，error 会自动打印一次
		// log.Fatal(err)
	}
}

```

#### github.com/qax-os/excelize

```shell
# go get
go get -u github.com/xuri/excelize/v2

# document
https://xuri.me/excelize/zh-hans
```

---

## nodejs

```shell
wget -c https://nodejs.org/dist/v16.5.0/node-v16.5.0-linux-x64.tar.xz
sudo tar -x -C /usr/local/ -f node-v16.5.0-linux-x64.tar.xz
rm -rf node-v16.5.0-linux-x64.tar.xz

mv /usr/local/node-v16.5.0-linux-x64 /usr/local/nodejs
sudo ln -s /usr/local/nodejs/bin/npm /usr/local/bin/
sudo ln -s /usr/local/nodejs/bin/node /usr/local/bin/

# 换源(taobao)
npm config set registry https://registry.npmmirror.com/

# pnpm
sudo npm install -g pnpm
sudo ln -s /usr/local/node/bin/pnpm /usr/local/bin/
```

---

## python

```shell
# 依赖
sudo apt install -y wget build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev

# Python3
ver=3.12.0
wget -c https://www.python.org/ftp/python/$ver/Python-$ver.tgz && tar -xvf Python-$ver.tgz
cd Python-$ver
./configure --enable-optimizations --prefix=/usr/local/python3
sudo make -j 2
sudo make altinstall

# 软链接
# 删除旧的 python、python3 软链
for i in pip pip3 python python3; do if [[ -f "/usr/bin/$i" ]]; then sudo rm -rf /usr/bin/$i; fi; done
# pip、python
sudo ln -s /usr/local/python3/bin/python3.12 /usr/bin/python
sudo ln -s /usr/local/python3/bin/pip3.12 /usr/bin/pip

# pip 换源
# pypi.org
pip config set global.index-url https://pypi.org/simple
pip config set global.trusted-host pypi.org
# douban
pip config set global.index-url https://pypi.douban.com/simple
pip config set global.trusted-host pypi.douban.com

# 第三方依赖
black ····· 代码格式化工具
pymysql ··· 操作 MySQL
requests ·· HTTP 封装

# PYTHONPATH
cat >> ~/.zshrc << EOF
export PYTHONPATH = "$HOME/.local/lib/python3.x/site-packages"
EOF
```

## ————————

## tips

### nats

```shell
# 1. nats 集群负载的是客户端，而不是 nats 请求，所以若是客户端并发过高，还是会导致节点高负载；
# 2. nats 集群节点宕机后，有自动重连机制，会以相同的客户端 ID 连接其他可用节点（但是需要在本地代码内手动重试），
#    待节点恢复后，客户端会自动重启至之前节点；
```

