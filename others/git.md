## ★ .gitignore

```shell
# 忽略所有文件和文件夹，包括隐藏的文件和文件夹 
**

# 排除 Scripts 文件夹本身
!Scripts/
# 排除 Scripts 文件夹内的所有文件和子文件夹
!Scripts/**
```



---

## ★ [gitconfig](.share/gitconfig)

```shell
# 优先级
本地仓库配置 (.git/config) > 全局配置 (~/.gitconfig) > 系统配置 (/etc/gitconfig)
```



---

## ★ subcommand

---

### ☆ branch

```shell
# 分支关联
git branch --set-upstream-to=<remote-branch> <local-branch>
```

- 删除

  ```shell
  # 本地分支
  git branch -d branch
  
  # 远程分支
  git push origin -d branch
  
  #
  b=branch; git push origin --delete $b && git branch -d $b
  ```

  

---

### ☆ clone

```shell
# git pull 下载小文件时，禁用 gzip  来提高下载速度
git clone -c core.compression=0 <repo.url>

# '-c core.compression=0' 禁用 gzip
# '-b <branch>'     将新创建的 HEAD 指向指定分支
# '--single-branch' 只拉取指定分支
# '--depth 1'       只拉取最新的提交记录, 暗含 '--single-branch'
# '--no-tags'       不克隆任何标签
# ''
git clone -b master --single-branch --depth 1 -c core.compression=0 <repo.url>
```



---

### ☆ filter-branch

```shell
# 删除大文件
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch <filename>' --prune-empty --tag-name-filter cat -- --all

# 清楚 git 历史
git reflog expire --expire=now --all && git gc --prune=now --aggressice

git push -f
```



---

### ☆ merge

```shell
# 参数
#  --continue: 继续变基
#  --abort: 撤销变基, 恢复之前的代码
#  --skip: 跳过提交
```

- merge

- rebase

  ```shell
  # 第一步：解决代码冲突
  
  # 第二步：添加变动文件到暂存区
  git add .
  
  # 第三步：提交文件变动
  git commit --amend
  
  # 第四步：继续变基
  git rebase --continue
  
  # 第五步：提交至远程仓库
  git push origin HEAD:[branch] --force
  ```

---

### ☆ pull

```shell

```



---

### ☆ push

```shell
# 推送到远程分支
git push origin <local-branch>:<remote-branch>
```



---

### ☆ reset

```shell
git reset [option] <commit>

# option
#   soft:  将当前分支的 HEAD 移动到指定的 commit，但不会改变暂存区和工作目录中的文件。
#   mixed: 默认选项。该命令会重置暂存区，使其与 commit 保持一致，但是不会改变工作目录的文件。
#   hard:  该命令会重置暂存区和工作目录，使其与 commit 保持一致，所有未提交的更改都会被丢弃
```



---

### ☆ rev-parse

```shell
# 查看当前分支名
git rev-parse --abbrev-ref HEAD

# 查看当前分支 hash
git rev-parse HEAD

# 查看当前分支 hash(short)
git rev-parse --short HEAD
```



---

### ☆ submodule

- 添加

  ```shell
  git submodule add url [path/module]
  ```

  

- 更新

  ```
  git submodule update --remote
  ```

  

- 删除

  ```
  # 删除 git 缓存
  git rm --cached [module]
  
  # 删除 .gitmodules 子模块信息
  [submodule "module"]
  
  # 删除 .git/config 子模块信息
  [submodule "module"]
  
  # 删除 .git 子模块文件
  rm -rf .git/modules/[model]
  ```

  

---

### ☆ tag

- 添加

  ```shell
  # new tag
  git tag -a "v1.0.0" -m "release v1.0.0"
  
  # push
  git push --tags
  
  #
  v=v1.0.0; git tag -a "$v" -m "release $v" && git push --tags
  ```

  

- 删除

  ```shell
  # 删除本地
  git tag -d v1.0.0
  
  # 删除远程
  git push origin :refs/tags/v1.0.0
  
  #
  v=v1.0.0; git tag -d $v && git push origin :refs/tags/$v
  ```

  

---

## ★ github

- ssh: connect to host github.com port 22: Connection timed out

  ```shell
  # 使用 443 端口
  
  cat >> ~/.ssh/config << EOF
  Host github.com
    Port 443
    Hostname ssh.github.com
    ServerAliveInterval 120
    ServerAliveCountMax 720
    # IdentityFile ~/.ssh/id_rsa
    PreferredAuthentications publickey
  EOF
  ```

  

- ssh: connect to host ssh.github.com port 443: Connection timed out

  ```shell
  # 添加 hosts 映射
  # https://www.ipaddress.com/website/ssh.github.com/
  #   搜索 "DNS Resource Records"
  ```

  

- githubusercontent

  ```shell
  # 下载 github 项目文件
  wget -O - https://raw.githubusercontent.com/<user>/<repo>/<branch>/<filepath> > <file>
  ```

  

---

## ★ git-for-windows

```shell
# git 启动时会扫描临时文件夹，启动慢时删除临时文件夹即可
rm -rf ~/AppData/Local/Temp/* &>/dev/null
```

- ##### inputrc

  ```shell
  # git-bash 删除键闪屏
  sed -i -s 's/set bell-style visible/set bell-style none/g' inputrc
  
  # 历史记录前缀搜索
  cat >> inputrc << EOF
  "\e[A": history-search-backward
  "\e[B": history-search-forward
  EOF
  ```

- ##### bash.bashrc

  ```shell
  # 将每个 session 的历史记录行追加到历史文件中
  echo "PROMPT_COMMAND='history -a'" >> bash.bashrc
  ```



- ##### profile.d

  - [git-prompt.sh](.share/scripts/git-prompt.sh)

## ——————
