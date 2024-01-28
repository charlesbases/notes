## 1. 说明

- ##### 名词解释

  ```shell
  # dc (domain component)
  # 一般为公司名。eg: dc=google,dc=com

  # ou (organization unit)
  # 组织单元，最高为四级，每级最长32个字符，可以为中文

  # cn (common name)
  # 用户名或者服务器名，最长可以到80个字符，可以为中文

  # dn (distinguished name)
  # 为一条LDAP记录项的名字，有唯一性。eg: dn: "cn=admin,ou=developer,dc=google,dc=com"
  ```

------

## 2. 部署

### 1. kubernetes

```shell
./bash.sh apply -v
```
