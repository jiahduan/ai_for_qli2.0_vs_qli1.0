# System Architecture — Yocto

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| Yocto Release | 5.0.19,codename scarthgap(LTS) | 6.0.1,codename wrynose(LTS) |
| bitbake版本 | 2.8.1 | 2.18.0 |
| 顶层结构 | `poky/`(bitbake+meta+meta-poky一体化) | `bitbake/`与`oe-core/`独立顶层仓库,无poky整合层 |
| 版本跨度 | — | 跨一整个LTS周期,中间styhead/walnascar/whinlatter均被跳过 |
| 官方对照 | Qualcomm Linux 1.x ↔ scarthgap/kirkstone | Qualcomm Linux 2.x ↔ wrynose(meta-qcom-distro/README.md证实) |

## 关键差异

- `LAYERSERIES_COMPAT`由scarthgap变为wrynose,未更新声明的meta-qti-*层原样搬迁会在layer加载阶段直接报错,是强制性迁移门槛。
- 顶层组织从"厂商fork单体poky"转为"上游oe-core+独立BSP/distro层",是架构范式转变而非单纯版本提升。
- 中间版本被跳过,内核/glibc/systemd等recipe升级、bbclass API变化需一次性吸收,回归测试面显著放大。

## 待确认

- 是否有5.1/5.2/5.3阶段性验证记录,还是直接从5.0跳到6.0。
- QLI1.0各meta-qti-*层是否已有wrynose兼容版本。
