# Build Architecture — SDK/eSDK

## 对比范围

- **覆盖**:
  - 底层标准SDK类(两侧未改动):`populate_sdk_base.bbclass`、`populate_sdk_ext.bbclass`、`testsdk.bbclass`
  - 二次封装class对比:已重新确认downstream(maili)`poky/meta-qti-bsp/classes/populate_sdk_qti.bbclass`(`inherit populate_sdk_ext`)与QLI2.0`meta-qcom-robotics-sdk/classes/psdk-image.bbclass`(`addtask do_generate_qirp_sdk after do_populate_sdk`)均存在
  - 内核源码是否随SDK交付、工具链附加、devtool集成、产物形态四个维度的两侧对比
  - 覆盖产品线活跃度:已重新`find`确认downstream(maili) 4条产品镜像(`qti-multimedia-image.bb`/`qti-robotics-image.bb`/`qti-xreality-image.bb`/`qti-xreality2-base-image.bb`)均存在;QLI2.0仅`meta-qcom-robotics-sdk`层有自研SDK打包,grep核实其他产品线(multimedia/networking/container-orchestration)无等价TODO/WIP痕迹
  - SDK_VERSION管理对照:已重新核对`meta-qcom-robotics-sdk/classes/psdk-image.bbclass`硬编码`SDK_VERSION = "2.7.0"`与`meta-qcom-distro/conf/distro/include/qcom-base.inc`的`SDK_VERSION = "${DISTRO_VERSION}"`,及各自`git log`独立发布节奏取证
- **明确排除**:(无,已核实:eSDK/SDK打包机制、工具链附加、产品线维护活跃度经排查均为SDK_eSDK自身管辖范围,与HY11/HY22预编译分发、Toolchain主工具链选型等相邻主题未见实质重叠,不构成需要移交的项)
- **待定边界**:(无,已核实:产品线活跃度与SDK_VERSION独立发布节奏均已用git log交叉核实,未发现悬置的归属问题)

## 对比总览

