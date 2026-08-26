# System Architecture — Distro Version

## 对比总览

| 维度 | QLI1.0(`meta-qti-distro`) | QLI2.0(`meta-qcom-distro`) |
|---|---|---|
| 变体文件数量 | 30个(`{base,fullstack,camerastack,xr,vnm,rb,host}×{debug,perf,user}`组合) | 4个(`qcom-distro`/`-selinux`/`-sota`/`-catchall`) |
| DISTRO_FEATURES专有项 | `eabi ipv6 ipv4 largefile thumb-interwork xattr selinux emmc-boot qti-wifi qti-ab-boot` | `efi glvnd kvm minidebuginfo opencl overlayfs pam pni-names polkit security tpm2 virtualization wifi x11` |
| INIT_MANAGER | systemd | systemd |
| GCC版本锁定 | distro层二次锁定`13.4%` | 未二次锁定,继承oe-core默认 |
| SELinux开关方式 | 写死在base.inc默认开 | 拆分为独立selinux overlay,按需启用 |
| OTA方案 | `qti-ab-boot`(A/B分区) | `qcom-distro-sota`(OSTree/aktualizr) |
| 变体管理方式 | 静态conf文件矩阵 | kas yaml片段拼装 |

## 关键差异

- 两侧DISTRO_FEATURES专有项互不重叠,依赖这些feature做条件编译的recipe迁移时都要重新检查。
- 配置管理方式由"conf文件排列组合"整体切换为"kas yaml片段拼装"(详见Build_Architecture/Build_Tools.md)。

## 待确认

- QLI1.0的30个垂直产品线变体在QLI2.0是否有对应kas片段或路线图。
- `qti-ab-boot`→OSTree的迁移时间表,两条路线是否会并存。
- meta-qcom-distro目前仅4个conf是否代表该层仍处早期阶段。
