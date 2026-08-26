# Code Composition — Code Sync Method

## 对比总览

| 维度 | QLI1.0(repo) | QLI2.0(kas) |
|---|---|---|
| 元数据 | `.repo/manifests/*.xml`(单文件380个project) | 分散在各层`ci/*.yml`,可按machine/distro组合 |
| 命令 | `repo init`+`repo sync -j<N>`(两步,需手动生成bblayers.conf) | `kas checkout`/`kas build`(一步,自动生成bblayers.conf/local.conf) |
| 锁定粒度 | manifest revision字段+local_manifests覆盖 | `base.lock.yml`集中锁定所有层SHA |
| 跨仓补丁 | 无原生机制,依赖cherry-pick/脚本 | kas `patches:`声明式跨仓打补丁 |
| 容器化 | 无 | `kas-container`一行命令 |
| 层清单来源 | 手写在脚本/bblayers.conf模板,与manifest是两套信息 | `repos:`与BBLAYERS同源自动生成 |

## 关键差异

- kas把"拉代码+配层+锁版本"合并为一步,避免repo模式下manifest revision与bblayers.conf手工列表两处维护、易失配的问题。
- 失去repo的local_manifests灵活覆盖能力和Gerrit code-review集成(详见Platform_Features/Code_Submission.md)。

## 待确认

- QLI2.0是否所有产品线都已切换到kas。
- 内部私有层如何通过kas接入私有git服务器与鉴权。
