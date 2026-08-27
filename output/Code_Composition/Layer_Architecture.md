# Code Composition — Layer Architecture

## 对比范围

- **覆盖**:
  - 激活层数量统计:重新逐行核实QLI1.0`build-qti-distro-camerastack-debug/conf/bblayers.conf`的`BBLAYERS`(实测59条路径)与QLI2.0`build/conf/bblayers.conf`的`BBLAYERS`(实测21条`${TOPDIR}/../`条目),两次重新统计与现有正文结论完全一致
  - QLI1.0`poky/meta-qti-*`系列层全量普查(重新`find poky -maxdepth 1 -iname "meta-qti-*"`实测49个子目录,含prop/internal/core/kernel等后缀细分;文档正文"约45个"为口径宽松估计,已记入本次报告的偏差说明)与QLI2.0全部21个激活层名单、"旧layer→新layer映射表"
  - 消失layer去向逐项核实(层名/目录归属层面的普查,不含各子系统内部驱动/协议深挖):
    - ss-mgr:`meta-qti-ss-mgr(-prop)`(`init-mss_2.0.bb`/`reboot-daemon`)去向,内核remoteproc迁移与用户态看门狗缺口(重新核实`poky/meta-qti-ss-mgr/recipes/init-mss/init-mss_2.0.bb`、`src/mdm-ss-mgr/reboot-daemon/reboot-daemon.c`两文件均存在)
    - aosphal-adaptation:`libhardware_1.0.bb`/`camera-metadata_1.1.bb`(重新核实两文件确实存在于`poky/meta-qti-aosphal-adaptation/recipes/`下)去向,AOSP HAL移除结论
    - cta-internal/sv-internal/sv-prop:EVA/CVP视觉引擎去向,与Camera.md的CVP硬件证据角度互补而非重复(重新核实`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`与`meta-qcom/conf/machine/kaanapali-mtp.conf`两侧文件均存在)
    - security-internal(-common):`minktransport-test.bb`/`qtvm-test.bb`/`securemsm-internal.bb`(重新核实三文件均存在于`poky/meta-qti-security-internal/recipes/`下)去向,Mink IPC/QSEECom→Linux TEE子系统迁移,TUI生产能力去向(重新核实`meta-qti-security-internal-common`确实为空层,目录下仅`.git`软链接、0个真实文件)
    - internal测试类层(kernel-tests/stability-tests/sat-module/memory-error-tests)向公开`qualcomm-linux/lava-test-plans`/`qcom-linux-testkit`仓库迁移的模式性结论
  - 层数变化的性质归因(合并进`meta-qcom`/`meta-qcom-distro`、整层拆分为独立开源产品、新增机器人/ROS产品线三种效应叠加)与"-internal/-prop边界物理消失后新治理机制"的开放问题
- **明确排除**:
  - WLAN/BT驱动栈、平台守护进程与固件深度对比 ——见[WiFi_BT](../System_Architecture/WiFi_BT.md)
  - Toolchain/`meta-clang`组织形式变化与内核构建clang强制使用问题的深度分析 ——见[Toolchain](../Build_Architecture/Toolchain.md)
  - OTA机制(`src/OTA`→`meta-updater`)深度对比 ——见[OTA_Mechanism](../Platform_Features/OTA_Mechanism.md)
  - `meta-lts-mixins`与内核版本管理关系的辨析 ——见[Kernel_Code_Architecture](../System_Architecture/Kernel_Code_Architecture.md)
  - Display合成服务层/DRM-KMS/Wayland/Mesa深度对比 ——见[Display](../System_Architecture/Display.md)
  - GPU用户态3D驱动开源状态深度对比 ——见[Graphics](../System_Architecture/Graphics.md)
  - Camera CamX/ChiCDK/QMMF/camera-service深度对比 ——见[Camera](../System_Architecture/Camera.md)
  - Audio框架(`meta-iot-audio`→`meta-audioreach`)深度对比 ——见[Audio](../System_Architecture/Audio.md)
  - SELinux/`meta-qti-sepolicy`/`meta-selinux`策略体系深度对比 ——见[Security_Architecture](../System_Architecture/Security_Architecture.md)
