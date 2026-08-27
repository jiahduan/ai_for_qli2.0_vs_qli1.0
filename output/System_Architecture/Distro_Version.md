# System Architecture — Distro Version

## 对比范围

- **覆盖**:本文比较两侧"distro层"(策略/镜像配置层本身,非发行版版本号)的变体管理方式、DISTRO_FEATURES专有追加、发行版级构建变量、SELinux启用方式(开关机制本身)、OTA方案选型(选型事实本身)、IMAGE_CLASSES/FSTYPES,以及QLI1.0多产品线变体在QLI2.0的承接情况核实:
  - 变体文件矩阵与产品线承接情况:
    - QLI1.0:`poky/meta-qti-distro`(30个`qti-distro-{base,fullstack,camerastack,xr,vnm,rb,host}-{debug,perf,user}[-nosecurity][-noselinux][-virtualization].conf`组合)、`qti-distro-base.inc`
    - QLI2.0:`meta-qcom-distro`(`qcom-distro.conf`/`qcom-distro-selinux.conf`/`qcom-distro-sota.conf`/`qcom-distro-catchall.conf`)、`qcom-base.inc`;`rb`(robotics)产品线承接:`meta-qcom-robotics-sdk`(`qcom-robotics-distro-{catchall,selinux,sota}.conf`,4-conf模式原样复制);`camerastack`/`xr`/`vnm`/`host`四条线已遍历`meta-qcom-distro/ci/`全部35个yml及`meta-qcom/ci/`确认零命中(尚未规划)
  - DISTRO_FEATURES专有追加对比:QLI1.0`qti-distro-base.inc`(`eabi ipv6 ipv4 largefile thumb-interwork xattr selinux emmc-boot qti-wifi qti-ab-boot`) vs QLI2.0`qcom-base.inc`(`efi glvnd kvm minidebuginfo opencl overlayfs pam pni-names polkit security tpm2 virtualization wifi x11`)
  - 发行版级构建变量:PACKAGE_CLASSES(QLI1.0未覆盖默认`package_rpm`继承`poky.conf` vs QLI2.0`qcom-distro.conf`显式声明`package_rpm`)、TCLIBC默认值(两侧均glibc;picolibc新增选项细节归Toolchain.md)、GCCVERSION锁定方式(QLI1.0`qti-distro-base.inc`二次锁定`13.4%` vs QLI2.0未二次锁定继承`tcmode-default.inc`的`15.%`)
  - SELinux启用方式:QLI1.0写死在`qti-distro-base.inc`默认开 vs QLI2.0拆分独立`qcom-distro-selinux.conf` overlay按需启用(`DEFAULT_ENFORCING ?= "enforcing"`)
  - OTA方案选型:QLI1.0`qti-ab-boot`(A/B分区) vs QLI2.0`qcom-distro-sota`(OSTree+aktualizr)
  - IMAGE_CLASSES/FSTYPES:QLI2.0`qcom-base.inc`新增`IMAGE_CLASSES += "image_types_qcom"`、`IMAGE_FSTYPES += "qcomflash"`(QLI1.0未特别声明)
  - `meta-qcom-distro`演进活跃度核实:git创建(2023-07-18)/首次实质提交(2024-01-25)至今582个commit,及4-conf模式已在`meta-qcom-robotics-sdk`原样复制的判断
- **明确排除**:
  - DISTRO_VERSION/DISTRO_CODENAME/LAYERSERIES_COMPAT等Yocto release版本号与版本对齐分析 ——见[Yocto](Yocto.md)
  - systemd具体机制/service单元/补丁去向 ——见[systemd_](../Boot_Architecture/systemd_.md)
  - SELinux策略体系细节(refpolicy基线、策略规则数量、机型策略目录对应关系) ——见[Security_Architecture](Security_Architecture.md)
  - OTA具体实现机制与镜像完整性校验(OSTree/aktualizr工作原理、dm-verity/AVB) ——见[OTA_Mechanism](../Platform_Features/OTA_Mechanism.md)
  - kas yaml拼装机制细节与CI片段结构 ——见[Build_Tools](../Build_Architecture/Build_Tools.md)
  - TCLIBC可选项细节(picolibc新增能力等) ——见[Toolchain](../Build_Architecture/Toolchain.md)
- **待定边界**:(无,已核实与Yocto/systemd_/Security_Architecture/OTA_Mechanism/Build_Tools/Toolchain/Layer_Architecture/Bitbake_Version等潜在交叉主题的边界:版本号/release对齐归Yocto,systemd机制归systemd_,SELinux策略细节归Security_Architecture,OTA实现细节归OTA_Mechanism,kas细节归Build_Tools,TCLIBC/picolibc细节归Toolchain;PACKAGE_CLASSES与GCCVERSION锁定方式这一"distro层选型事实"仍由本文承载——Bitbake_Version.md已明确说明PACKAGE_CLASSES差异"是distro层选型差异,与bitbake版本无关"、Toolchain.md虽也列出GCCVERSION锁定行但落脚于toolchain选型视角,两文档均未反向认领,不构成悬空或双认领冲突;Layer_Architecture.md的`meta-qti-distro`→`meta-qcom-distro`映射属于全量59→21层清单的一行,不与本文逐条对比范围冲突,未纳入排除)

## 对比总览

