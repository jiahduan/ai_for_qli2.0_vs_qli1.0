# Code Composition — Branch Management

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 常见状态 | detached HEAD(repo sync标准行为) | 具名长期分支(wrynose/master/2.18) |
| 分支语义体现方式 | commit message/tag/manifest属性(如`LA.VENDOR.17.6.0.AU287`) | git branch本身 |
| 特殊分支 | 无 | `patched-<sha>`(kas对打了本地补丁的仓库自动创建的临时分支,非上游真实分支) |
| 版本锁定方式 | tag+manifest revision | `base.lock.yml`集中锁定+各层长期分支滚动更新 |

## 关键差异

- QLI1.0 detached HEAD模式下直接提交易造成孤儿提交,须走repo start/upload流程;QLI2.0具名分支更贴近标准git工作流,但`patched-*`分支容易被误认为真实功能分支而误操作。
- 同一分支名在QLI2.0不同时间点检出代码不同,复现性依赖lock文件是否被严格使用。

## 待确认

- QLI2.0团队是否统一要求"改动先提PR到具名分支,再更新lock文件"的分支保护规则。
