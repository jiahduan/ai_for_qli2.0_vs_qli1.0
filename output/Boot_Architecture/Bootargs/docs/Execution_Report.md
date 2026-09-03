# Bootargs 取证过程复盘

本文档复盘`Bootargs.md`当前结论是怎么从检索动作一步步取得的,按`rules/Boot_Architecture/Bootargs.md`"Bootargs专属取证要点"逐条展开。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Bootargs.md`。

## 逐项取证过程

### 1. perf构建cmdline拼接方式
**做法**:直接读取QLI1.0`pebble.conf`的`CONSOLE_PARAM:qti-distro-perf=""`字段与QLI2.0`esp-qcom-image.bb`的`UKI_CMDLINE`字段,逐字对比两侧拼接cmdline的写法。
**证据**:前者是构建期把console参数烘焙为空字符串,后者是`UKI_CMDLINE = "root=${QCOM_BOOTIMG_ROOTFS} rw rootwait console=${KERNEL_CONSOLE}"`的显式变量拼接。
**支撑结论**:《对比总览》表第1行。

### 2. 真正生效cmdline的产生机制来源
**做法**:定位QLI1.0侧cmdline并非在Yocto配置里能看全,继续往运行时找,读取`src/bootctrl/abctl/libabctl.cpp`中`SLOT_SUFFIX_STR`及其对`/proc/cmdline`的解析逻辑。
**证据**:确认QLI1.0的root=、slot_suffix等关键字段是ABL在运行时动态拼出来的,源码仓库本身看不到最终形态;QLI2.0则是`UKI_CMDLINE`一次性构建期确定。
**支撑结论**:《对比总览》表第2行,《关键差异》第1条"审计方式差异"。

### 3. 其他机型cmdline完整示例
**做法**:抽样读取QLI1.0`qcs610-odk-64.conf`完整cmdline字符串;QLI2.0侧检索各机型`KERNEL_CMDLINE_EXTRA`追加项,复核`qcom-qcs8300.inc`第12行、`qcom-qcm2290.inc`第11行的具体追加值,RT内核追加项交叉引用RT.md结论而不重新取证。
**支撑结论**:《对比总览》表第3行。

### 4. root=语法
**做法**:比较两侧`root=`字段的字面写法。
**证据**:QLI1.0隐式依赖运行时/分区表决定的A/B slot,QLI2.0显式静态`root=PARTLABEL=rootfs`。
**支撑结论**:《对比总览》表第4行,《关键差异》第1条。

### 5. verity/AVB相关cmdline参数与systemd补丁交叉印证
**做法**:全局检索`verity=enabled`、`avb-verity`、`arg_usr_verity`,范围限定meta-qcom*,并读取QLI1.0`fstab-generator-Honor-verity-enabled-cmdline.patch`确认其识别的正是这些字符串。
**证据**:QLI2.0侧检索结果为零匹配。进一步读取QLI1.0`poky/meta-qti-bsp/classes/`下8个dm-verity/AVB相关bbclass文件名,确认QLI1.0侧cmdline的verity参数不是孤立存在,而是配合一整套镶像校验机制;QLI2.0中未见任何一个对应class。
**支撑结论**:《对比总览》表第5行,《与systemd补丁的交叉印证》整节,《关键差异》第3条。

### 6. console参数来源规范化
**做法**:读取`meta-qcom/conf/machine/include/qcom-base.inc`第19行`SERIAL_CONSOLES ?= "115200;ttyMSM0"`,对比QLI1.0各机型手写字符串的不一致情况。
**支撑结论**:《对比总览》表第6行。

### 7. 根文件系统完整性校验替代方案排查
**做法**:全局检索`fs-verity`/`fsverity`/`veritysetup`/`dm-verity`(范围meta-qcom*),并读取`UKI_CMDLINE`确认`rw`而非`ro`、`DISTRO_FEATURES`/`EXTRA_IMAGE_FEATURES`是否含`read-only-rootfs`。
**证据**:均为零命中/未添加,确认QLI2.0当前没有任何完整性校验替代方案,是纯ext4无校验。
**支撑结论**:《对比总览》表第7行,《影响与风险》第3条。

## 纠错记录复盘:"UKI是否签名"这一交叉引用结论

本主题不直接对UKI签名机制取证(权威取证方是Boot_Flow.md,见`Principles.md`第3节的边界原理),但《关键差异》第2条和《影响与风险》第1条引用了这个结论来解释"cmdline构建期固化"的安全含义,因此有必要复盘这条结论本身经历的纠正过程:

- **初步判断**:cmdline构建期静态烘焙进UKI,直觉上容易读成"签名后不可变"——即默认认为静态化=已经过secure boot签名固定。
- **发现问题**:全局检索`UKI_SB_KEY`/`UKI_SB_CERT`/`sbsign`,范围限定`meta-qcom*`/`meta-security*`/`meta-updater`/`build/conf`,结果为**零命中**。
- **核实后结论**:更正为"当前未签名"——`oe-core/meta/classes-recipe/uki.bbclass`第85-87行确实提供了`UKI_SB_KEY`/`UKI_SB_CERT`签名钩子,但当前默认构建没有配置任何签名密钥/证书,即UKI这套"能装载签名"的机制处于"能力在场但未上岗"状态。
- **影响范围**:该条已同步进README《曾纠正过的结论》表,条目名"QLI2.0 UKI是否签名(Boot_Flow/Bootargs)",提示这不只是本主题内部认知调整,而是影响了两篇文档共同的结论措辞,因此需要在两篇文档间保持一致。
- **本文档如何体现这次纠正**:《影响与风险》第1条明确写"cmdline固化不能简单等同于更安全",正是吸收这次纠正后的表述,避免读者把"构建期固化"和"已签名防篡改"混为一谈。