| 维度 | QLI1.0(`meta-qti-distro`) | QLI2.0(`meta-qcom-distro`) |
|---|---|---|
| 变体文件数量 | 30个(`qti-distro-{base,fullstack,camerastack,xr,vnm,rb,host}-{debug,perf,user}[-nosecurity][-noselinux][-virtualization].conf`组合) | 4个:`qcom-distro.conf`(require `qcom-base.inc`)、`qcom-distro-selinux.conf`、`qcom-distro-sota.conf`、`qcom-distro-catchall.conf` |
| DISTRO_FEATURES专有追加 | `eabi ipv6 ipv4 largefile thumb-interwork xattr selinux emmc-boot qti-wifi qti-ab-boot`(`qti-distro-base.inc`) | `efi glvnd kvm minidebuginfo opencl overlayfs pam pni-names polkit security tpm2 virtualization wifi x11`(`qcom-base.inc`) |
| INIT_MANAGER | systemd | systemd |
| PACKAGE_CLASSES | 未覆盖,默认`package_rpm`(继承poky.conf) | 显式声明`PACKAGE_CLASSES="package_rpm"` |
| TCLIBC | 未覆盖,默认glibc | 未覆盖,默认glibc(oe-core新增picolibc选项,详见output/Build_Architecture/Toolchain.md) |
| GCC版本锁定 | distro层二次锁定`GCCVERSION="13.4%"` | 未二次锁定,继承`tcmode-default.inc`的`15.%` |
| SELinux开关方式 | 写死在base.inc默认开(详见Security_Architecture.md) | 拆分为独立`qcom-distro-selinux.conf` overlay,按需启用,`DEFAULT_ENFORCING ?= "enforcing"` |
| OTA方案 | `qti-ab-boot`(A/B分区,非ostree) | `qcom-distro-sota`(OSTree+aktualizr,详见output/Platform_Features/OTA_Mechanism.md) |
| 变体管理方式 | 静态conf文件矩阵(30个) | kas yaml片段拼装(`ci/debug.yml`、`ci/performance.yml`等,详见output/Build_Architecture/Build_Tools.md) |
| IMAGE_CLASSES/FSTYPES | 未特别声明 | `IMAGE_CLASSES += "image_types_qcom"`,`IMAGE_FSTYPES += "qcomflash"` |

## 关键差异

- 两侧DISTRO_FEATURES专有项完全不重叠——QLI1.0的`qti-wifi`、`qti-ab-boot`、`emmc-boot`在QLI2.0不存在;QLI2.0新增的`tpm2`、`kvm`、`overlayfs`、`polkit`也是QLI1.0未涉及的能力面,依赖这些feature做条件编译的recipe迁移时都要重新审视。
- 配置管理方式由"静态conf文件矩阵"整体切换为"kas yaml片段拼装",是构建配置管理方法论的整体转变。
- OTA方案路线不同,两者升级机制、分区布局、镜像格式均不兼容。
- QLI1.0的30个变体产品线里,只有`rb`(robotics)在QLI2.0已有明确承接——独立层`meta-qcom-robotics-sdk`+专属`qcom-robotics-distro-{catchall,selinux,sota}.conf`+专属ci/LAVA测试;`camerastack`/`xr`/`vnm`/`host`四条线逐一核对`meta-qcom-distro/ci/`(35个yml)及`meta-qcom/ci/`均未找到对应kas片段,确认目前尚未规划。
- `meta-qcom-distro`自2023-07-18创建、2024-01-25首次实质提交至今已有582个commit,持续演进超2年;"base+selinux开关+sota开关+catchall"这套4-conf模式已在`meta-qcom-robotics-sdk`层原样复制一遍,是刻意设计的可复制最小化distro范式,不是尚未展开的精简阶段。

## 影响与风险

- QLI1.0的30个变体里,只有`rb`(robotics)在QLI2.0有明确承接;`camerastack`/`xr`/`vnm`/`host`四条产品线目前连最基础的distro conf骨架都不存在(`meta-qcom-distro/ci/`35个yml及`meta-qcom/ci/`均未找到对应片段,详见"关键差异")。这些产品线若要迁移到QLI2.0,现在不是"改一下配置"就能开始,而是要先由产品/系统架构团队拍板是否、何时在这些产品线上落地QLI2.0——已同步补充进README《待拍板事项汇总》。
- GCC版本锁定方式改变(QLI1.0在distro层二次锁定`GCCVERSION="13.4%"`,QLI2.0未二次锁定、直接继承`tcmode-default.inc`的`15.%`)意味着两侧编译器版本不再受同一套distro层策略统一管控;任何下游流程如果依赖"改distro层GCCVERSION就能锁定全量构建的编译器版本"这一QLI1.0习惯,迁移到QLI2.0后需要改为直接管理`tcmode-default.inc`或在machine/recipe级override,否则会误以为版本仍受distro层控制。
- SELinux启用方式从"写死默认开"变为"按需选配的独立overlay conf",直接决定了QLI2.0当前实际构建(`qcom-robotics-ros2-jazzy`)默认不启用SELinux这一事实,与Security_Architecture.md的风险评级(P1)是同一枚硬币的两面,规模差距与补齐计划以该文档结论为准,此处不重复评级。
- OTA方案(`qti-ab-boot`分区式 vs `qcom-distro-sota`的OSTree+aktualizr)不兼容,升级机制/分区布局/镜像格式三者均需重新设计,是README《待拍板事项汇总》里P0级"OTA终态方案"决策的直接源头证据之一,决策未落地前无法评估其余产品线迁移的分区/镜像兼容性。
