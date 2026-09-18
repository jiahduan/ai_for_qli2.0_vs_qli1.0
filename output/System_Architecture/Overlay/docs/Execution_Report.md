# Overlay 规则执行逻辑细节报告

本文档记录`Overlay.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/Overlay.md`"Overlay专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Overlay.md`。

## 1. rootfs overlayfs方案核实

**做法**:核对downstream(maili)`qimage-ext4.bbclass`的`gen_overlayfs()`、`overlay-mounter_1.0.bb`专用挂载器、`overlayfs.cfg`(`CONFIG_OVERLAY_FS=y`);对QLI2.0本次复核重新跑`grep -rln overlayfs-etc meta-qcom meta-qcom-distro meta-qcom-robotics-sdk`确认零处inherit;用`debugfs -R "cat /etc/fstab"`直接读取实际构建镶像`qcom-robotics-image-iq-9075-evk.rootfs.ext4`内的`/etc/fstab`。
**证据**:QLI2.0侧`overlayfs-etc.bbclass`存在但未被任何层inherit;实际镶像`/`挂载项是`auto defaults`(无`ro`),`/etc`、`systemd/system`均未见overlay相关mount unit——即该镶像是可写根、未启用overlayfs-etc,不是配置推断而是直接读取镶像文件得到的事实。
**落到结论**:对比总览表(rootfs)"实现方式""是否默认启用"两行,"影响与风险"节"当前默认构建形态下既没有downstream(maili)式overlay-mounter,也没有开启OSTree原子只读根"的判断。

**本次复核新发现的边界点**:重新grep确认QLI2.0实际构建产物`.config`里`CONFIG_OVERLAY_FS=m`真实存在,与对比总览表"内核配置"行QLI2.0列"不适用(机制不同)"的表述并非完全等价——内核侧overlay文件系统能力本身存在,只是当前没有任何上层机制去使用它。这一点已记录在"覆盖"字段作为边界澄清,不是纠错(未改动原表述,只是补充记录取证细节)。

## 2. 设备树dtbo overlay源文件与构建链核实

**做法**:统计downstream(maili)385个`*-overlay.dts`分布(`opensource/display-devicetree`209、`mm-devicetree`96、`proprietary/display-devicetree`52、`mm-devicetree`28);核对`do_merge_techpack_dtbos`任务与`BUILD_WITH_TECHPACKS`开关变量;核对QLI2.0`linux-qcom-dtbbin.bbclass`与`dtb-fit-image.bbclass`的职责边界及`qcs615-ride.conf`的`LINUX_QCOM_KERNEL_DEVICETREE`实值。
**证据**:两套构建链路的机制差异(动态扫描合并 vs 声明式FIT映射)。
**落到结论**:对比总览表(设备树Overlay)"Overlay源文件规模""构建系统归属""编译recipe""合并机制""开关变量""产物格式"多行。

## 3. downstream(maili) techpack overlay是否真实交付的四类交叉证据

**做法**:①核对构建描述文件类型(recipe/bbclass);②核对`do_merge_techpack_dtbos`合并逻辑;③核对实际产物文件名(如`tech_dtbs/pebble-mm-atp-overlay.dtbo`)与源码dts文件名是否逐字对应(仅扩展名不同);④对最终融合dtb直接`dtc -I dtb -O dts`反解,实测命令`dtc -I dtb -O dts pebblep-pebble-hfi-core-...-0x3ed5501da86a4297.dtb`,在输出第20956-21147行区间读到`qcom,hw-fence`节点,第22202行读到`sde_dp = "/soc/qcom,dp_display"`别名。
**证据**:四类独立证据相互印证,camera techpack(hw-fence)与display techpack(sde/dp)确实被合入同一枚最终产物dtb。
**落到结论**:"关键差异"节"downstream(maili)的techpack overlay已确认是真实交付内容而非死代码"的判断。

## 4. QLI2.0设备树dtbo是否真实参与最终构建——纠错记录(本文档取证重点)

**初步判断**:仅看到`linux-qcom-dtbbin.bbclass`里`# Skip DTBOs`的注释,第一轮结论是"QLI2.0侧dtbo构建路径不明/可能未真正参与最终镶像"。

**核实过程**:进一步查找与`linux-qcom-dtbbin.bbclass`并行的另一份class,找到`dtb-fit-image.bbclass`,确认它是职责互补的另一条路径,专门负责dtbo,内含`FIT_DTB_COMPATIBLE`声明式映射与`do_generate_qcom_fitimage`任务。用`ls build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/image/boot/*.dtbo`实测确认真实产出9个`.dtbo`文件(`lemans-staging`/`lemans-evk-emmc`/`lemans-el2`等);读取`qcs615-ride.conf`第16-18行`LINUX_QCOM_KERNEL_DEVICETREE ?= "qcom/talos-el2.dtbo qcom/talos-staging.dtbo"`,确认dtbo被写进machine级配置实值。

**核实后结论**:确认参与,证据链完整——`# Skip DTBOs`是`linux-qcom-dtbbin.bbclass`主动跳过dtbo条目、把这部分工作完全交给`dtb-fit-image.bbclass`处理的有意设计,不是遗留未清理代码,两条class职责边界清晰、互不重叠。

**落到结论**:"纠错记录:QLI2.0设备树dtbo是否真实参与最终构建"表格,以及"关键差异"节"'Skip DTBOs'是有意为之的正常设计而非遗留未清理代码"的判断。该纠错已同步进README.md《曾纠正过的结论》表。本次复核重新grep`# Skip DTBOs`注释与重新`find`点数9个dtbo文件,确认结论未变。

## 5. audio/eva overlay承接机制排查

**做法**:先在`fit-dtb-compatible-linux-qcom.inc`及其base(合计298行)全文grep`audio`/`eva`/`hw-fence`;发现"audio"字样有命中后进一步核查发现是路径/命名巧合(如`dtb-fit-image.bbclass`、camera测试patch文件名带"audio"字样),再把grep范围扩大到`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-audioreach`全层并改用整词匹配`grep -rlw eva`复核。
**证据**:两轮检索(先窄范围扩展关键字排查巧合命中,再扩大范围整词匹配)均确认0命中。
**落到结论**:"关键差异"节"audio/eva类专有overlay目前未找到对应承接机制……代码侧线索已用尽,承接机制在当前快照下确实不存在"的判断,是规则1"禁止仅凭关键字搜索为空断言"要求下,交叉检索多个关键字变体并排除假阳性后才下的结论。
