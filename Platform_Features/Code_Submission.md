# Platform Features — Code Submission

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 版本管理拓扑 | Google repo聚合多仓,单一manifest锁定所有子项目 | 每层独立git仓库,无统一manifest |
| 评审系统 | Gerrit(`review-android.quicinc.com`,Change-Id/Code-Review) | GitHub风格PR+DCO(`git commit -s`)+`probot/dco`自动校验 |
| 许可证合规检查 | 未见项目自身自动化工具 | `meta-audioreach/repolint.json`强制SPDX/Copyright头检查 |
| CI定义 | 未见项目自身CI配置 | 各层`ci/`目录kas矩阵+`meta-security`/`meta-updater`独立`.gitlab-ci.yml`+`yocto-patchreview.sh` |
| 贡献指南 | 无 | 各开源层均有CONTRIBUTING.md/adoc,要求DCO+测试门槛 |
| 提交追溯 | `summary_log.txt`(Gerrit Change-Id清单) | 分散在各层git历史 |

## 关键差异

- 从Gerrit强评审模式迁移到PR+DCO+外部kas CI,评审强制性依赖外部CI系统实际接入情况。
- `yocto-patchreview.sh`检测Signed-off-by和upstream-status标记,与DCO共同构成双重把关。

## 待确认

- 各层`ci/*.yml`实际由哪个外部CI系统触发,是否已作为生产环境的merge gate。
- `repolint.json`检查失败是否真正阻断合并。
- 是否所有开源层都要求DCO,内部专有层评审流程是否不同。
