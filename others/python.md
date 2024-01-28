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