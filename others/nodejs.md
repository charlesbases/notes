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