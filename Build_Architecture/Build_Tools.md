# Build Architecture — Build Tools (kas)

## 对比总览

| 维度 | QLI1.0(repo) | QLI2.0(kas) |
|---|---|---|
| 环境搭建命令 | `repo init/sync` + `source setup-environment`(两步以上) | `kas build <machine>.yml:<distro>.yml`(一步) |
| 配置来源 | `.repo/manifests/*.xml`,手写local.conf,`get_bblayers.py`运行时扫描目录生成bblayers.conf | `ci/*.yml`分层声明,`base.lock.yml`锁定精确commit,自动生成bblayers.conf/local.conf |
| 主入口层 | 无(内网manifest+私有脚本) | `meta-qcom/ci/*.yml`、`meta-qcom-distro/ci/*.yml`(46+36个yml) |
| 容器化支持 | 无 | `kas-container`,host仅需Docker/Podman |
| Host前置要求 | 强制`/bin/sh->bash`,需装whiptail/dialog | 无strict shell校验(容器内环境固定) |
| CI集成 | 无原生集成,交互式菜单需环境变量绕过 | ci.yml/world.yml/schemacheck.py与人工命令行同源 |

## 关键差异

- meta-security/kas、meta-updater/kas是上游社区层自带的自测配置(面向qemux86-64仿真机型),非QLI2.0团队主入口,真正的一键构建入口是meta-qcom系列层的`ci/*.yml`。
- kas支持跨仓库补丁声明式打入第三方仓库(详见Code_Composition/Patch_Management.md)。

## 影响与风险

- repo→kas迁移需要构建入口、CI脚本、开发者环境搭建方式全面更新。
- 团队需理解kas多文件include合并顺序,否则排障困难。

## 待确认

- 官方推荐构建入口是`meta-qcom/ci`还是`meta-qcom-distro/ci`。
- QLI1.0是否有迁移到kas的计划,或认为repo在多SoC/多manifest场景有不可替代优势。
