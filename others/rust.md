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