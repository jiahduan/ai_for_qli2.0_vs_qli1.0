# Log_System 规则执行逻辑细节报告

本文档记录`Log_System.md`当前内容(DIAG/Android兼容日志/基础系统日志三层对比)是**怎么从源码证据一步步取得的**——按`rules/Platform_Features/Log_System.md`"专属取证要点"逐条复盘,原理性背景见同目录`Principles.md`,具体差异结论本身见`../Log_System.md`。

## 逐条取证过程

### 1. DIAG协议栈两侧实现对比
**做法**:定位downstream(maili)`src/diag/`目录结构,以及QLI2.0对应recipe。
**证据**:downstream(maili)`diag_lsm*.c`/`mdlog/diag_mdlog.c`/`klog/diag_klog.c`/`socket_log/`/`uart_log/`/`java/`(JNI`com.qualcomm.qti.diagservice.libdiagwrapper`);QLI2.0`meta-qcom/recipes-test/diag/diag_git.bb`(拉取`github.com/linux-msm/diag`,BSD-3-Clause)+`diag-router_1.0.2.bb`+`libdiag_1.0.5.bb`,两者`RCONFLICTS`/`RPROVIDES:virtual-diag-router`互斥。
**落到结论**:对比总览表"DIAG协议栈"行、关键差异第2条("源码级核心组件"降级为"测试镶像/可选预编译二进制")。

### 2. Android兼容日志检索——命中后逐一排除误报
**做法**:对`meta-qcom`、`meta-qcom-distro`、`meta-audioreach`、`meta-security`、`meta-updater`执行`grep -rln "logd\|logcat"`全量检索。
**证据**:实际命中4个文件——`rsyslog.logrotate.qcom`、`organize_distro_discovery.patch`、`suricata_8.0.4.bb`、`0002-Makefile-don-t-set-uid-gid.patch`。逐一核查命中行后确认均为子串误报,分别是`rsyslogd`(2处)、`logdir`(2处)、`logdir`、`csyslogd`,没有一处是真正的logd守护进程或logcat命令。
**落到结论**:对比总览表"Android兼容日志"行(QLI2.0"无对应组件");影响与风险第3条明确写出零命中的4个文件及各自误报字段,而不是笼统写"未检索到"——这是"禁止仅凭关键字搜索为空断言功能消失"规则在本主题的具体落实,必须展示真实命中并逐一核查,不能靠"没搜到就是没有"。

### 3. 镜像集成范围逐一核实
**做法**:对`meta-qcom-distro/recipes-products/images/`下7个产品镜像逐一核对`CORE_IMAGE_BASE_INSTALL`字段。
**证据**:仅`qcom-multimedia-proprietary-image.bb`显式装了`libdiag-bin`;其余6个(console/container-orchestration/minimal/multimedia非proprietary版/networking/xfce-demo)出厂默认不含。
**落到结论**:影响与风险第1条——"QLI2.0量产镶像中diag相关能力的默认启用范围很窄",这个结论必须建立在"逐一核对7个镜像"而非"抽样判断"之上,因为规则要求机制是否默认启用要看真实构建配置而非代码库存在性。

### 4. CI产品镜像构建列表核实
**做法**:读取`meta-qcom/ci/qcom-distro.yml`的`target:`列表。
**证据**:量产列表不含`diag-router`;`diag-router`/`virtual-diag-router`只出现在`meta-qcom/recipes-test/images/initramfs-test-image.bb`测试镶像里。
**落到结论**:影响与风险第1条补充——"即量产SKU不会随任何产品镜像默认打包diag-router",区分"代码库里存在"与"CI实际会构建"。

### 5. rsyslog定制内容核实
**做法**:完整读取`meta-qcom-distro/recipes-extended/rsyslog/files/rsyslog.logrotate.qcom`。
**证据**:只解决轮转/留存策略(`/var/log/syslog`等按满100MB或7天轮转,保留20份归档),不包含任何脱敏/过滤规则。
**落到结论**:关键差异第3条——"需要与安全/合规团队确认落盘日志的敏感信息处理是否与downstream(maili)一致",这个待办本身是基于"读了实际内容确认没有脱敏规则"而非猜测。

### 6. android_compat功能定位澄清
**做法**:读取`src/android_compat/common/inc/`目录下头文件实际内容,而非只看目录名。
**证据**:`target.h`/`common_log.h`/`comdef.h`/`rex.h`/`qsocket.h`,确认为头文件级REX/QNX移植兼容层,用于让modem侧代码在Linux上编译。
**落到结论**:对比总览表"android_compat澄清"行——排除了"这是logcat/logd的downstream(maili)再实现"这一容易望文生义的误判,真正的logd/logcat落在`src/system/core`。

## 关于纠错记录

`rules/Platform_Features/Log_System.md`"已知易错点"明确记录本主题**暂无正式的"初步判断→核实后结论"纠错记录**,但有两处需要在复核时留意的"排除误判"提示(即上文第2、6条):`grep`命中不能直接采信为真实存在,必须逐行核查排除子串误报;`android_compat`目录名容易被望文生义误判为logd/logcat实现。这两处都不是"结论被推翻"式的纠错,而是取证过程中主动做的交叉核查,防止走入误判,已如实记录在此,不额外编造正式纠错记录。