| 维度 | downstream(maili)(扩展eSDK路线) | QLI2.0(标准SDK路线+二次打包) |
|---|---|---|
| 底层标准SDK类 | `populate_sdk_base.bbclass`、`populate_sdk_ext.bbclass`、`testsdk.bbclass`(oe-core/poky原样,未改动) | 相同类,未改动;差异全部在下游二次封装层 |
| 二次封装class | `poky/meta-qti-bsp/classes/populate_sdk_qti.bbclass`,`inherit populate_sdk_ext` | `meta-qcom-robotics-sdk/classes/psdk-image.bbclass`,`addtask do_generate_qirp_sdk after do_populate_sdk` |
| 内核源码是否随SDK交付 | 是:`copy_buildsystem:append()`把`kernel_platform`源码目录、内核defconfig、`PREBUILT_SRC_DIR`预编译产物拷进eSDK的`src/`,写入eSDK自己的bblayers.conf(`WORKSPACE`变量)和local.conf(`PREBUILT_SRC_DIR`) | 否,psdk流程完全没有拷内核源码的逻辑 |
| 工具链附加 | `TOOLCHAIN_HOST_TASK:append`加`nativesdk-protobuf-compiler`、按`QTI_LLVM_VARIANT`条件加`nativesdk-kernel-toolchain`/`nativesdk-llvm-arm-toolchain`;`TOOLCHAIN_TARGET_TASK:append`加`linux-msm-headers-dev`(内核模块编译头文件) | `qcom-robotics-sdk.inc`按DISTRO_FEATURES含ros2-humble/jazzy条件加入`nativesdk-ament-package`/`nativesdk-python3-colcon-common-extensions`/`nativesdk-rosidl-*`等ROS2编译工具包 |
| devtool集成 | `ext-sdk-add-layer.bbclass`:在生成的eSDK里放交互式`add_bitbake_layer`/`add_external_layers`脚本,方便开发者用`bitbake-layers add-layer`/`devtool modify`接入本地源码和BSP层 | 不支持,psdk使用者拿到的是"toolchain+预编译运行时包+示例代码" |
| 产物形态 | 标准`*.sh`自解压安装器(poky标准形态,`SDK_OUTPUT`/`SDKPATH`) | 自定义目录结构`tar.gz`(toolchain/、runtime/packages/*.rpm、qirp-samples/),需配套`qirp-setup.sh`自行解释安装逻辑,超出标准bitbake SDK类职责范围 |
| 覆盖产品线 | `qti-multimedia-image.bb`、`qti-robotics-image.bb`(`inherit qimage populate_sdk_qti`)、`qti-xreality-image.bb`、`qti-xreality2-base-image.bb`,4个通用产品镜像;已核实`qti-xreality2-image.bb`经`require qti-xreality2-base-image.bb`链式引用同样`inherit populate_sdk_qti`,即4条镜像线(含最新xreality2)全部在正常使用eSDK机制,repo内没有deprecated/EOL标记;进一步用`git log`核实这4个recipe文件各自最后一次真实改动(剔除本地`[DNM]`临时commit):`qti-multimedia-image.bb`2026-07-27、`qti-xreality2-base-image.bb`2026-05-27,均在近3个月内,活跃;`qti-robotics-image.bb`2025-07-28,距今约13个月;`qti-xreality-image.bb`2023-01-09,距今约3年7个月,是4条里明显最久未改动的一条 | 仅`meta-qcom-robotics-sdk`层(`qcom-robotics-image`/`qcom-robotics-proprietary-image`两个target),其他产品线(multimedia/networking/container-orchestration)没有类似专属SDK打包任务;但`meta-qcom-distro/conf/distro/include/qcom-base.inc`已把`SDK_VERSION`/`SDK_NAME`/`SDK_VENDOR`挂在distro层,标准`do_populate_sdk`/`do_populate_sdk_ext`对所有qcom-distro镜像天然可用(继承自oe-core),缺的只是robotics线那种自研二次打包;已用grep核实meta-qcom/meta-qcom-distro/meta-security/meta-updater/meta-virtualization全层没有任何multimedia/networking/container-orchestration专属SDK打包的TODO或WIP痕迹(唯一命中`do_populate_sdk`关键字的`meta-virtualization/.../vcontainer-tarball.bb`是上游通用容器打包recipe,与Qualcomm产品线规划无关) |
| 其他细节 | `meta-qti-customizations/core/recipes-core/meta/meta-extsdk-toolchain.bbappend`: `DEPENDS:remove = "qemu-native qemu-helper-native"`(QTI eSDK不支持qemu场景) | 打包依赖`do_collect_rdepends`生成的`packagegroup-*.list`文件;`BB_SETSCENE_ENFORCE_IGNORE_TASKS:append=" *:do_collect_rdepends"`修复内部eSDK构建下setscene报错的已知问题;`recipes-sdk/qirp-sdk.bb`纯运行时占位recipe,只安装`/usr/share/qirp-setup.sh` |
| SDK_VERSION管理 | 挂在整机`SDK_VERSION`/`BUILDNAME`,来自repo manifest的git describe | distro层通用机制`SDK_VERSION = "${DISTRO_VERSION}"`(`qcom-base.inc`)其实与downstream(maili)思路同构(都是绑定固件/distro版本);例外是`meta-qcom-robotics-sdk/classes/psdk-image.bbclass`硬编码`SDK_VERSION = "2.7.0"`,覆盖掉distro层默认值。已用`git log`对两个文件分别取证:`qcom-base.inc`里的`DISTRO_VERSION`自2025-03-03显式设为`"2.0"`后至今未再变过(42次相关commit里没有一次改动这个值);而`psdk-image.bbclass`的`SDK_VERSION`从初始2025-10-27提交的`"2.4.0"`,经多次修改,在2026-06-23由一次专门的`feat: update SDK_VERSION to 2.7.0`commit改到`"2.7.0"`。即在同一段时间里`DISTRO_VERSION`纹丝不动而`SDK_VERSION`独立升了3个小版本,坐实qirp-sdk走的是与固件/distro版本完全脱钩的独立发布节奏,是有意为之而非疏漏 |
| 静默失败风险 | eSDK生成时若`kernel_platform`路径命名不匹配,`os.path.exists`检测后`pass`,不打印警告,隐蔽故障点 | `do_generate_qirp_sdk`依赖文件缺失时`bbfatal`终止,失败模式更早暴露,风险低于downstream(maili) |

## 关键差异

- 走eSDK还是标准SDK:downstream(maili)走`populate_sdk_ext`(可devtool、可增量重建单个recipe、体积更大更"重"),QLI2.0机器人线走标准`do_populate_sdk`(更"轻"、面向纯发布交付,不支持devtool增量开发),再叠加一层自研打包任务,两者对"给开发者的SDK交互模型"完全不同:downstream(maili) SDK使用者可以在eSDK里`devtool modify`改内核/BSP源码后原地重编译;QLI2.0的qirp-sdk使用者拿到的是"toolchain+预编译运行时包+示例代码",属于典型"跨平台工具链+现成二进制"交付,不具备就地改内核重编的能力。
- 若审计报告只搜`do_populate_sdk`关键字本身,会得出"两侧完全一样"的错误结论;实际差异隐藏在各自BSP/产品层对标准类的下游二次封装(`populate_sdk_qti.bbclass` vs `psdk-image.bbclass`),必须往下追层才能发现。

## 影响与风险

- QLI2.0目前只有机器人产品线有自研SDK打包(`psdk-image.bbclass`);技术上标准`do_populate_sdk`/`do_populate_sdk_ext`对所有qcom-distro镜像天然可用,不是能力空白。是否要为multimedia/networking/container-orchestration线补一条专属打包/发布流程,属产品发布策略决策,已归入README《待拍板事项汇总》。
- downstream(maili)eSDK里硬编码依赖`PREFERRED_VERSION_linux-msm`、`kernel_platform`路径命名(`copy_buildsystem:append`里的路径拼接),一旦内核目录命名规则变化容易在eSDK生成阶段静默出错,属于潜在的隐蔽故障点。
- `qti-xreality`/`qti-xreality2`/`qti-multimedia`/`qti-robotics`这4条downstream(maili)产品SKU的代码维护活跃度已用`git log`逐一取证(见"覆盖产品线"):`qti-multimedia-image.bb`(2026-07-27)、`qti-xreality2-base-image.bb`(2026-05-27)近3个月内有真实改动;`qti-robotics-image.bb`(2025-07-28)约13个月未改动;`qti-xreality-image.bb`最后一次真实改动在2023-01-09,距今约3年7个月,是4条SKU里唯一长期无代码变更、事实上处于停止维护状态的一条。

