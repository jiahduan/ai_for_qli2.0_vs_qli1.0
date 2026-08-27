# Boot Architecture — Bootargs

## 对比范围

- **覆盖**:
  - perf构建cmdline的拼接方式(`pebble.conf`的`CONSOLE_PARAM:qti-distro-perf=""` vs `esp-qcom-image.bb`的`UKI_CMDLINE = "root=${QCOM_BOOTIMG_ROOTFS} rw rootwait console=${KERNEL_CONSOLE}"`字符串本身,已复核变量取值未变)
  - 真正生效cmdline的产生机制来源(ABL运行时动态拼接+`libabctl.cpp`对`/proc/cmdline`中`SLOT_SUFFIX`的解析 vs 构建期完全静态确定);仅限"内容由谁/何时拼出来"这一层,不含该机制所处的启动链阶段划分或是否有签名保护
  - 其他机型cmdline完整示例对比(`qcs610-odk-64.conf`;QLI2.0侧`KERNEL_CMDLINE_EXTRA`逐机型追加项,已复核`meta-qcom/conf/machine/include/qcom-qcs8300.inc`第12行`arm64.nopauth`、`qcom-qcm2290.inc`第11行`clk_ignore_unused pd_ignore_unused`;RT内核追加项交叉引用RT.md)
  - root=语法(隐式依赖A/B slot vs 显式静态`root=PARTLABEL=rootfs`)
  - verity/AVB相关cmdline参数检索及其与systemd fstab-generator补丁吸收情况的交叉印证(`verity=enabled`/`avb-verity`/`arg_usr_verity`,已在meta-qcom*范围复核仍为零匹配)
  - console参数来源规范化(各机型手写字符串 vs `SERIAL_CONSOLES`/`KERNEL_CONSOLE`标准变量,已复核`meta-qcom/conf/machine/include/qcom-base.inc`第19行`SERIAL_CONSOLES ?= "115200;ttyMSM0"`)
  - 根文件系统完整性校验替代方案排查(dm-verity/AVB全套8个bbclass消失、`fs-verity`/`fsverity`/`veritysetup`/`dm-verity`在meta-qcom*范围复核仍为零命中、`UKI_CMDLINE`为`rw`非`ro`)
- **明确排除**:
  - UKI secure boot签名机制本身的取证与权威结论(`UKI_SB_KEY`/`UKI_SB_CERT`/`sbsign`零命中的判定,及该结论在README的纠错记录归属) ——见[Boot_Flow](Boot_Flow.md)
  - 启动链各阶段角色、Bootloader身份、内核镜像格式、initramfs机制、root挂载执行主体 ——见[Boot_Flow](Boot_Flow.md)
  - systemd层fstab-generator补丁的具体改动内容与吸收判定过程 ——见[systemd_](systemd_.md)
  - Android安全HAL分区消失的具体清单与分区总数对比 ——见[Partition_Layout](Partition_Layout.md)
  - OTA/Recovery完整性校验替代方案的产品级决策 ——见[OTA_Mechanism](../Platform_Features/OTA_Mechanism.md)
- **待定边界**:(无,已核实本文cmdline相关子项与Boot_Flow/systemd_/Partition_Layout的归属边界已明确划清,不存在悬空指向;实机`/proc/cmdline`抓取属于取证方法局限而非归属不明,已在下文《待确认》节单独跟踪)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| perf构建cmdline | `pebble.conf`: `CONSOLE_PARAM:qti-distro-perf=""`(构建期烘焙为空字符串) | `esp-qcom-image.bb`: `UKI_CMDLINE = "root=${QCOM_BOOTIMG_ROOTFS} rw rootwait console=${KERNEL_CONSOLE}"` |
| 真正生效的cmdline来源 | ABL运行时动态拼接(root=、androidboot.slot_suffix、skip_initramfs等),证据:`libabctl.cpp`中`SLOT_SUFFIX_STR`及对`/proc/cmdline`的解析 | 构建期完全确定:`root=PARTLABEL=rootfs rw rootwait console=ttyMSM0,115200` |
| 其他机型完整示例 | `qcs610-odk-64.conf`: `"noinitrd rootwait ... androidboot.hardware=qcom androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 service_locator.enable=1 firmware_class.path=/lib/firmware/updates msm_rtb.filter=0x237 hibernate=nocompress noswap_randomize verity=enabled"` | 个别机型追加`KERNEL_CMDLINE_EXTRA`(如qcs8300追加`arm64.nopauth`;qcm2290追加`clk_ignore_unused pd_ignore_unused`;RT内核追加`isolcpus=/irqaffinity=/rcu_nocbs=/rcupdate.rcu_expedited=/cpuidle.off= efi=runtime`,详见output/System_Architecture/RT.md) |
| root=语法 | 隐式依赖运行时/分区表(A/B slot)确定 | 显式静态`root=PARTLABEL=rootfs`,无A/B概念 |
| verity/AVB参数 | 广泛出现(`verity=enabled`、`avb-verity=enabled`,多个机型经`dm-verity-bootloader.bbclass`追加) | meta-qcom中未检索到任何dm-verity/avb相关cmdline注入 |
| console参数来源 | 各机型手写字符串,存在格式不一致历史包袱(有的`,n8`,有的没有) | 统一用oe-core标准变量`SERIAL_CONSOLES`/`KERNEL_CONSOLE`推导 |

