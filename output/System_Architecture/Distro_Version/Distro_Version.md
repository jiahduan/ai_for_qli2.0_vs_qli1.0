# System Architecture — Distro Version

## Comparison
downstream(maili)(8950-pebble) vs QLI2.0(iq-9075-evk)

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| Distro层物理载体 | `poky/meta-qti-distro` | `meta-qcom-distro` |
| 该机型生效DISTRO | `qti-distro-camerastack-debug`(`auto.conf`实测) | `qcom-distro`(官方CI矩阵`build-yocto.yml`实测) |
| 变体组织方式 | 30个静态`.conf`文件矩阵 | 4个conf(`qcom-distro*.conf`)+kas yaml拼装(35个片段) |
| PACKAGE_CLASSES | 未覆盖,默认`package_rpm` | 显式声明`package_rpm` |
| GCC版本锁定 | distro层二次锁定`13.4%` | 未二次锁定,继承`tcmode-default.inc`的`15.%` |
| SELinux启用方式 | 硬编码在distro conf(`PREFERRED_PROVIDER_virtual/refpolicy="refpolicy-mls-robotics"`),默认开 | 独立overlay`qcom-distro-selinux.conf`,`DEFAULT_ENFORCING?="enforcing"`,按需启用 |
| OTA方案 | `qti-ab-boot`(A/B分区) | `qcom-distro-sota`(OSTree+aktualizr) |
| DISTRO_FEATURES专有项 | `qti-wifi qti-ab-boot emmc-boot`等 | `tpm2 kvm overlayfs polkit`等,与downstream(maili)零重叠 |
| 机型级override | 未见覆盖distro层默认值 | 未见覆盖distro层默认值(已grep两侧machine conf确认) |
| 该产品线在对侧的承接 | pebble所在camerastack线 | 无对应distro conf,仅robotics线有承接(`meta-qcom-robotics-sdk`) |

优势：
• 变体管理由30个静态conf文件矩阵简化为4个conf+kas yaml拼装,可复制性已验证(robotics层原样复制一遍)
• SELinux从硬编码在具体distro conf(如pebble所用camerastack-debug层)改为独立overlay按需启用,配置更灵活
• OTA方案升级为OSTree+aktualizr(原子更新+差分升级),替代A/B分区式方案
• 新增tpm2/kvm/overlayfs/polkit等能力面,安全与虚拟化能力增强
• meta-qcom-distro持续活跃演进(582个commit,2年+),4-conf范式已被robotics产品线原样复用,非草案阶段

影响：
• 8950-pebble所在的camerastack产品线目前在QLI2.0没有对应distro conf(仅robotics线通过meta-qcom-robotics-sdk有承接),迁移前需产品/架构团队拍板时间表
• GCC版本从distro层二次锁定改为不锁定,依赖该机制统一管控编译器版本的下游流程需改造
• DISTRO_FEATURES专有项两侧完全不重叠(qti-wifi/qti-ab-boot/emmc-boot消失),依赖条件编译的recipe需重新审视
• iq-9075-evk等机型未见machine级override覆盖distro层SELinux默认值,当前实际构建默认不启用(P1风险,详见Security_Architecture)
• OTA机制不兼容,升级/分区/镜像三者均需重新设计(P0待决策)


