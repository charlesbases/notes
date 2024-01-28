## 1. tag

- ##### 添加

  ```shell
  # new tag
  git tag -a "v1.0.0" -m "release v1.0.0"

  # push
  git push --tags

  #
  v=v1.0.0; git tag -a "$v" -m "release $v" && git push --tags
  ```

- ##### 删除

  ```shell
  # 删除本地
  git tag -d v1.0.0

  # 删除远程
  git push origin :refs/tags/v1.0.0

  #
  v=v1.0.0; git tag -d $v && git push origin :refs/tags/$v
  ```

---

## 2. pull

```shell
# git pull 下载小文件时，禁用 gzip  来提高下载速度
git clone -c core.compression=0 <repo.url>

# '-c core.compression=0' 禁用 gzip
# '-b master'
# '--single-branch' 只拉取指定分支
# '--depth 1'       只拉取最新的提交记录
```

---

## 3. push

```shell
# 推送到远程分支
git push origin <local-branch>:<remote-branch>
```

---

## 4. branch

```shell
# 分支关联
git branch --set-upstream-to=<remote-branch> <local-branch>
```

- ##### 删除

  ```shell
  # 本地分支
  git branch -d branch

  # 远程分支
  git push origin -d branch

  #
  b=branch; git push origin --delete $b && git branch -d $b
  ```

---

## 5. submodule

- ##### 添加

  ```shell
  git submodule add url [path/module]
  ```

- ##### 更新

  ```shell
  git submodule update --remote
  ```

- ##### 删除

  ```shell
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

## 6. [gitconfig](.share/gitconfig)

---

## 7. completion

```shell
```



---

## 8. filter-branch

```shell
# 删除大文件
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch <filename>' --prune-empty --tag-name-filter cat -- --all

# 清楚 git 历史
git reflog expire --expire=now --all && git gc --prune=now --aggressice

git push -f
```

---

## 9. git-for-windows

```shell
# ssh: connect to host github.com port 22: Connection timed out

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



```shell
# git 启动时会扫描临时文件夹，启动慢时删除临时文件夹即可
rm -rf ~/AppData/Local/Temp/* &>/dev/null
```

- ##### vimrc

  ```shell

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

---

## 10. githubusercontent

```shell
# 下载 github 项目文件
wget -O - https://raw.githubusercontent/<user>/<repo>/<branch>/<filepath> > <file>
```

## ——————

## others

```shell
# 查看当前分支名
git rev-parse --abbrev-ref HEAD

# 查看当前分支 hash
git rev-parse HEAD

# 查看当前分支 hash(short)
git rev-parse --short HEAD
```
