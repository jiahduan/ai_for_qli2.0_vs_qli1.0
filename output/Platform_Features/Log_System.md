# Platform Features — Log System

## 对比范围

- **覆盖**:
  - DIAG协议栈/`diag-router`与`libdiag`的整体架构对比:QLI1.0`src/diag/`(`diag_lsm*.c`、`mdlog/diag_mdlog.c`、`klog/diag_klog.c`、`socket_log/`、`uart_log/`、`java/`JNI)vs QLI2.0`meta-qcom/recipes-test/diag/diag_git.bb`(`github.com/linux-msm/diag`)+`diag-router_1.0.2.bb`+`libdiag_1.0.5.bb`。
  - Android兼容日志(logd/logcat)对比:QLI1.0`src/system/core/logd/`、`src/system/core/logcat/`(已适配systemd,`logd.service`/`logd.path`)vs QLI2.0无对应组件;对`meta-qcom`/`meta-qcom-distro`/`meta-audioreach`/`meta-security`/`meta-updater`全量`grep -rln "logd\|logcat"`实测4处命中均逐行核查为子串误报(`rsyslogd`/`logdir`/`csyslogd`)。
  - 基础系统日志(journald/rsyslog)对比:两侧均继承systemd/journald,QLI2.0新增`meta-qcom-distro/recipes-extended/rsyslog/rsyslog_%.bbappend`+`rsyslog.logrotate.qcom`定制(仅轮转/留存策略,不含脱敏规则)。
  - 镜像集成范围核实:`meta-qcom-distro/recipes-products/images/`下7个产品镜像逐一核对`CORE_IMAGE_BASE_INSTALL`,仅`qcom-multimedia-proprietary-image.bb`装`libdiag-bin`;`meta-qcom/ci/qcom-distro.yml`的`target:`量产列表不含`diag-router`。
  - `android_compat`功能定位澄清:`src/android_compat/common/inc/`实测内容(`target.h`/`common_log.h`/`comdef.h`/`rex.h`/`qsocket.h`)确认为头文件级REX/QNX移植兼容层,非logcat/logd再实现。
- **明确排除**:
  - journald存储模式默认值变化(v259起`Storage=`由`auto`改为`persistent`)及其对`/var/log/journal`落盘行为的影响 ——见[systemd](../Boot_Architecture/systemd_.md)
- **待定边界**:(无,已核实。WiFi_BT.md的"明确排除"项——DIAG协议栈/`diag-router`与`libdiag`的整体架构对比——已在本文"覆盖"字段第一条真实承接,跨文档指向核对一致;本次未发现现有证据链之外的遗漏检索目录。)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| DIAG协议栈 | `src/diag/`: `diag_lsm*.c`(DIAG Linux Support Machine库)、`mdlog/diag_mdlog.c`(modem日志抓取)、`klog/diag_klog.c`、`socket_log/`、`uart_log/`、`java/`(JNI,`com.qualcomm.qti.diagservice.libdiagwrapper`),核心组件随发布,用于modem/DSP/子系统与QXDM/QPST等外部工具间的诊断报文路由 | `meta-qcom/recipes-test/diag/diag_git.bb`(拉取`github.com/linux-msm/diag`,BSD-3-Clause开源版)、`diag-router_1.0.2.bb`、`libdiag_1.0.5.bb`,均位于**`recipes-test/`**,闭源预编译包(从`softwarecenter.qualcomm.com`下载),彼此`RCONFLICTS`/`RPROVIDES:virtual-diag-router`互斥 |
| Android兼容日志 | `src/system/core/logd/`、`src/system/core/logcat/`:完整AOSP logd守护进程源码(`LogBuffer.cpp`/`LogReader.cpp`/`LogListener.cpp`/`LogAudit.cpp`/`LogKlog.cpp`/`CommandListener.cpp`等),已适配systemd(`logd.service`、`earlyinit-logd.service`、`logd.path`,`Alias=logcat.service`),提供`/dev/socket/logdw`、logcat语义环形缓冲 | 无对应组件,未发现Android logd/logcat兼容层 |
| 基础系统日志 | systemd/journald(继承poky,`poky/meta/recipes-core/systemd/systemd-conf/journald.conf`) | systemd/journald(继承oe-core),新增`meta-qcom-distro/recipes-extended/rsyslog/rsyslog_%.bbappend`+`files/rsyslog.logrotate.qcom`定制 |
| 镜像集成证据 | logd/logcat作为核心组件随发布 | `meta-qcom-distro/recipes-products/images/qcom-multimedia-proprietary-image.bb`显式依赖`libdiag-bin`;`meta-qcom/recipes-test/images/initramfs-test-image.bb`依赖`virtual-diag-router` |
| android_compat澄清 | `src/android_compat/common/inc/`实测只包含`target.h`、`common_log.h`、`comdef.h`、`rex.h`、`qsocket.h`等**头文件级REX/QNX移植兼容层**,用于让modem侧代码在Linux上编译,并非logcat/logd的再实现——真正的logd/logcat落在`src/system/core`而不是`android_compat` | 不适用 |

