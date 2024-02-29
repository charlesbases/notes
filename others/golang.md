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

---

```shell
# golds 文档查看
go install go101.org/golds@latest
# `golds std`: 查看标准库文档 
```

```shell
# 运算符优先级
# '.' > '&' = '*' > '--' = '++'
#   p := &t.x <=> p := &(t.x)
#   *p++      <=> (*p)++
```

---

## 1. test

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

### 1.1. cover

```shell
# 简略信息
go test -cover

# 详细信息
go test -coverprofile=cover.out && go tool cover -html=cover.out -o cover.html
```

### 1.2. benchmark

- ##### args

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

#### 1.2.1. pprof

```http
https://zhuanlan.zhihu.com/p/396363069
```

- ##### graphviz

  ```http
  https://graphviz.org/download
  ```

- ##### benchmark

  ```shell
  go test -test.bench=. -memprofile=mem.out .
  go tool pprof -http=:8080 mem.out
  ```

---

## 2. build

```shell
# -o <output> 执行生成的可执行文件的名称和路径
# -i       显示相关的依赖包，但不构建可执行文件
# -v       显示构建过程中的详细信息，包括编译的文件和依赖的包
# -x       显示构建过程中的详细信息，包括执行的编译命令
# -race    启用数据竞争检测，用于检查并发程序中的数据竞争问题
# -ldflags 为链接器提供额外的标志参数，如设置程序的版本信息等
```

- ##### goos

  ```shell
  # windows
  CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build .

  # linux
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build .

  # max
  CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build .
  ```

- ##### -ldflags

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

---

## 3. tools

### 3.1. goimports

```shell
go install golang.org/x/tools/cmd/goimports@latest

# use
goimports -w [filepath]
```

## ——————————

## github.com/urfave/cli

```shell
go get -u github.com/urfave/cli/v2
```

```go

```

---

## github.com/spf13/cobra

```shell
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

---

