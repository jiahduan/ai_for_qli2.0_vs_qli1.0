# systemd_ 取证过程复盘

本文档复盘`systemd_.md`当前结论(版本对比、补丁去向追踪表、NEWS筛选)是怎么从检索动作一步步取得的,按`rules/Boot_Architecture/systemd_.md`"systemd专属取证要点"逐条展开。原理性背景见同目录`Principles.md`,具体差异结论本身见`../systemd_.md`。

## 逐项取证过程

### 1. systemd版本本身
**做法**:分别读取`systemd_255.21.bb`(源`git://github.com/systemd/systemd-stable.git` branch `v255-stable`)与`systemd_259.5.bb`(源主线仓库tag`v259.5`),复核SRC_URI/版本号一致。
**支撑结论**:《对比总览》表第1行。

### 2. vendor层.service定制数量与分布
**做法**:清点downstream(maili)`meta-qti-*`系列下的`.service`文件数量并按层归类(meta-qti-bsp 41、meta-qti-wlan(-prop) 16等);QLI2.0侧复核meta-qcom*仅`format-tee-partition.service`1个,meta-updater层6个具名unit。
**支撑结论**:《对比总览》表第2行,《关键差异》第1条(强调更可能是层成熟度差异而非架构精简)。

### 3. 三个downstream(maili)补丁的吸收/消失判定过程(补丁去向追踪表)
- **`Disable-unused-mount-points.patch`**:读取补丁改动内容(`src/shared/mount-setup.c`把securityfs挂载点注释掉);随后全局检索`securityfs`,范围限定**实际参与构建的层**(`meta-security`本体、`meta-security/meta-tpm`、`meta-qcom*`、`oe-core/meta`)——零命中。另发现有命中的`meta-integrity`(IMA appraisal),但进一步核实`build/conf/bblayers.conf`未收录该层,因此该命中不构成"功能仍被使用"的反例,判定为"功能不再需要"。
- **`fstab-generator-Honor-verity-enabled-cmdline.patch`**:读取补丁改动内容(`src/fstab-generator/fstab-generator.c`识别`verity=enabled`/`avb-verity`);全局检索`verity=enabled`、`arg_usr_verity`——零匹配,该结论**引用**自Bootargs.md已完成的取证(不重复检索,见`Principles.md`第3节分工原理),判定为"功能不再需要",并与Partition_Layout.md的Android安全分区消失结论构成三方证据链。
- **`sd-bus-Allow-extra-users-to-communicate.patch`**:读取补丁改动内容(`src/libsystemd/sd-bus/bus-convenience.c`的`sd_bus_query_sender_privilege()`硬编码放行uid 1000/1001);全局检索`sender_uid == 1001`——零匹配,判定为"服务于downstream(maili)特定Android风格uid体系,QLI2.0全树无该私有uid体系痕迹"。
**支撑结论**:《systemd补丁去向追踪》整张表。

### 4. NEWS逐行diff与筛选
**做法**:对两侧SRCREV对应的确切NEWS文件(systemd-stable`v255.21` vs systemd主线`v259.5`)做逐行diff,统计新增约4117行,再逐条筛选与本BSP启动路径直接相关的变化,排除掉不相关的大量特性(如多profile UKI、ukify签名选项、Varlink IPC扩展等)。
**筛出的4条及各自的进一步核实**:
1. v256引入`ProtectSystem=`在initrd默认启用——标记为"需要回归测试当前initrd/UKI内嵌逻辑是否有相关写操作",未下确定结论,如实标注待验证。
2. v256起`systemd-stub`移除TPM 1.2 PCR measurement支持——读取`meta-qcom/conf/machine/iq-9075-evk.conf`确认`MACHINE_FEATURES`含`tpm2`而非tpm1.2,判定"该项变化不影响现状"。
3. v258起`systemd-gpt-auto-generator`新增`root=dissect`/`root=bind:`语义——核对`esp-qcom-image.bb`里`UKI_CMDLINE`走的是静态`root=PARTLABEL=rootfs`,不经过gpt-auto-generator路径,判定"不适用"。
4. v259起journal默认存储模式由`auto`改为`persistent`——检索`meta-qcom*`范围内`journald.conf`级`Storage=`覆盖,未发现显式改回,判定"升级后会默认持久化落盘,需确认是否符合当前存储/日志策略预期"。
**支撑结论**:《影响与风险》第1条的四点具体NEWS影响分析。

## 关于纠错记录的说明

`rules/Boot_Architecture/systemd_.md`"已知易错点/纠错记录"一节明确写"本文档自身没有初步判断→核实后结论式的纠错记录,README《曾纠正过的结论》表也未收录systemd_专属条目"。本文档如实记录这一点,不编造一次不存在的纠正过程。但需要专门说明一个**交叉关注点**(不是本主题自身的纠错,是对相关主题纠错的追踪义务):本文档"dm-verity相关补丁消失"结论与Bootargs.md/Partition_Layout.md构成同一条三方证据链,而Bootargs.md/Boot_Flow.md所属的"UKI签名"结论曾被README纠正(初步误判为"已签名",核实后为"未签名",详见Bootargs.md和Boot_Flow.md各自的Execution_Report.md)。本文档虽不直接涉及UKI签名取证,但《对比范围》"明确排除"第1条已注明该结论的权威归属不在本文——复核本文档时应留意:若Boot_Flow.md侧的UKI签名措辞未来有变化,本文档中提及TPM/measured-boot相关NEWS影响分析的表述(《影响与风险》第1条第2点)是否需要同步复核用词,避免与Boot_Flow.md产生不一致的暗示。