## 与systemd补丁的交叉印证

- QLI1.0的`fstab-generator-Honor-verity-enabled-cmdline.patch`(修改`fstab-generator.c`,识别cmdline中`verity=enabled`/`avb-verity`参数,检测到则强制用`/dev/mapper/root`作为根设备)在QLI2.0全局检索`verity=enabled`、`arg_usr_verity`均零匹配。
- 决定性证据:QLI1.0的`poky/meta-qti-bsp/classes/`下存在整整8个dm-verity相关bbclass(`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2/v3.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-none.bbclass`、`avb-verity-initramfs.bbclass`等),构成一整套AVB/dm-verity镶像签名与校验架构。QLI2.0的meta-qcom中没有任何一个对应class。
- 与output/Boot_Architecture/Partition_Layout.md(Android安全HAL分区消失)、output/Boot_Architecture/systemd_.md三方证据互相印证。

## 关键差异

- root=语法变化(隐式A/B slot → 显式静态`root=PARTLABEL=rootfs`)和cmdline固化时机变化(运行时拼接 → 构建期烘焙进UKI)看似两条独立的表格行,实际是同一件事的两个侧面:QLI1.0的cmdline是"运行时由ABL+abctl拼出来的",QLI2.0是"构建时就定好、之后不再变"。这直接决定了审计方式的差异——QLI1.0要看实机才能拿到真实cmdline,QLI2.0靠看Yocto配置就能还原,但代价是灵活性(同一镜像切换console/内存布局需要重新构建)。
- 但"构建期固化"不能简单等同于"更安全":cmdline固化只解决了"内容是否可预测",没有回答"内容是否可被篡改后仍然启动"——这需要UKI签名机制配合,而`meta-qcom*`/`build/conf`范围内全局检索`UKI_SB_KEY`/`UKI_SB_CERT`/`sbsign`均零命中(见Boot_Flow.md),说明当前默认构建的UKI没有做secure boot签名。也就是说cmdline固化目前只带来了可预测/可审计收益,还没有带来防篡改收益。
- 三个独立证据源(cmdline无verity参数、systemd的verity相关补丁未吸收、Android安全分区消失)指向同一个结论:QLI1.0那套"cmdline声明verity状态→fstab-generator识别→dm-verity/AVB校验→安全分区提供密钥"的完整链路,在QLI2.0里不是被等价替换,而是整条链路都不存在了,目前也没有看到功能对等的替代方案在构建配置里落地。

## 影响与风险

- 若QLI2.0后续要为某些产品线启用dm-verity/安全启动等价能力,需要重新设计cmdline注入点(目前`esp-qcom-image.bb`里没有对应hook)、补上UKI secure boot签名链路(`UKI_SB_KEY`/`UKI_SB_CERT`,目前零命中),且systemd层面的fstab-generator逻辑也需要重新引入。
- QLI1.0的运行时动态cmdline意味着仅看Yocto仓库无法还原出设备上实际生效的完整`/proc/cmdline`,审计/合规团队如需精确核对启动参数,必须结合实机抓取或ABL源码。
- QLI2.0根文件系统完整性校验已确认没有替代方案:就是纯ext4、无任何完整性校验机制,不存在"被fs-verity等价机制替代"的情况——`UKI_CMDLINE`明确是`rw`而非`ro`,`DISTRO_FEATURES`/`EXTRA_IMAGE_FEATURES`都没有加`read-only-rootfs`,全仓检索`fs-verity`/`fsverity`/`veritysetup`/`dm-verity`在`meta-qcom*`范围内零命中。这是output/Platform_Features/OTA_Mechanism.md中P0级待决策事项的重要组成部分。

## 待确认

- **pebble实机`/proc/cmdline`抓取**——ABL运行时动态拼接的cmdline(slot_suffix、root设备等)无法从源码静态还原,因为ABL以`file://edk2`本地二进制打包,构建仓库里看不到拼接逻辑的源码;静态只能推断到`pebble.conf`的`CONSOLE_PARAM:qti-distro-perf=""`和`libabctl.cpp`的解析逻辑这一层。确认步骤:由实验室/测试团队在真实pebble样机上执行`adb shell cat /proc/cmdline`(或串口console下`cat /proc/cmdline`),采集一份实际生效的完整cmdline,与静态推断结果交叉核对。