- **待定边界**:(无,已核实——本次重新核实的全部关键锚点[BBLAYERS两侧计数、ss-mgr/aosphal/EVA/security-internal相关recipe与源码文件是否存在]均与现有正文结论一致;上述9条"明确排除"对应的目标文档均已实际存在且在自身正文/覆盖字段中承接了对应内容,未发现悬空指向)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 激活层数量 | 59条路径(`build-qti-distro-camerastack-debug/conf/bblayers.conf`的`BBLAYERS`变量,逐行统计`/local/...`路径条目数得59,非此前误记的51) | 21条路径(`build/conf/bblayers.conf`的`BBLAYERS`变量逐行统计) |
| `meta-qti-*`系列规模 | 约45个,按prop/internal/core/kernel等后缀细分同一功能域,如:`meta-qti-aosphal-adaptation`、`meta-qti-bsp(-prop)`、`meta-qti-bt(-prop)`、`meta-qti-camera(-prop)`、`meta-qti-core(-internal/-prop)`、`meta-qti-cta-internal`、`meta-qti-display(-internal/-prop)`、`meta-qti-distro`、`meta-qti-eva(-devicetree)`、`meta-qti-fastcv(-internal/-prop)`、`meta-qti-gfx-kernel(-prop)`、`meta-qti-gfx-prop`、`meta-qti-gst`、`meta-qti-internal`、`meta-qti-ml(-prop)`、`meta-qti-mmframeworks(...)`、`meta-qti-perf-prop`、`meta-qti-ppat-prop`、`meta-qti-qmmf(-prop)`、`meta-qti-security(...)`、`meta-qti-sepolicy`、`meta-qti-ss-mgr(-prop)`、`meta-qti-sv-internal`、`meta-qti-sv-prop`、`meta-qti-touch`、`meta-qti-wlan(-prop)`;另有`meta-clang`、`meta-iot-audio(-internal/-prop)`、`meta-poky`、`meta-yocto-bsp`、`meta-selftest`、`meta-skeleton` | `meta-audioreach, meta-lts-mixins, meta-openembedded/{meta-filesystems,meta-gnome,meta-multimedia,meta-networking,meta-oe,meta-python,meta-xfce}, meta-qcom, meta-qcom-distro, meta-qcom-robotics-sdk, meta-ros/{meta-ros-common,meta-ros2,meta-ros2-jazzy}, meta-security, meta-security/meta-tpm, meta-selinux, meta-updater, meta-virtualization, oe-core/meta` |
| 命名体系 | 私有前缀`meta-qti-*` | 社区惯例`meta-qcom*`,已开源到`github.com/qualcomm-linux/*` |
| 层数降幅 | — | 约64%((59-21)/59) |

## 旧layer → 新layer映射表

