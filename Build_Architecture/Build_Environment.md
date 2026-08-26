# Build Architecture — Build Environment

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 环境搭建入口 | `setup-environment` → `poky/qti-conf/set_bb_env.sh`(457行) | `kas-container build <yaml>` |
| Host依赖 | bash、whiptail/dialog、内网镜像访问 | Docker/Podman + kas-container脚本 |
| Python最低版本 | 3.8.0 | 3.9 |
| 磁盘/内存要求 | 90GB / 8GB(Yocto 5.0标准) | 未见独立文档 |
| 层版本锁定方式 | repo manifest revision | kas `base.lock.yml`精确commit锁定 |
| 内网基础设施耦合 | 脚本硬编码Qualcomm内网IP段/mirror域名 | 无内网耦合痕迹,面向公开GitHub生态 |
| 补丁注入机制 | `apply_poky_patches()`每次进环境对poky打专有补丁 | 无对应机制 |

## 关键差异

- 从"clone大manifest+setup-environment"整体切换为"kas-container+yaml组合"。
- Python 3.9门槛可能影响较老host环境。

## 影响与风险

- kas容器化引入Docker/Podman权限依赖,在严格内网安全策略环境可能是新障碍。
- `apply_poky_patches`是隐藏的构建期变更点,需确认对应补丁是否已上游化。

## 待确认

- 内部是否有类似set_bb_env.sh的kas封装脚本。
- `qti-conf/patches/series`补丁清单内容及QLI2.0等价实现。
- 原生(非容器)构建的host完整依赖包列表。