## 关键差异

- 依赖logcat/`/dev/socket/logdw`语义读取日志的上层Android兼容应用、AI/HAL组件、以及基于logcat的问题定位脚本,在QLI2.0上没有对应接口,需要迁移到`journalctl`/`rsyslog`或自行移植logd。
- DIAG从"源码级核心组件"降级为"测试镶像/可选预编译二进制",意味着量产镶像默认可能不含完整DIAG能力(除非显式选择libdiag-bin),对现网依赖QXDM/QPST做售后诊断的流程有直接影响。
- rsyslog定制的引入表明QLI2.0对日志留存策略(logrotate)做了重新设计,需要与安全/合规团队确认落盘日志的敏感信息处理是否与QLI1.0一致。

## 影响与风险

- QLI2.0量产镶像中diag相关能力的默认启用范围很窄:对`meta-qcom-distro/recipes-products/images/`下全部7个产品镜像逐一核实,只有`qcom-multimedia-proprietary-image.bb`的`CORE_IMAGE_BASE_INSTALL`里显式装了`libdiag-bin`,其余6个(console/container-orchestration/minimal/multimedia非proprietary版/networking/xfce-demo)出厂默认不含;`diag-router`/`virtual-diag-router`只出现在`meta-qcom/recipes-test/images/initramfs-test-image.bb`测试镶像里,不在`meta-qcom/ci/qcom-distro.yml`的`target:`产品镜像构建列表中,即量产SKU不会随任何产品镜像默认打包diag-router。
- Android兼容日志接口的消失属于架构决策的自然延续(与System_Architecture中放弃AOSP HAL路线的判断一致),但影响面广,涉及所有依赖logcat语义的现有工具链。
- 已对`meta-qcom`、`meta-qcom-distro`、`meta-audioreach`、`meta-security`、`meta-updater`全部搜索`logd`/`logcat`关键字:`grep -rln "logd\|logcat"`实际命中4个文件——`meta-qcom-distro/recipes-extended/rsyslog/files/rsyslog.logrotate.qcom`、`meta-security/dynamic-layers/meta-perl/recipes-security/bastille/files/organize_distro_discovery.patch`、`meta-security/recipes-ids/suricata/suricata_8.0.4.bb`、`meta-security/recipes-ids/ossec/files/0002-Makefile-don-t-set-uid-gid.patch`。逐一核查命中行后确认均为子串误报,分别是`rsyslogd`(2处)、`logdir`(2处)、`logdir`、`csyslogd`,没有一处是Android的logd守护进程或logcat命令本身。代码库层面确实没有logd/logcat兼容层,也没有任何迁移代码痕迹。
- 已读取`meta-qcom-distro/recipes-extended/rsyslog/files/rsyslog.logrotate.qcom`完整内容,确认它只解决轮转/留存策略(`/var/log/syslog`等按满100MB或7天轮转,保留20份归档),不包含任何脱敏/过滤规则。
