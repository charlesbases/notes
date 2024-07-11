## 空白区域不可点击

```shell
# 解决方案使用新的输入系统

# 第一步
# 导入包 "Unity/Package Manager/Unity Registry/Input System"

# 第二步
# Hierarchy/Event System/Inspector/Input System UI Input Model(Script)/Deselect On Backgrond/Disable
```

---

## NOTE

```
1. 继承 MonoBehaviour 的类不要在构造函数中初始化任何变量. 

* 在 Unity 场景中, 会多次调用构造参数
* 也不要在类声明中直接初始化变量, 同样会执行多次
* 建议所有初始化语句放在 Awake 或 Start 方法中执行
```

```
2. 不要在任何类的构造函数中调用 Unity 方法 (包括非 MonoBehaviour 类)
```

