## C#

### convention

```shell
# 文件：PascalCase，通常与文件中主要的类或接口的名称相匹配
# 文件夹：PascalCase，文件夹名称应该反映其内容或功能
```

```shell
# 命名空间（Namespace）：PascalCase
# 类（Class）：PascalCase，通常是名词或名词短语，表示一个具体的事物或概念
# 方法（Methods）：PascalCase，通常为动词或动词短语
# 属性（Properties）：PascalCase，通常为名词或名词短语，表示对象的特性或状态
# 事件（Events）：PascalCase，通常以 'On' 开头，后面跟上一个表示事件的名词或名词短语
# 字段（Fields）：camelCase，通常是私有的，并不建议直接暴露字段，如果需要公开，应该通过属性来访问
# 常量（Constants）：PascalCase，并且所有字母大写，可以使用 '_' 分割单词
# 局部变量（Local Variables）：camelCase
# 参数（Parameters）：camelCase
# 接口（Interfaces）：PascalCase，通常以 'I' 开头，后面跟上一个名词或名词短语，表示一种规范或契约
# 枚举（Enums）：PascalCase
# 枚举项（Enum Items）PascalCase
# 泛型类型参数（Type Parameters in Generics）：通常使用单个大写字母，如 'T' 表示泛型类型， 'V' 表示值的类型
# 异步方法（Async Methods）：PascalCase，通常以 'Async' 结尾
```



---

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
# golang 设计与实现
https://draveness.me/golang
```



### download

```shell
# download
wget -c https://golang.google.cn/dl/go1.20.10.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local

# environment
cat >> ~/.zshrc << EOF
export GOHONE="/usr/local/go"
export GOPATH="/opt/go"
export GOPROXY="https://goproxy.io,direct"
export GOSUMDB="off"
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

```text
.
├── api # openapi/swagger 规范，json 示例文件
│   └── swgger.json
├── build # 编译脚本
│   ├── build.sh
│   └── ci # ci 工具集成脚本
│       └── jenkins.sh
├── cmd
│   └── app
│       └── app.go
├── config # 配置文件
│   └── app.yaml
├── deployment # 系统和容器编排部署配置和模板
├── docs # 文档
│   └── api.md
├── internal
├── pkg
├── scripts
├── test 
├── thirdparty
└── web # 静态 web 资源
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

    // flags
    
	// 将选项绑定到指定类型的指针变量上
	var enableJson bool
	sub.PersistentFlags().BoolVarP(&enableJson, "json", "j", false, "Enable json output")

	// 解析选项，并返回一个变量指针
	_ = sub.PersistentFlags().BoolP("verbose", "v", false, "Enable verbose output")

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

