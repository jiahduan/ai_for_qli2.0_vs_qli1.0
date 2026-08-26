# Code Composition — Source Code Structure

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 顶层src/汇聚目录 | 存在,37个子目录(audio/bluetooth/display/kernel-6.18/OTA/security/wlan等) | 不存在 |
| 源码获取模式 | 预取(pre-fetch):repo sync一次性拉到统一src/目录树 | 按需拉取(recipe-driven fetch):每个recipe自带`SRC_URI`/`SRCREV` |
| 源码可见性 | 集中可一次性盘点审计 | 分散在各层recipe中 |

## 关键差异

- 从"集中汇聚"到"按recipe拉取"是标准Yocto惯例的回归,提升可复用性和上游可贡献性。
- 出口管制/合规审查方式需从"看src目录"转为"遍历所有层的recipe SRC_URI",复杂度上升。

## 待确认

- `src/security/*`、`src/mdm-ss-mgr`、`src/OTA`等专有闭源模块在QLI2.0是被开源化收编,还是仍以私有方式存在于未展示的仓库(详见Code_Composition/Layer_Architecture.md)。
