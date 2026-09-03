# Partition_Layout 取证过程复盘

本文档复盘`Partition_Layout.md`当前《对比总览》表是怎么从检索动作一步步取得的,按`rules/Boot_Architecture/Partition_Layout.md`"Partition_Layout专属取证要点"逐条展开。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Partition_Layout.md`。

## 逐项取证过程

### 1. 分区总数(含一次纠错)
**做法**:不满足于数配置文件里的条目数,坚持以**实际构建产物**为准——QLI1.0读取`build-qti-distro-camerastack-debug/tmp-glibc/deploy/images/pebble/qti-multimedia-image/rawprogram[0-9].xml`,按`label=`字段去重计数;QLI2.0同法读取`build/tmp/deploy/images/iq-9075-evk/partitions/iq-9075-evk/ufs/rawprogram[0-9].xml`。
**初步判断**:QLI2.0侧首次计数得到67个。
**核实过程**:重新按`label=`去重复核。
**核实后结论**:更正为66个。
**支撑结论**:《对比总览》表"分区总数"行(含纠错标注)。此条未再单独写入README(未涉及跨文档判断依赖)。

### 2. 上游qcom-ptool源码条目数与实际构建产物的差异
**做法**:读取`build/downloads/git2/github.com.qualcomm-linux.qcom-ptool.git`下`platforms/iq-9075-evk/ufs/partitions.conf`的`--partition`条目数(72个),与实际构建产物66个对比,发现不完全一致。
**证据与解释**:核对差异原因为source配置里部分条目对应GPT/backup/占位段,不对应实际下发的独立分区,因此以实际构建产物计数为准,不以源配置条目数为准。
**支撑结论**:《对比范围》"覆盖"第2条,以及分区总数行的注释说明。

### 3. 同芯片剥离机型因素的控制对比(方法论核心)
**做法**:为了把"产品形态换代"和"架构选择"两个变量分开(见`Principles.md`第3节),找双侧都覆盖的相同芯片`qrb5165-rb5`,分别读取QLI1.0`poky/meta-qti-bsp/conf/machine/partition/qrb5165-rb5-partition.conf`(90个`--partition`条目)与QLI2.0外部仓库`qcom-ptool`的`platforms/qrb5165-rb5/ufs/partitions.conf`(77个条目),确认两者均为Android式A/B布局(xbl_a/tz_a/hyp_a/aop_a/abl_a/boot_a/boot_b/keymaster_a/dtbo_a/vbmeta_a俱全)。
**支撑结论**:《关键差异》第1条——证明"156→66"这个数字不能直接读成QLI2.0精简了58%能力,同芯片对比是90 vs 77,说明QLI2.0架构本身并不必然抹掉Android式分区,分区精简主要是iq-9075-evk这个具体机型的选择。

### 4. 底层固件A/B、OS层A/B、Android安全HAL分区族、新增分区
**做法**:逐类清点rawprogram xml里的分区label,并读取`pebble.conf`的`MACHINE_FEATURES += "qti-ab-boot"`确认QLI1.0侧A/B模型的配置声明。
**支撑结论**:《对比总览》表对应行。

### 5. A/B槎位管理组件对比
**做法**:QLI1.0侧读取`src/bootctrl/abctl/libabctl.cpp`支持的命令行参数(`--set_active`/`--boot_slot`等);QLI2.0侧读取`recipes-support/qbootctl/qbootctl_git.bb`的`SRC_URI`(`github.com/linux-msm/qbootctl`),并复核`rb1-core-kit.conf`的`MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "qbootctl"`仍存在。
**支撑结论**:《对比总览》表"A/B管理组件"行——确认开源等价物已存在于meta-qcom上游但需显式挂载,不是能力缺失。

### 6. xbl_a/b等低层固件槎位fallback行为的排查(检索范围收窄的教训)
**做法**:先在`trusted-firmware-a-qcom`/`meta-qcom*`范围内检索`BOOT_ROM`等疑似A/B fallback关键字。
**初步结果**:零命中,且进一步核实发现`BOOT_ROM`字符串命中的是XPU内存保护区域命名,与A/B切换机制语义不同(需人工甄别排除误报)。
**扩大检索范围**:没有停在"零命中=功能不存在",转而查`u-boot-qcom`实际拉取的上游仓库(`git://github.com/qualcomm-linux/u-boot.git`)的文档,在`doc/board/qualcomm/rdp.rst`(IPQ9574/RDP机型文档)里找到watchdog复位→XBL切换bank重试→双bank失败进EDL的描述。
**结论限定**:明确标注这是同一固件家族的旁证,不是iq-9075-evk(QCS9100)专属证据,严格结论仍需向QCT固件团队确认,已记入《待确认》节而非直接写入正文结论。
**支撑结论**:《待确认》节;《对比范围》"待定边界"字段的记录依据。

## 方法论教训小结

本主题两处过程值得单独强调:一是"分区总数"的67→66属于常规复核纠错,不涉及跨文档影响;二是"BOOT_ROM零命中"到"rdp.rst旁证"的检索范围收窄过程,提示"零命中不代表功能不存在,可能是检索范围不够广"——这条经验已写入`rules/Boot_Architecture/Partition_Layout.md`的易错点提醒,后续复核类似"某机制未找到证据"的结论时应参考这个先例,先确认检索范围是否已覆盖上游实际拉取的仓库,而不是止步于本地BSP层的零命中。
