# WiFi_BT —— 规则

> 本文件对应产出文档 [output/System_Architecture/WiFi_BT/WiFi_BT.md](../../output/System_Architecture/WiFi_BT/WiFi_BT.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

## 强制规则

以下规则对所有主题文档硬性生效,不因主题不同而放宽。

### 1. 证据引用标准

任何结论性陈述必须能追溯到以下至少一种证据:
- 具体文件路径(尽量带行号),如`meta-qcom/classes-recipe/image_types_qcom.bbclass`第127-136行
- 检索命令及其实际输出,如`grep -rln "abctl|libabctl" meta-qcom meta-qcom-distro meta-updater`零匹配
- git commit hash / `git log`/`git describe`输出
- 官方文档原文引用(需注明来源与核实方式,见规则6)

**禁止**仅凭目录名或关键字搜索为空就断言"某功能已消失"——必须展示实际检索命令及零命中证据,并在可能时交叉检索多个关键字变体(如同时检索`abctl`与`libabctl`)。

### 2. 统一文档结构

每个主题文档必须按以下顺序包含章节(可在中间插入主题专属章节,但首尾两类不可省略):

0. `## 对比范围` — 三个固定字段,必须都出现:
   - **覆盖**:本文实际比较的子项列表,每项标明双侧目录/文件锚点。单条bullet的"锚点+说明"过长(经验值:超过约150字/接近一整段)时,拆成更细的子bullet,不要塞成一段长文字,保持列表可扫读
   - **明确排除**:本主题名义上涉及、但结论归属别的文档的项——不要求"正文已经字面提到过才能排除",只要读者可能预期在本文找、但实际该去别的文档找,就该排除。每条只写"项名 ——见[YY](相对路径/YY.md)",不展开排除理由(理由留给目标文档自己交代,或在本文正文引用处简要说明,不塞进这一行);用markdown链接而非书名号,保持和README索引表一致的可点击引用风格;有多条时每条单独一行列出(子bullet),不要用分号堆在同一行——方便脚本按行解析,也方便人工审阅
   - **待定边界**:暂时定不下来该归哪篇、先记录别漏掉的项;为空写"(无)"——如果是"核实过确认没有"而非"没检查",可以写成"(无,已核实XX)"这种形式简要说明核实范围,不算违反"为空写(无)"的要求;随本文档下次修订顺带复核,不单开复核周期;若长期悬而未决,同步进README《待拍板事项汇总》

   本节是文字化元信息(管辖边界、目录锚点、排除去向),不重复下面《对比总览》表已有的对比结论;《对比总览》也不解释某项为何不在表里——两节不互相转述。
1. `## 对比总览` — 一张`维度 | QLI1.0 | QLI2.0`表格,是文档骨架,让读者10秒内看到全貌
2. (可选)主题专属深挖章节 — 追踪表、抽样统计、专项验证等
3. `## 关键差异` — 综合性洞察,**不是对总览表的复述**,要回答"这些差异放在一起意味着什么"
4. `## 影响与风险` — 对下游团队/决策的具体影响,不做纯技术总结

### 2.1 WiFi_BT源码级分析方法论(8步,细化System_Architecture专属取证指引在本主题下的落地方式,不替代第2条的标准文档结构)

WiFi_BT本质是WLAN线(QCACLD/Prima→ath10k/ath11k/ath12k)与BT线(Fluoride→BlueZ5)两条连接技术线各自的架构迁移,以架构师视角做source-level分析,按下面顺序找证据,不从"驱动栈变了"这类抽象产品维度直接下结论:

1. **定位两条线各自的物理载体**:WLAN——QLI1.0是`meta-qti-wlan`(驱动recipe)+`meta-qti-wlan-prop`(平台守护进程recipe),QLI2.0是`ath10k`/`ath11k`/`ath12k`(随`linux-qcom`内核recipe统一编译,不是独立recipe);BT——QLI1.0是`meta-qti-bt`(Fluoride主栈)+`meta-qti-bt-prop`(专有组件),QLI2.0是`meta-qcom-distro/recipes-connectivity/bluez5/bluez5_%.bbappend`(标准BlueZ5)。
2. **看机型级核心变量的赋值点,不能只讲"存在ath10k/11k/12k"这类空话**:QLI1.0在WLAN recipe里用`MACHINE` override直接把芯片代号赋成变量(如`TARGET_WLAN_CHIP:vienna = "themisto"`),编译期确定;QLI2.0在机型dts里用`compatible`字符串声明BT侧具体芯片(如`&uart17`下`bluetooth { compatible = "qcom,wcn6855-bt"; }`),走标准Linux设备树探测框架,但WLAN侧(PCIe自枚举)反而没有对应的机型级静态声明——两侧"钉死芯片型号"的绑定层完全不同,要分别找,不能假设两侧用同一种绑定方式。
3. **看变体矩阵的物理组织方式**:WLAN——QLI1.0按芯片/项目拆分出十余个`qcacld32-ll-*`/`qcacld-hl*`/`qcacld30-*`recipe,一机型一(组)recipe;QLI2.0是`ath10k`/`ath11k`/`ath12k`三个驱动族随内核一次性全部编译出模块,具体哪颗芯片生效由运行时PCI枚举+`board-2.bin`固件匹配决定,不是机型conf里选出来的。BT——QLI1.0单一`fluoride_4.1.bb`+按`BTVENDOR` machine override可选挂`libbt-vendor`;QLI2.0单一`bluez5`,无按机型分支的vendor包。
4. **看平台守护进程/协议栈的绑定方式**:QLI1.0 WLAN侧`cnss-daemon`/`qsaharaservice`/`ftm`等专有daemon,BT侧`hci-qcomm-init`(`EXTRA_OECONF += "--enable-target=${BASEMACHINE}"`,机型名作为构建期参数传入而不是recipe级override)/`bttransport`/`xpan`;QLI2.0两条线均无这类专有daemon,协议栈落在标准`wpa_supplicant`/`hostapd`(WLAN)与BlueZ D-Bus(BT)。
5. **看固件与RF区域码/校准的绑定点**:QLI2.0标准`linux-firmware`+`wireless-regdb`+`board-2.bin`多variant容器(`bus/qmi-chip-id/qmi-board-id/variant`分段,dts侧`qcom,calibration-variant`声明);QLI1.0专有固件包+厂商私有区域码方案,无对应的机型级variant声明机制。
6. **看认证测试工具链**:QLI1.0`wlan-sigma-dut`(厂商fork);QLI2.0`sigma-dut`(标准WFA认证代理)+`wifi-test-suite`(WFA官方DUT测试套件);Sahara固件下载/WLAN FTM等量产测试能力在QLI2.0侧recipe层与固件物料层均需核实是否有等效物,不能只看recipe存在与否。
7. **精确到两个具体机型的WLAN/BT驱动变体接线链**(本主题证据链的核心,不做抽象产品线覆盖度调查)——见下方"专属取证要点"第7条,已实测确认QLI1.0**vienna**与QLI2.0**iq-9075-evk**各自WLAN芯片型号与BT接线方式。
8. **用DIAG旁证与上游维护状态佐证成熟度/风险**:`hci-qcomm-init`(QLI1.0)`DEPENDS += "diag time-genoff"`,即BT bring-up本身依赖DIAG协议栈,这是WLAN/BT与DIAG基础设施耦合关系的具体证据(整体架构对比归`Log_System.md`,本主题只取这一条耦合事实);`ath6kl-firmware`上游2014年起无提交,`db845c_gki.fragment`仅被Google/Linaro touch未被Qualcomm产品链路挂接,均是"专有→开源"迁移是否彻底、是否有历史遗留分支的佐证。

每一步的产出最终收敛进"专属取证要点",再由取证要点收敛成正文的对比总览/关键差异/影响与风险——取证要点是证据,正文是结论,不能反过来倒推。

### 3. 抽样声明

涉及大规模内容(补丁、commit、recipe)无法逐一核对时,必须:
- 明示抽样范围与方法(如"随机抽样`meta-qti-gst`全部144个补丁中的6个,按recipe分布统计")
- 明确抽样结论的局限,不得直接外推为总体结论而不加限定语(如用"存活率约9%"而非"补丁基本都丢了")

### 4. 纠错记录

当先前判断被新证据推翻时,禁止静默覆盖旧结论,必须:
- 在该主题文档内保留"初步判断 → 核实后结论"的对照(可用小节或表格形式,如Patch_Management.md的补丁总量纠正)
- 若纠正的结论足够重要(影响其他文档的判断或曾写入README汇总表),同步更新README.md《曾纠正过的结论》表

### 5. 风险分级

任何写入README《安全/合规风险清单》或《待拍板事项汇总》的发现,必须标注优先级:

| 等级 | 判定依据 |
|---|---|
| P0 | 影响范围广且不可逆(如安全校验机制整体消失、需要重建服务端基础设施) |
| P1 | 影响范围较大或需要专项决策,但有明确规避/替代路径 |
| P2 | 影响范围有限,属于工程执行层面的既定工作 |
| P3 | 边缘case或低优先级遗留问题 |

分级依据是"影响范围 × 不可逆性",不是主观感受;同一发现在不同产品线/团队视角下等级可能不同,应在文档中说明判定理由而非只写等级本身。

### 6. 交叉验证

当本地代码库证据不足以支撑结论(尤其是"上游行为是否符合规范""是否遵循最佳实践"类判断)时:
- 必须查找官方文档/release notes/迁移指南等权威来源(如对应的`reference/`子目录下的存档页面)交叉验证
- 明确标注验证状态:"已用XX来源核实"或"未能核实,标注为推测,待后续验证"
- 若本地环境网络受限无法直连官方站点,应将需要的页面存档到本主题的`reference/`子目录后再核实,而非跳过验证直接下结论

### 7. 范围交叉一致性

任何文档《对比范围》里的"明确排除",必须能在被指向的文档的"覆盖"字段里找到对应项;反之,任何"待定边界"项,不得同时被两篇文档都排除或都不提及。写完/改完一篇文档的《对比范围》后,必须检查它指向或被指向的文档是否需要同步更新。可用`scripts/check_scope_links.sh`辅助抓悬空引用(字符串级别粗检查,不能替代人工判断措辞是否准确)。

## System_Architecture 专属取证指引

系统级基础设施与硬件子系统对比。优先证据来源:
- 版本字符串:distro/layer的`.conf`文件(如`poky.conf`的`DISTRO_VERSION`)、`layer.conf`的`LAYERSERIES_COMPAT_core`
- 构建产物内版本信息:`bitbake`/内核源码内`git describe`、`__init__.py`等版本常量
- 子系统专有栈 vs 开源栈的判定:优先搜对应服务/驱动的顶层recipe与依赖(如Display看HWC/Composer vs DRM/KMS+Mesa,Audio看AudioReach源码树 vs meta-audioreach+PipeWire)
- 安全类结论(如SELinux策略)需要给出规则数量级对比(如"661文件"vs"约3个策略点"),不能只写"有/无"

## WiFi_BT专属取证要点(按2.1节8步方法论组织)

- **1.物理载体**:WLAN——QLI1.0`meta-qti-wlan`(驱动recipe)+`meta-qti-wlan-prop`(平台守护进程recipe);QLI2.0`ath10k`/`ath11k`/`ath12k`随`meta-qcom`引入的`linux-qcom`内核recipe统一编译产出,不是独立recipe。BT——QLI1.0`meta-qti-bt`(`fluoride_4.1.bb`/`btvendorhal_4.1.bb`/`hidl-client_4.1.bb`)+`meta-qti-bt-prop`(`hci-qcomm-init_4.1.bb`/`bttransport_4.1.bb`/`xpan_4.1.bb`);QLI2.0`meta-qcom-distro/recipes-connectivity/bluez5/bluez5_%.bbappend`(标准BlueZ5)
- **2.核心变量赋值点**:QLI1.0在WLAN recipe里用`MACHINE`override把芯片代号直接赋值(如`qcacld32-ll-vienna-le.bb`第10行`TARGET_WLAN_CHIP:vienna = "themisto"`),编译期确定;QLI2.0在机型dts里用`compatible`字符串声明BT侧具体芯片(`lemans-evk.dts`第1100-1108行`&uart17`下`bluetooth { compatible = "qcom,wcn6855-bt"; max-speed = <3200000>; ... }`),WLAN侧(ath11k走PCIe自枚举,`lemans-evk.dts`/`lemans.dtsi`均未见wifi专属dts节点)反而没有对应的机型级静态声明——已实测确认两侧"钉死芯片"的绑定层完全不同(QLI1.0在bb层,QLI2.0在dts层,且QLI2.0仅BT侧有dts静态声明)
- **3.变体矩阵组织方式**:QLI1.0`meta-qti-wlan/recipes/wlan/`下`qcacld32-ll-{vienna-le,neo-kiwi,kiwi,hst,qcs40x,peach,debug,cologne,oot,ar-sg1}`等十余个按芯片/项目拆分的recipe(已用`find`实测枚举);QLI2.0`ath10k`/`ath11k`/`ath12k`三个驱动族随内核一次性全部编译出模块,具体哪颗生效由运行时PCI枚举+`board-2.bin`固件匹配决定(已用`iq-9075-evk`真实rootfs manifest核实:即便SoC层`packagegroup-machine-essential-qcom-qcs9100-soc`只"essential"声明了`kernel-module-ath11k-pci`一项,真实镶像仍因`qcom-minimal-image.bb`的`CORE_IMAGE_BASE_INSTALL += "kernel-modules"`这一catch-all伪包,把该机型内核编译出的`ath10k-core/pci/sdio/snoc`、`ath11k`/`ahb`/`pci`、`ath12k`/`wifi7`全部模块都装入镶像,不受SoC essential列表约束——这是本次新增的机制性解释,精确化而非推翻此前"已写入iq-9075-evk真实rootfs manifest"这一既有表述)
- **4.平台守护进程/协议栈绑定方式**:QLI1.0 WLAN侧`cnss-daemon`/`qcacld-utils`/`hal-proxy-daemon`/`qsaharaservice`/`ftm`/`wlan-services`(均`meta-qti-wlan-prop`),BT侧`hci-qcomm-init_4.1.bb`(`EXTRA_OECONF = "--with-glib --enable-target=${BASEMACHINE} --enable-rome=${BASEPRODUCT}"`,机型名`BASEMACHINE`作为构建期参数传入,而非recipe级MACHINE override)+`bttransport`+`xpan`;`packagegroup-qti-bluetooth.bbappend`(`meta-qti-bt-prop`)对所有机型无条件追加`bttransport`+`hci-qcomm-init`两个RDEPENDS(已核实无machine override,即只要该prop层在`bblayers.conf`里就对全部机型生效);QLI2.0两条线均无对应专有daemon,全树检索`cnss`/`sahara`/`ftm`/`hci-qcomm`/`bttransport`/`xpan`均零命中(沿用此前检索结论)
- **5.固件与RF区域码/校准绑定点**:QLI2.0`wireless-regdb`+`board-2.bin`多variant容器(`bus/qmi-chip-id/qmi-board-id/variant`分段)+dts侧`qcom,calibration-variant`声明(`qrb2210-rb1.dts`→`Thundercomm_RB1`、`qcs6490-rb3gen2.dts`→`Qualcomm_rb3gen2`、`talos-evk-som.dtsi`→`QC_QCS615_Ride`、`lemans-ride-common.dtsi`→`QC_SA8775P_Ride`);`iq-9075-evk`所用`lemans-evk.dts`本身未声明`qcom,calibration-variant`,落到通用/默认board-id项;QLI1.0专有固件包,无对应的机型级variant声明机制
- **6.认证测试工具链**:QLI1.0`wlan-sigma-dut_git.bb`(厂商fork);QLI2.0`sigma-dut_git.bb`(`github.com/qualcomm/sigma-dut`标准WFA认证代理)+`wifi-test-suite_10.10.1.bb`(WFA官方DUT测试套件);Sahara固件下载/WLAN FTM等效工具链已解包`linux-firmware_20260519.tar.xz`对`ath11k`/`ath12k`全部136个固件文件名做`utf`/`test`/`ftm`关键词检索,确认零命中(recipe层与固件物料层双重确证)
- **7.两个具体机型的WLAN/BT驱动变体接线链(本次新增,已实测确认,是本主题最核心的证据)**:
  - **vienna(QLI1.0)**:`MACHINE=vienna`——`poky/meta-qti-bsp/conf/machine/vienna.conf`(`MACHINE_MNT_POINTS`含`/vendor/bt_firmware`,`MACHINE_FEATURES`含`qti-audio`等,未`DISTRO_FEATURES:remove`掉wifi/bt相关能力);已核实`packagegroup-qti-wifi.bb`第22行`QCACLD32_LL:vienna="qcacld32-ll-vienna-le"`,对应recipe`meta-qti-wlan/recipes/wlan/qcacld32-ll-vienna-le.bb`第10行显式`TARGET_WLAN_CHIP:vienna = "themisto"`——即QLI1.0侧vienna机型的WLAN芯片代号是`themisto`(仅在此一处recipe出现,已用`grep -rl themisto`全树检索确认无第二处引用,即代号本身未在本地源码库留下更多物理型号信息);BT侧`packagegroup-qti-bluetooth.bb`第14-15行`BTVENDOR`只对`qcm6490`/`kera`置`True`,`vienna`无override即走默认`False`(不挂`libbt-vendor`),即vienna的BT组合是`fluoride`+`bt-app`+`bt-dlkm-kernel`+`hidl-client`+`bthost-ipc`+`btdevicetree`(无vendor HAL)+`meta-qti-bt-prop`无条件追加的`hci-qcomm-init`/`bttransport`;已检索`meta-qti-bt`/`meta-qti-bt-prop`全树`vienna`关键字,除packagegroup RDEPENDS组合外无machine级override,也未在QLI1.0本地内核dts源码树(`src/kernel-6.18/kernel_platform/qcom/opensource/devicetree/qcom/vienna.dtsi`及其引用链)里找到蓝牙芯片的静态dts声明——即QLI1.0侧BT芯片型号无法像WLAN的`themisto`一样从recipe层直接钉死,只能确认走"`hci-qcomm-init --enable-target=vienna`+无vendor HAL"这条通用路径,已作为边界如实记录,不强行凑一个具体型号
  - **iq-9075-evk(QLI2.0)**:`MACHINE=iq-9075-evk`——`meta-qcom/conf/machine/iq-9075-evk.conf`(`require conf/machine/include/qcom-qcs9100.inc`,即`SOC_FAMILY="qcs9100"`);已核实`meta-qcom/recipes-bsp/packagegroups/packagegroup-machine-essential.bb`第201-213行`packagegroup-machine-essential-qcom-qcs9100-soc`声明`kernel-module-ath11k-pci`;真实构建产物`build/tmp/deploy/images/iq-9075-evk/qcom-robotics-image-iq-9075-evk.rootfs.manifest`(2026-08-25生成)实测确认`ath10k-core/pci/sdio/snoc`、`ath11k`/`ath11k-ahb`/`ath11k-pci`、`ath12k`/`ath12k-wifi7`模块及`linux-firmware-ath11k-qca6698aq`/`ath11k-wcn6855`/`ath12k-qcc2072`/`ath12k-qcn9274`/`ath12k-wcn7850`固件全部装入镶像(见第3条机制解释);BT侧已实测读取`build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/boot/dts/qcom/lemans-evk.dts`第1100-1108行,确认`&uart17`下静态声明`bluetooth { compatible = "qcom,wcn6855-bt"; max-speed = <3200000>; vddrfacmn-supply = <&vreg_wcn_3p3>; ... }`,即iq-9075-evk的BT芯片明确是**WCN6855**的BT半区,通过UART17以`hci_uart`/`btqca`传输(defconfig已确认`CONFIG_BT_HCIUART_QCA=y`),用户空间是标准BlueZ5(`bluez5_%.bbappend`仅`0001-Use-system-bus-instead-of-session-for-obexd.patch`+UTF16/32 glibc-gconv依赖,无vendor HAL);WLAN侧因PCIe自枚举无对应dts静态节点(已grep`lemans-evk.dts`/`lemans.dtsi`确认零命中wifi/ath相关compatible字符串,只有`&pcie0`/`&pcie1`两个通用PCIe控制器节点`status="okay"`),但rootfs manifest里`linux-firmware-ath11k-wcn6855`固件包与dts声明的`wcn6855-bt`正好是同一枚WCN6855combo芯片的两个半区——即iq-9075-evk上"BT芯片型号"比"WLAN芯片型号"更容易从源码钉死(dts显式声明vs运行时枚举),但两者指向同一物理芯片这一点已交叉印证
  - 两个机型对比揭示的架构差异:QLI1.0把"机型→芯片型号"这一绑定做成recipe/packagegroup层的显式变量赋值(`TARGET_WLAN_CHIP:vienna`、`BTVENDOR:kera`),编译期就能从源码直接读出;QLI2.0把WLAN侧这一绑定让渡给运行时PCI枚举+固件匹配(源码层只能看到"这个SoC家族essential声明哪个,以及镶像实际打包了哪些候选项"),只有BT侧因UART非自枚举而保留了dts级的显式声明——这不是"QLI2.0信息更少",而是两代驱动模型本身的探测方式不同(mac80211/PCI标准探测 vs 厂商专有驱动手工绑定)
- **8.DIAG旁证与上游维护状态佐证成熟度/风险**:`hci-qcomm-init_4.1.bb`第9-10行`DEPENDS += "diag time-genoff"`,即QLI1.0侧BT bring-up本身依赖DIAG协议栈(与`meta-qcom/recipes-test/diag-router_1.0.2.bb`+`libdiag_1.0.5.bb`分工边界一致,整体架构对比归`Log_System.md`,本主题只取这一条耦合事实);对`kernel_platform/common`仓库(remote`quic`)跑`git log --all`核实`db845c_gki.fragment`历史提交作者(全部是`@google.com`/`@linaro.org`);WebFetch核实`github.com/qca/ath6kl-firmware/commits/master.atom`确认上游最后提交日期(2014-06-17)
- **已验证的检索方式(汇总)**
  - `MACHINE=qcom-armv8a bitbake-getvar MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS`实测变量解析结果,核对与`packagegroup-rb1/rb2/rb3gen2/rb5-firmware`等静态声明是否一致
  - 解包`linux-firmware_20260519.tar.xz`,读取`board-2.bin`内`bus=ahb,qmi-chip-id=N,qmi-board-id=M[,variant=NAME]`分段结构;对`ath11k`/`ath12k`全部136个固件文件名做`utf`/`test`/`ftm`关键词检索,确认零命中
  - grep`qcom,calibration-variant`属性跨多机型dts,确认已声明variant清单(Thundercomm_RB1/Qualcomm_rb3gen2/QC_QCS615_Ride/QC_SA8775P_Ride)
  - 直接读取真实构建产物(`build/tmp/work-shared/<machine>/kernel-source/arch/arm64/boot/dts/qcom/*.dts`+`build/tmp/deploy/images/<machine>/*.rootfs.manifest`)核实机型级dts声明与镶像实际内容,而非只读静态conf/recipe猜测
- **已知易错点/纠错记录**:有(文档内部,未写入README)——文档专设"关于'QLI1.0=全专有驱动'的核实"一节,核实发现QLI1.0内核树客观携带完整可编译的`ath10k`/`ath11k`/`ath12k`源码及`db845c_gki.fragment`(仅被Google/Linaro touch,未被Qualcomm产品链路挂接)。修正结论:"QLI1.0所有已知量产机型的packagegroup均强制选择QCACLD"(镜像级/产品级结论)成立,但"QLI1.0代码库完全没有ath代码"(代码库级结论)不成立,是过度简化。本次新增易错点:不要只看`packagegroup-machine-essential.bb`某SoC分组"essential"声明的ath模块列表就断言"这个机型只用这一个ath驱动族"——真实镶像可能因`kernel-modules`这类catch-all IMAGE_INSTALL机制装入该机型内核编译出的全部ath10k/11k/12k模块,"essential声明"只是下限,不是上限,必须用真实rootfs manifest核实。