| QLI1.0旧layer | QLI2.0新layer/归属 | 说明 |
|---|---|---|
| meta-qti-bsp(-prop), meta-qti-gfx-kernel(-prop), meta-qti-touch, meta-qti-eva(-devicetree), meta-qti-perf-prop, meta-qti-ppat-prop, meta-qti-ml(-prop), meta-qti-qmmf(-prop), meta-qti-security(-*), meta-qti-sepolicy(部分) | **meta-qcom** | 硬件使能层合并:recipes-bsp/(firmware,lk,u-boot,partition), recipes-graphics/(adreno,kgsl-dlkm,mesa,msm-gbm-backend), recipes-kernel/(linux,iris-video-module), recipes-ml/qairt, recipes-support/(pd-mapper,qmi-framework,qrtr,rmtfs,fastrpc), recipes-test/(diag,bootrr) |
| meta-qti-camera(-prop), meta-qti-fastcv(-internal/-prop) | **meta-qcom**(recipes-multimedia/camx, fastcv) + **meta-qcom-distro**(recipes-multimedia/libcamera) | 相机内核态驱动(camx-dlkm)仍闭源存在,但用户态转向开源libcamera栈 |
| meta-qti-display(-internal/-prop) | **meta-qcom**(recipes-graphics/wayland,mesa) + **meta-qcom-distro**(recipes-graphics/wayland) | 私有display HAL消失,替换为Mesa/DRM/Wayland开源图形栈 |
| meta-qti-gst | **meta-qcom**/**meta-qcom-distro**的recipes-multimedia/gstreamer | 直接迁移 |
| meta-qti-wlan(-prop) | **meta-qcom**(recipes-connectivity/sigma-dut) | 未见独立wlan专有层,ath系开源驱动路径已在output/System_Architecture/WiFi_BT.md完整核实 |
| meta-qti-bt(-prop) | **meta-qcom-distro**(recipes-connectivity/bluez5) | 从专有libbt-vendor迁移为标准BlueZ5 |
| meta-qti-distro | **meta-qcom-distro** | 一一对应的"distro策略/镜像"层 |
| meta-iot-audio(-internal/-prop) | **meta-audioreach**(独立顶层新repo) | 音频框架整层拆出为独立开源项目 |
| meta-qti-internal, meta-qti-cta-internal, meta-qti-sv-internal/-prop, meta-qti-aosphal-adaptation, meta-qti-security-internal-common | **未找到对应新层** | 逐层核实结果见下方"消失layer去向核实" |
| meta-qti-ss-mgr(-prop) | **未找到对应新层** | 核实结果见下方 |
| meta-clang | **组织形式变化,已合并进oe-core主干** | 详见output/Build_Architecture/Toolchain.md,非能力删除 |
| meta-poky, meta-yocto-bsp, meta-selftest, meta-skeleton | **移除**,改用纯`oe-core`+`distro: nodistro`(kas base.yml已验证) | 不再套用Poky参考发行版壳,直接基于OE-Core |
| meta-openembedded/{meta-oe,meta-python,meta-networking,meta-filesystems,meta-multimedia} | 原样保留,新增**meta-gnome, meta-xfce** | 桌面相关子层是全新引入 |
| meta-virtualization, meta-selinux | 原样保留 | 层名、定位不变 |
| — | **meta-qcom-robotics-sdk**(全新) | 全新机器人/ROS产品线专属层 |
| — | **meta-ros**(meta-ros-common/meta-ros2/meta-ros2-jazzy,全新) | 全新ROS2支持 |
| — | **meta-updater**(全新,aktualizr/OSTree OTA) | 功能上取代QLI1.0`src/OTA`(Android式bsdiff+recovery A/B升级),详见output/Platform_Features/OTA_Mechanism.md |
| — | **meta-security/meta-tpm**(全新) | TPM2硬件安全栈,与meta-qti-security(专有TrustZone/QSEE相关)定位不同,是新增能力 |
| — | **meta-lts-mixins**(全新) | 实际只含linux-firmware后向移植mixin,与内核版本管理无关(常见误解需纠正,详见output/System_Architecture/Kernel_Code_Architecture.md) |

## 消失layer去向核实

### meta-qti-ss-mgr / meta-qti-ss-mgr-prop(Subsystem Restart管理)

- QLI1.0原功能:`init-mss_2.0.bb`安装`init_mss`初始化脚本+`init_rproc_mss.service`。**关键证据**——即使在QLI1.0里,该服务本身就是对标准Linux`remoteproc`sysfs接口的封装:`for d in /sys/class/remoteproc/remoteproc*/; do ... echo start > $d/state; ... done`,新款平台(kalama/pineapple/kera/qcm2290-mtp等)均直接安装`init_rproc_mss.service`走`/sys/class/remoteproc/remoteprocN/state`。同类模式还有`init_mss.rules`(udev规则,面向遗留字符设备`/dev/subsys_modem`、`/dev/subsys_wcnss`)、`reboot-daemon`(在modem反复加载失败后触发slot切换/EDL/recovery重启,`SlotSwitchReboot()`)。`meta-qti-ss-mgr-prop`(标记为mdm-ss-mgr,MDM SKU专用):`ssreq-server`(Subsystem Shutdown Request server)、`pdc-daemon`(Persistent Device Config)、`psm`(Power Saving Mode Framework)、`qmi-shutdown-modem`、`diag-reboot-app`,全部通过QMI协议与调制解调器交互。
- QLI2.0搜索结果:全树搜索`subsystem.restart|ssr|pil.splitter|ramdump|remoteproc|subsys_modem|ssreq|pdc.daemon|qmi.shutdown|mdm-ss-mgr`**未命中任何recipe**(仅命中内核构建产物auto.conf)。**内核侧确认保留且已升级为主线框架**:`CONFIG_REMOTEPROC=y`、`CONFIG_QCOM_RPROC_COMMON=m`、`CONFIG_QCOM_Q6V5_COMMON=m`、`CONFIG_QCOM_Q6V5_MSS=m`(modem子系统PIL驱动,主线)、`CONFIG_QCOM_Q6V5_PAS=m`、`CONFIG_QCOM_Q6V5_ADSP=m`、`CONFIG_QCOM_PIL_INFO=m`、`CONFIG_QCOM_SYSMON=m`(子系统间优雅关机通知协议,主线)。但**没有找到任何用户态remoteproc启动脚本/systemd unit/udev规则**;已核实自动上电机制不是设备树属性,而是`drivers/remoteproc/qcom_q6v5_pas.c`里per-SoC匹配表的`.auto_boot = true`硬编码字段(kernel-source全树`grep -rl "pas-auto-boot"`零命中,排除了"设备树属性驱动上电"这个猜测),即modem/DSP由内核remoteproc驱动按驱动代码内置逻辑自动上电,不依赖DT配置,也不需要任何用户态脚本介入。MDM/QMI专属栈(ssreq-server/pdc-daemon/psm/qmi-shutdown-modem/diag-reboot-app/CTA综合测试)完全未见,转向主线`ModemManager`而非专有QMI用户态守护进程栈。
- **结论**:内核态remoteproc/subsystem-restart框架已迁移(从专有PIL驱动升级为主线`CONFIG_QCOM_Q6V5_*`/`CONFIG_QCOM_SYSMON`驱动,QLI1.0自身用户态代码其实已经在用这套接口)。MDM/QMI专属用户态子系统管理栈**已移除**,与"QLI2.0是否还支持独立调制解调器SKU"这一更大架构问题相关——若QLI2.0定位不再包含standalone-MDM产品线,则移除属预期;否则为功能缺失。
- **单次崩溃自动恢复的等价物已核实存在,但"多次失败后升级为slot切换/EDL"的看门狗逻辑确认没有等价物**:mainline`remoteproc`核心(`drivers/remoteproc/remoteproc_sysfs.c`)自带每个rproc设备的`recovery`sysfs属性,默认值`enabled`,子系统崩溃时内核直接调用`rproc_trigger_recovery()`自动重启对应子系统,不需要任何用户态daemon介入;`remoteproc_core.c`中`crash_cnt`只做日志计数(`"handling crash #%u in %s"`),核对`qcom_q6v5_pas.c`/`qcom_sysmon.c`全文,均未发现"连续失败N次后触发系统级reboot/EDL/slot切换"的升级逻辑。同时用`meta-qcom/conf/machine/*.conf`核对了实际启用modem硬件路径(`mpss-pas`,在共享内核树`sm8750.dtsi`/`sc7280.dtsi`均存在)的机型:`qcm6490-idp`、`iq-8275-evk`、`iq-9075-evk`、`rb3gen2-core-kit`均带`MACHINE_FEATURES += "...phone"`,`meta-qcom-distro/recipes-products/images/qcom-console-image.bb`按此feature拉取标准`modemmanager`(`meta-openembedded/meta-oe/recipes-connectivity/modemmanager`),即QLI2.0modem生命周期管理走mainline ModemManager+内核自带单次崩溃自恢复,原QLI1.0"多次失败后触发slot切换/EDL恢复"的看门狗逻辑**确认为真实缺口,无等价实现**,不是待人工确认的未知项。
- **internal-only QA工具是否已被开源标准工具替代**这半个问题已有明确答案:`oe-core/meta/recipes-extended/ltp/ltp_20260130.bb`、`oe-core/meta/recipes-extended/stress-ng/stress-ng_0.20.01.bb`均是标准recipe,且`oe-core/meta/lib/oeqa/runtime/cases/ltp.py`、`ltp_compliance.py`已集成进OEQA运行时测试框架,即LTP/stress-ng确认以标准OE机制存在(kselftest未找到独立recipe,通常随内核源码树自带,非本次搜索范围内可证伪)。**"是否额外转移到独立测试仓库"这半个问题现已证实**:`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-audioreach`四个顶层产品的`.github/workflows/test*.yml`与`.github/actions/lava-test-plans/action.yml`里,硬件在环测试(HIL smoke/boot test)通过`actions/checkout@v6`显式拉取两个独立仓库——`qualcomm-linux/lava-test-plans`(生成LAVA测试job的测试计划仓库)与`qualcomm-linux/qcom-linux-testkit`("standalone validation scripts...for Qualcomm RB3Gen2 and platforms based on meta-qcom",即验证脚本本体),测试执行落在第三方托管的LAVA测试实验室`lava.infra.foundries.io`(`foundriesio/lava-action@v13`)。用`curl -s https://api.github.com/repos/qualcomm-linux/lava-test-plans`与`.../qcom-linux-testkit`核实两者`"private": false`,均是`qualcomm-linux`组织下的公开仓库(`qcom-linux-testkit`的`commits/main.atom`显示2026-08-24仍有活跃提交)。即QA工具确实"转移到了独立仓库",但不是未公开的私有内部仓库,而是与`meta-qcom`平级的公开GitHub仓库+Foundries.io托管的公开LAVA测试lab,这一问题已不再是"快照之外的私有信息"。

### meta-qti-aosphal-adaptation(Android HAL适配层)

- QLI1.0原功能:层内仅两个recipe——`libhardware_1.0.bb`("Android libhardware headers",`PACKAGECONFIG:="audio camera display location sensors"`,`DEPENDS += "libcutils libutils liblog system-core-headers"`,即标准Android`hardware/libhardware`HAL加载框架`hw_get_module()`)、`camera-metadata_1.1.bb`("Recipe to provide Camera Metadata library",`HOMEPAGE="http://developer.android.com/"`,`DEPENDS += "libcutils binder liblog libutils"`,标准Android Camera HAL3元数据库)。该层是让CamX/Camera等Qualcomm多媒体栈复用AOSP Camera HAL3/libhardware接口的适配层(不含HIDL/hwbinder,是较老的passthrough HAL而非Treble HIDL)。
- QLI2.0搜索结果:`grep -rli "libhidl|hwbinder|android\.hardware|libhardware"`全树仅命中`android-tools_5.1.1.r37.bb`(adb/fastboot工具,与HAL无关)。`find -iname "*libhardware*" -o -iname "*camera-metadata*"`无命中。进一步验证:QLI2.0中连基础Android兼容库本身(`libcutils`/`liblog`/`libbinder`/`libutils`,即`system/core`)也全部不存在。交叉验证:QLI2.0的camx(`camxlib-kodiak_1.0.24.bb`)`DEPENDS`只有`glib-2.0 fastrpc protobuf-camx libxml2 qmi-framework sensinghub qcom-sensors-binaries`,不再依赖libhardware/binder/camera-metadata。
- **结论**:已移除,且是彻底的架构性移除(不是改名)。QLI2.0已完全放弃AOSP HAL/`system/core`兼容库路线,CamX等多媒体栈改为直接对接原生Linux(glib/协议库)接口,不再需要任何Android HAL passthrough层。这是架构决策,应作为记录而非缺陷。

### meta-qti-cta-internal / meta-qti-sv-internal / meta-qti-sv-prop

- **CTA**:`meta-qti-cta-internal/recipes/cta/cta_1.1_git.bb`:"Library and application for CTA(comprehensive test app)"。关键证据——`SRC_URI="file://mdm-ss-mgr/internal-tests/cta/"`,`DEPENDS += "glib-2.0 data qmi-framework qmi"`。**CTA=Comprehensive Test App,是mdm-ss-mgr生态下的QMI综合测试工具**,与"合规测试自动化"无关,而是调制解调器/QMI子系统的内部测试应用,仅面向sdm845/sdxprairie/sdxpoorwills/mdm9607/mdm9650/sdx20等MDM系列机型镜像(`recipes/images/<machine>/xxx-cta-internal-image.inc`)。
- **SV**:`meta-qti-sv-internal/recipes/sv-internal/sv-internal_git.bb`:"Generates svTest32/svTest64 binary",源目录`vendor/qcom/proprietary/cv-internal/sv`。`meta-qti-sv-prop/recipes/sv-noship/sv-noship_1.0.bb`:"Generates libeva",源目录`vendor/qcom/proprietary/cv-noship`。`evass-fw_git.bb`:"EVA firmwre binaries"。**SV隶属于CV(Computer Vision)子系统,产出库名为`libeva`/`packagegroup-qti-eva`,即Qualcomm的EVA(Engine for Video/Vision Analytics)硬件加速视觉分析引擎**的固件与测试套件,与"System Verification"或"Sensor Vision"字面猜测不同,是具体的视觉分析DSP引擎栈。
- QLI2.0搜索结果:`grep -rli "\bcta\b"`全树无命中(排除build产物噪声);`grep -rliE "\beva\b|libeva|evass"`全树无命中,`\bcvp\b|\bicp\b`也无命中。`meta-qcom-robotics-sdk`目录树中的视觉/感知相关组件是`qrb-ros-camera`、`qrb-ros-nn-inference`、`qrb-ros-video`、`qrb-ros-color-space-convert`、`orbbec-camera`等基于ROS2的通用感知栈,没有任何EVA专用引擎的对应物,也没有`packagegroup-qti-eva`或等价packagegroup。进一步把搜索范围从"当前machine的dts"扩大到`build/tmp/work-shared/iq-9075-evk/kernel-source`整个共享内核源码树(`drivers/`全部驱动代码+`Documentation/devicetree/bindings/`全部binding文档+`arch/arm64/boot/dts/qcom/`全部SoC dts,覆盖sm8750/qcm6490/sc7280/sm8650等这套mainline内核支持的全部平台),`grep -rliE "qcom,.*-eva\b|qcom,.*cvp|\beva-fw\b"`同样零命中——即这不是"当前machine的dts没写"的问题,而是这整套mainline内核代码库里从未出现过EVA/CVP的compatible字符串或驱动代码,证明EVA/CVP在QLI2.0所依赖的这条内核基线上确实没有对应驱动。
- **结论**:CTA已移除——本质是ss-mgr的测试子集,结论与上一条联动,若QLI2.0不再支持MDM SKU则该测试工具随之退役属预期。SV/EVA(Computer Vision分析引擎)经多关键字搜索(eva/libeva/evass/cvp/icp/sv-noship)确认无对应物,QLI2.0机器视觉能力已完全转向`meta-qcom-robotics-sdk`下的ROS2/`qrb-ros-*`通用感知栈。**硬件层面已确认存在**:`meta-qcom/conf/machine/kaanapali-mtp.conf`是QLI2.0真实定义的机型,QLI1.0的`eva-kernel`驱动里有专为"kaanapali"芯片写的`cvp_kaanapali_hal.c`(Qualcomm署名),两边指向同一SoC代号,证明该芯片确实带EVA硬件IP;而QLI1.0`meta-qti-eva-devicetree`层标记`x-ship="hy11"`,说明EVA在QLI1.0自己的产品线里也是HY11(fullstack)专属,并非所有产品线标配——QLI2.0现在机器人产品线定位下未启用EVA,更像是产品定位选择而非迁移遗漏。

### meta-qti-security-internal(-common)

- `meta-qti-security-internal-common`:目录下除`.git`软链接外无任何文件,确认为空/未拉取的占位层,在本快照中不承载任何实际功能。`meta-qti-security-internal`(注意与-common是两个不同层)实际承载内容:`minktransport-test.bb`(`SRC_URI="file://mink/vendor/qcom/proprietary/mink-internal/minktransport_test"`,`RDEPENDS="gtest minkfdwrapper mink-transport"`——Mink IPC传输层的gtest测试程序)、`qtvm-test.bb`(`DEPENDS += "... qtvm-sdk"`——QTVM,Qualcomm Trusted VM,虚拟化TEE平台的测试TA)、`securemsm-internal.bb`(内含TUI(Trusted User Interface)图片/字体资源`files/tui/*.png`/`*.bin`、GPTEE测试App、smcinvoke测试客户端,`EXTRA_OECONF`开关`--enable-trustedui`/`--enable-gptest`/`--enable-qti-mink`)。该层是TrustZone/QTVM安全世界的内部QA/测试工具集,区别于`meta-qti-sepolicy`(SELinux策略)和`meta-qti-security-prop`(生产安全组件),纯粹是测试/调试用途,不是生产安全功能本体。
- QLI2.0搜索结果:`grep -rli "qseecom|mink-transport|mink_transport"`全树无命中——旧的QSEECom字符设备接口与专有`mink-transport`库已不存在。但安全IPC能力并未消失,而是架构性升级:`meta-qcom/dynamic-layers/openembedded-layer/recipes-security/minkipc/minkipc_1.2.8.bb`与`mink-idl-compiler_0.2.3.bb`仍存在(生产版Mink IPC,已被`qwes`、`securemsm`等多处`DEPENDS`引用);`meta-qcom/dynamic-layers/openembedded-layer/recipes-security/qcomtee/qcomtee_git.bb`:"QCOM-TEE Library provides an interface for communication to the Qualcomm Trusted Execution Environment (QTEE) via the QCOM-TEE driver registered with the **Linux TEE subsystem**"(`github.com/quic/quic-teec`)——安全世界通信已从专有QSEECom迁移到主线Linux TEE子系统框架(`drivers/tee`)。`qwes_1.1.bb`(Qualcomm Wireless Edge Services)也`DEPENDS += "... minkipc qmi-framework ..."`,证明minkipc生产栈仍在被消费。但`minktransport-test`/`qtvm-test`/`securemsm-internal`(TUI资源)/GPTEE测试本身,以及`meta-qti-security-internal-common`(本就空)在QLI2.0全树未找到任何对应物。
- **结论**:底层安全IPC能力已迁移/升级(QSEECom+Mink-transport→主线Linux TEE子系统+`qcom-tee`(quic-teec)+生产版minkipc)。这是积极的架构现代化,不是功能缺失。`meta-qti-security-internal-common`因其在QLI1.0快照中本就是空层,无法评估其功能,不构成"缺失"证据。`meta-qti-security-internal`的测试工具(minktransport-test/qtvm-test/TUI资源/GPTEE测试)已移除——属于内部QA/调试工具范畴,移除风险较低。**TUI(Trusted UI)本体已核实是QLI1.0侧真实生产能力而非测试资源**:`build-qti-distro-camerastack-debug/conf/{alor,kera,pebble,sun}_prebuilts.conf`里的`securemsm-noship`包含生产二进制`TUICoreService`、`libqwes`、`libQseeComApi`、`libqcbor`等一整套支撑库,按HY11标记打包到这4个当前在用的机型上。QLI2.0侧把搜索范围从`meta-qti-security-internal`对应目录扩大到`meta-qcom`/`meta-security`/`meta-updater`全部`.bb`/`.bbappend`/`.inc`/`.conf`,`trustedui|trusted-ui|biometric|payment.*secure|fingerprint.*ui|securemsm|gptee`零命中——即QLI2.0目前没有任何TUI对应物(不只是测试资源消失,生产本体同样缺失)。是否需要补齐属产品决策,已在README.md"安全/合规风险清单"(TUI行,P1)记录,本文档不再重复讨论是否要补的问题。

### 交叉发现:internal测试类层的系统性缺失模式

`meta-qti-internal`(未在原任务列表中单列,但同属"未找到映射"疑点集合)里的`kernel-tests`/`stability-tests`/`sat-module`(安全测试模块)/`memory-error-tests`/`msm-bus`测试等调试与基准测试工具,经`grep -rli "kernel-tests|stability-tests|memory-error-tests|sat-module"`全树搜索同样确认无对应物,与security-internal的测试类工具遭遇相同命运——即QLI2.0不再维护QLI1.0那种按layer内嵌`-internal`测试recipe的模式,而是把"要跑什么测试"整体外移到了公开的`qualcomm-linux/lava-test-plans`+`qualcomm-linux/qcom-linux-testkit`两个独立仓库,由GitHub Actions在PR/nightly时拉取执行(详见下方"消失layer去向核实"最后一条的更新)。这两个具体QTI legacy测试项(kernel-tests/stability-tests/sat-module/memory-error-tests)本身在新testkit里是否有等价脚本未逐条比对,但"测试是否被移到独立仓库"这一模式性问题已证实为真,建议在总结论中将"internal测试类层迁移到公开testkit仓库"作为一个统一模式指出,而非逐层单独判定为风险。

## 汇总结论表

| QLI1.0层 | QLI2.0去向 | 性质 |
|---|---|---|
| meta-qti-ss-mgr(内核态remoteproc部分) | 迁移(主线CONFIG_QCOM_Q6V5_*) | 架构升级 |
| meta-qti-ss-mgr(用户态reboot-daemon) | 未找到,且已确认无等价物 | **真实缺口**(mainline remoteproc只有单次崩溃自恢复,无"多次失败后slot切换/EDL"升级逻辑) |
| meta-qti-ss-mgr-prop(MDM/QMI专属栈) | 未找到 | 可能是产品线取舍(MDM SKU) |
| meta-qti-aosphal-adaptation | 已移除 | **架构决策**(放弃AOSP HAL) |
| meta-qti-cta-internal | 已移除(随ss-mgr退役) | 预期内 |
| meta-qti-sv-internal/-prop(EVA引擎) | 未找到 | **硬件存在,软件未跟进**(kaanapali芯片经交叉验证确认带EVA IP,是否补齐取决于产品对该机型的定位) |
| meta-qti-security-internal-common | 无法评估(QLI1.0侧本就是空层) | 证据不足 |
| meta-qti-security-internal(测试工具) | 已移除(功能本体已migrate,只是测试工具消失) | 低风险 |
| meta-qti-internal(各类internal QA工具) | 未找到原样对应物,但已确认LTP/stress-ng等标准OE测试recipe存在并集成进OEQA,测试执行整体迁移到公开仓库`qualcomm-linux/lava-test-plans`+`qualcomm-linux/qcom-linux-testkit`(经GitHub API核实均为公开仓库) | 已证实迁移到公开独立仓库,非私有内部仓库 |
| meta-clang | 合并进oe-core主干 | 组织形式变化,非移除 |

## 关键差异

- 层数从59条压缩到21条,降幅约64%,但这个降幅是三种不同性质的变化叠加而成,不能直接读成"功能砍掉了六成":大部分`meta-qti-*`是被合并进`meta-qcom`/`meta-qcom-distro`(硬件使能层整合,能力延续、只是物理位置变了),部分整层拆成独立开源产品(`meta-audioreach`、`meta-updater`),同时还新增了QLI1.0完全没有的机器人/ROS产品线专属层(`meta-qcom-robotics-sdk`、`meta-ros`)。三者相加才导致净层数大幅下降。
- "找不到映射的旧layer"里真正站得住的能力缺口比表面看到的少,但已经收窄到两个具体、都已交叉验证的点:内核态remoteproc/安全IPC底层表面上"消失",实际是升级到了主线框架(`CONFIG_QCOM_Q6V5_*`+`CONFIG_QCOM_SYSMON`、Linux TEE子系统+`qcomtee`/`minkipc`),internal测试类层的消失也不是能力丢失而是整体外移到`qualcomm-linux/lava-test-plans`+`qcom-linux-testkit`两个公开仓库由GitHub Actions驱动。真正的缺口只剩:ss-mgr用户态"多次失败后slot切换/EDL"看门狗逻辑(mainline remoteproc只有单次崩溃自愈,没有升级逻辑)和EVA视觉分析引擎(kaanapali芯片硬件IP经交叉验证确认存在,但QLI2.0软件栈未跟进,转向ROS2感知栈)——这两项已分别记录进README安全/合规风险清单。
- 命名体系从私有前缀`meta-qti-*`切到社区惯例`meta-qcom*`并整层开源到GitHub,同时`-internal`/`-prop`/`-core`这类原本用于标记"是否可对外"的目录级边界在物理层面一并消失。这意味着QLI2.0控制专有/开源边界的机制已经从"目录名带不带internal/prop"变成了"代码进了哪个可见性的仓库",这个控制机制本身的搬迁,比"层的数量变少了"更需要下游确认——需要明确新的边界判定是靠recipe级LICENSE字段还是靠仓库访问权限,否则存在过度开源或误判闭源边界的风险。

## 影响与风险

- DISTRO_FEATURES语义/layer边界重构:层合并意味着原来精细的`-internal`/`-prop`/`-core`边界(通常用于区分"可开源"vs"内部专有"vs"客户可见")在物理目录层面消失,需要确认新的开源/闭源边界控制机制(是靠recipe级LICENSE还是靠仓库可见性控制?),否则可能有过度开源风险。
- `meta-qti-ss-mgr`、`meta-qti-internal`、`meta-qti-cta-internal`等找不到直接映射,如果这些功能未被迁移而只是被静默删除,需要产品侧确认功能是否有缺失(如subsystem restart管理ss-mgr是核心稳定性功能,不应"消失")。
- 工具链从`meta-clang`移除后如果编译器切换到纯GCC,可能影响之前依赖clang特定优化/sanitizer(如HWASAN,注意QLI1.0中出现过`noship_common_HY11-HWASAN`文件名)的调试能力(详见output/Build_Architecture/Toolchain.md,已纠正为组织形式变化而非能力删除)。
