# Build Architecture — Kernel Build

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| ko编译框架 | 自定义`inherit linux-kernel-base deploy`+手写do_compile/install/deploy,调用`build_module.sh`(Android DDK) | 标准`inherit module`(module.bbclass+kernel-module-split自动拆包) |
| ko源码获取 | `file://vendor/...`本地目录 | 独立git仓库+SRCREV/tag(kgsl/camx/iris-video/qps615) |
| ko与内核耦合 | `EXT_MODULES`相对路径,强耦合`KERNEL_PLATFORM_PATH`目录结构 | 标准out-of-tree module编译(KERNEL_SRC/STAGING_KERNEL_DIR) |
| dts/dtb变量 | 自定义`TARGET_DTBS`/`KERNEL_SRC_TYPE=soc-repo` | 标准`KERNEL_DEVICETREE` |
| 模块黑名单 | 手工维护`KERNEL_MODULES_BLACKLIST` | 标准`module_conf_<name>`/`KERNEL_MODULE_PROBECONF` |
| Yocto层补丁数 | 6个(dtc编译、lk指令集、ALSA uapi修复等杂项) | 1个(构建脚本修复,非驱动功能) |
| 驱动定制承载方式 | 独立专有源码树整棵拷贝(非patch形式) | 内核仓库commit(`FROMLIST:`488条、`QCLINUX:`41条、`BACKPORT:`102条) |

## 关键差异(含统计纠正)

- 此前统计"src下5083个patch"存在严重误判:约5077个是Bazel模块注册表和u-boot patman测试fixture等第三方噪声文件,与Qualcomm内核驱动无关。真实的QTI Yocto层内核补丁仅6个(详见Code_Composition/Patch_Management.md)。
- 内核驱动定制的吸收方式主要是"上游合并"(FROMLIST标签走LKML)和"内核仓库commit化"(QCLINUX标签),不是靠Yocto层patch文件维护。

## 影响与风险

- QLI1.0整套kernel_platform与Yocto生态(fetcher/SRCREV/sstate)脱节,增量判定粒度粗。
- QLI2.0每个驱动独立SRCREV,升级内核大版本时兼容性验证工作量分散到各仓库。
- `linux-yocto_6.18.bbappend`挂载的DTS patch对真实产品provider `linux-qcom`不生效,是潜在死配置。

## 待确认

- QLI1.0的8个vendor驱动在QLI2.0是否已有`-dlkm`recipe承接,目前仅确认kgsl/camx/iris-video/qps615四个。
- `KERNEL_MODULES_BLACKLIST`黑名单在QLI2.0标准机制下是否一一对应迁移。
- 若要迁移私有内核栈,需重建AOSP预编译clang工具链体系(详见Toolchain.md)。
