# System Architecture — WiFi/BT

## 对比范围

- **覆盖**:本文比较WLAN与BT两条连接技术线各自的驱动/平台守护进程/固件/测试认证工具栈,以及跨两条线的"downstream(maili)=全专有驱动"假设核实;按线分组列出双侧锚点:
  - WLAN线:
    - 驱动栈与平台守护进程:
      - downstream(maili):`poky/meta-qti-wlan/recipes/wlan/`(`qcacld32-ll-vienna-le.bb`/`qcacld-hl_git.bb`/`qcacld30-ll_git.bb`等按芯片/项目拆分的多个recipe)+`wcnss_git.bb`+`poky/meta-qti-wlan-prop/recipes/wlan-proprietary/`(`cnss-daemon_git.bb`/`qcacld-utils_git.bb`/`hal-proxy-daemon_git.bb`/`qsaharaservice.bb`/`ftm_git.bb`/`wlan-services_git.bb`)+`wlan-prima_git.bb`+`packagegroup-qti-wifi.bb`
      - QLI2.0:`meta-qcom`内核编译产出的`ath10k`/`ath11k`/`ath12k`(已用`iq-9075-evk`真实构建产物的defconfig与rootfs manifest核实)+`oe-core/meta/recipes-kernel/linux-firmware/linux-firmware_20260410.bb`/`meta-lts-mixins/recipes-kernel/linux-firmware/linux-firmware_20260519.bb`+`meta-qcom/recipes-bsp/firmware/firmware-ath6kl_git.bb`+`packagegroup-machine-essential.bb`
    - wpa_supplicant/hostapd:downstream(maili) `poky/meta-qti-wlan/recipes/wpa-supplicant/`(`wpa-supplicant-qcacld_git.bb`/`wpa-supplicant-ath6kl_git.bb`)+`hostap-daemon-qcacld_git.bb` vs QLI2.0 `oe-core/meta/recipes-connectivity/wpa-supplicant/wpa-supplicant_2.11.bb`+`meta-openembedded/meta-oe/recipes-connectivity/hostapd/hostapd_2.11.bb`
    - 认证/合规测试工具:downstream(maili) `poky/meta-qti-wlan/recipes/wlan-sigma-dut/wlan-sigma-dut_git.bb` vs QLI2.0 `meta-qcom/recipes-connectivity/sigma-dut/sigma-dut_git.bb`+`meta-openembedded/meta-oe/recipes-connectivity/wifi-test-suite/wifi-test-suite_10.10.1.bb`
    - RF区域码与板级校准:
      - QLI2.0侧:`oe-core/meta/recipes-kernel/wireless-regdb/wireless-regdb_2026.03.18.bb`+`meta-qcom/recipes-devtools/qca-swiss-army-knife/qca-swiss-army-knife_git.bb`(`ath10k`/`ath11k` board-2.json生成脚本)
      - 板级证据:解包`linux-firmware_20260519.tar.xz`得到的`board-2.bin`内部`bus/qmi-chip-id/qmi-board-id/variant`分段结构+dts侧`qcom,calibration-variant`声明(`qrb2210-rb1.dts`/`qcs6490-rb3gen2.dts`/`talos-evk-som.dtsi`/`lemans-ride-common.dtsi`)
    - ath6kl legacy路径与"downstream(maili)=全专有驱动"假设核实:
      - downstream(maili):内核树`src/kernel-6.18/kernel_platform/common/drivers/net/wireless/ath/{ath10k,ath11k,ath12k}`(随ACK镜像携带但未挂接产品链路,已跑`git log --all`核实`db845c_gki.fragment`历史提交作者)+`poky/meta-qti-wlan-prop/recipes/wlan-proprietary/`(`ath6kl-proprietary_git.bb`/`ath6kl-utils_git.bb`)
      - QLI2.0:`iq-9075-evk`实际`kernel-source/arch/arm64/configs/defconfig`(`CONFIG_ATH10K/11K/12K=m`,无`CONFIG_ATH6KL`)与rootfs manifest
  - BT线:
    - BT主栈:downstream(maili) `poky/meta-qti-bt/recipes-connectivity/`(`fluoride/fluoride_4.1.bb`/`btvendorhal/btvendorhal_4.1.bb`/`hidl_client/hidl-client_4.1.bb`/`bt_dlkm_kernel`)+`packagegroup-qti-bluetooth.bb` vs QLI2.0 `meta-qcom-distro/recipes-connectivity/bluez5/bluez5_%.bbappend`(标准BlueZ5)
    - BT专有组件:downstream(maili) `poky/meta-qti-bt-prop/recipes-connectivity/`(`hci-qcomm-init/hci-qcomm-init_4.1.bb`/`bttransport/bttransport_4.1.bb`/`xpan/xpan_4.1.bb`) vs QLI2.0 全树检索零命中
- **明确排除**:
  - DIAG协议栈/`diag-router`与`libdiag`的整体架构对比 ——见[Log_System](../../Platform_Features/Log_System/Log_System.md)
- **待定边界**:(无,已核实三处易混淆边界均不需挪动:①内核驱动层ath10k/11k/12k vs QCACLD——`Kernel_Code_Architecture.md`对WLAN/BT关键字零命中,不重叠;②认证合规重新认证影响——`Security_Architecture.md`同样零命中,该结论仍由本文承载,已同步README《待拍板事项汇总》;③量产测试工具链缺口(Sahara/FTM)——本文"待确认"节已用recipe级证据覆盖,未超出本文范围)

## 对比总览

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| WLAN驱动 | 专有CLD/PRIMA族:`meta-qti-wlan`(`qcacld32-ll-vienna-le.bb`、`qcacld-hl_git.bb`、`qcacld30-ll_git.bb`等按芯片/项目拆分多个recipe,`wcnss_git.bb`) | mainline mac80211:`ath10k`(`snoc/pci/sdio`)、`ath11k`(`ahb/pci`)、`ath12k`,均随`linux-qcom`内核recipe统一编译产出 |
| WLAN平台守护进程 | `meta-qti-wlan-prop`: `cnss-daemon_git.bb`、`qcacld-utils_git.bb`、`hal-proxy-daemon_git.bb`、`qsaharaservice.bb`、`ftm_git.bb`、`wlan-services_git.bb`、`wlan-prima_git.bb` | 全树搜索均零命中;内核`.config`中`CONFIG_CNSS`无匹配(先前grep命中的"cnss"字符串是`wcnss.mbn`/`wlanmdsp.mbn`文件名子串假阳性) |
| WLAN固件 | 专有固件包 | 标准`linux-firmware.git`项目:`oe-core/meta/recipes-kernel/linux-firmware/linux-firmware_20260410.bb`与`meta-lts-mixins/.../linux-firmware_20260519.bb`(版本更高,按BitBake规则默认选中,manifest已核实);仅`meta-qcom/recipes-bsp/firmware/firmware-ath6kl_git.bb`(社区仓库github.com/qca/ath6kl-firmware)为历史遗留例外 |
| WLAN测试工具 | `wlan-sigma-dut_git.bb` | `sigma-dut_git.bb`(标准WFA认证测试代理,github.com/qualcomm/sigma-dut);另有`meta-openembedded/meta-oe/.../wifi-test-suite_10.10.1.bb`(WFA官方DUT测试套件) |
| wpa_supplicant/hostapd | `wpa-supplicant-qcacld_git.bb`、`hostap-daemon-qcacld_git.bb`、`wpa-supplicant-ath6kl_git.bb`(Qualcomm自持代码仓,非标准w1.fi tarball) | `oe-core/meta/.../wpa-supplicant_2.11.bb`、`meta-openembedded/.../hostapd_2.11.bb`,均未经任何bbappend覆盖,补丁仅含通用CVE修复(macsec、OWE/802.11be defconfig、CVE-2025-24912等),PACKAGECONFIG仅openssl/gnutls |
| BT栈 | `meta-qti-bt`: `fluoride_4.1.bb`(AOSP蓝牙栈分支)、`btvendorhal_4.1.bb`、`hidl_client/hidl-client_4.1.bb`(Android HIDL)、`bt_dlkm_kernel` | `meta-qcom-distro/recipes-connectivity/bluez5/bluez5_%.bbappend`——标准BlueZ5(仅`0001-Use-system-bus-instead-of-session-for-obexd.patch`及UTF16/32 glibc-gconv依赖补充) |
| BT专有组件 | `meta-qti-bt-prop`: `hci-qcomm-init_4.1.bb`、`bttransport_4.1.bb`、`xpan_4.1.bb` | 全树零命中 |
| 内核CONFIG(构建产物验证) | — | `CONFIG_WLAN=y`、`CONFIG_WLAN_VENDOR_ATH=y`、`CONFIG_ATH10K=m`(+CE/PCI/SDIO/SNOC子模块)、`CONFIG_ATH11K=m`(+AHB/PCI)、`CONFIG_ATH12K=m`,已写入`iq-9075-evk`真实rootfs manifest(含`kernel-module-ath10k-core/pci/sdio/snoc`、`ath11k/ahb/pci`、`ath12k/wifi7`、`linux-firmware-ath11k-wcn6855`、`ath12k-qcn9274/wcn7850`等) |
| 镜像集成 | `packagegroup-qti-wifi.bb`对所有列出机型override均是QCACLD32_LL+wlan-platform+hostap-daemon-qcacld+wpa-supplicant-qcacld | `packagegroup-machine-essential.bb`按SoC分组RRECOMMENDS拉取ath模块(hamoa/purwa: ath11k-pci+ath12k;qcm2290: ath10k-snoc;qcs6490: ath11k-ahb;qcs8300/9100: ath11k-pci),板级packagegroup按`DISTRO_FEATURES`含'wifi'条件拉取固件(RB1/RB2: ath10k-wcn3990;RB3gen2: ath11k-wcn6750;RB5: ath11k-qca6390;SM8550-HDK: ath12k-wcn7850)。RB1/RB2/RB3gen2/RB5/SM8550-HDK在当前meta-qcom里并非各自独立的Yocto MACHINE(本地repo里只有`qrb2210-rb1-core-kit`/`rb1-core-kit`/`rb3gen2-core-kit`等少数板级conf,没有单独的rb2/rb5/sm8550-hdk机型),而是`packagegroup-rb1/-rb2/-rb3gen2/-rb5/-sm8550-hdk.bb`固件包被通用机型`qcom-armv8a`的`MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS`一并合并安装;用`MACHINE=qcom-armv8a bitbake-getvar MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS`实测(非纯静态阅读,真正跑了一次bitbake解析),变量解析结果与`packagegroup-rb1/rb2/rb3gen2/rb5-firmware`等静态声明完全一致,配置层面无解析错误或override覆盖问题 |

## 关于"downstream(maili)=全专有驱动"的核实

- downstream(maili)内核源码树(继承自Google ACK镜像)客观携带完整可编译的`drivers/net/wireless/ath/{ath10k,ath11k,ath12k}`源码,`db845c_gki.fragment`显式启用`CONFIG_ATH10K_AHB=y`等,主`defconfig`本身也带`CONFIG_ATH10K/11K/12K=m`。
- 但`db845c_gki.fragment`在poky/vendor全树中未被任何bb/bbappend/conf引用,属Google公共内核镶像自带、未被Qualcomm产品链路挂接的"死配置"。对该文件所在git仓库(`src/kernel-6.18/kernel_platform/common`,remote为`quic`镜像的`kernel/common`)跑`git log --all`核实:触碰`db845c_gki.fragment`的commit作者全部是`@google.com`/`@linaro.org`(无一个`@qualcomm.com`/`@quicinc.com`),本地`git branch -a`/`git tag`也只有2个远程分支(均非ath相关的实验分支),即这份本地镜像的可见历史里找不到Qualcomm一侧touch过这个文件或试图借它切WLAN路径的痕迹。
- 决定性证据:`packagegroup-qti-wifi.bb`对所有列出机型(neo/kalama/qrb5165/qcs40x/pineapple/qcm2290-mtp/ar-sg1/kera/sun/alor/vienna及缺省项)均是QCACLD32_LL组合,没有任何机型override指向ath10k/11k/12k。
- ath6kl(AR6004)是双方共有、且在downstream(maili)中实际被打包的legacy路径(`hostap-daemon-ath6kl`、`wpa-supplicant-ath6kl`、`meta-qti-wlan-prop/ath6kl-proprietary`);QLI2.0侧`firmware-ath6kl_git.bb`固件recipe虽在层内,但`iq-9075-evk`实际构建产物`kernel-source/arch/arm64/configs/defconfig`里只有`CONFIG_ATH10K`/`ATH11K`/`ATH12K=m`,没有`CONFIG_ATH6KL`(驱动模块本身未启用),`build/tmp/deploy/images/iq-9075-evk/`下全部rootfs manifest对`ath6kl`关键字也是0命中(该recipe没有被任何machine/packagegroup RDEPENDS/RRECOMMENDS拉取)——即在当前可见的唯一真实构建产物上,ath6kl从内核模块到固件包全链路均未激活。
- **修正结论**:"downstream(maili)所有已知量产机型的packagegroup均强制选择QCACLD"这一镜像级/产品级结论成立;"downstream(maili)代码库完全没有ath代码"这一代码库级结论不成立,是过度简化。

## 关键差异

- WLAN从专有QCACLD-3.0/CLD3(及更早PRIMA)驱动族+CNSS平台守护进程整套闭源栈,完全替换为主线开源ath10k/ath11k/ath12k mac80211驱动+标准linux-firmware固件包,是本次审计"专有仓库→标准开源"最彻底的案例之一。
- BT从Android派生的Fluoride蓝牙栈(含libchrome、HIDL client、btvendorhal)切换为标准Linux BlueZ5栈,应用层集成方式(D-Bus API vs 原HIDL/Fluoride API)发生根本变化。
- 移除组件:PRIMA驱动、ath6kl旧驱动族(生产环境路径)、`qsaharaservice`(专有固件下载/diag协议守护进程)、`ftm`(WLAN工厂测试模式)、`xpan`(BT跨网络特性)——均未在QLI2.0找到对应物。
- WLAN/BT认证测试工具从厂商fork(`wlan-sigma-dut`)变为标准`sigma-dut`。
- WLAN区域码/国家规则已确认统一走标准`wireless-regdb`(`qcom-armv8a.conf`按`DISTRO_FEATURES`含`wifi`条件拉取),取代原厂商私有区域码方案;天线增益等板级RF校准并非完全不可见——实际解包`linux-firmware_20260519.tar.xz`后核实`ath11k/WCN6750/hw1.0/board-2.bin`等文件内部是按`bus=ahb,qmi-chip-id=N,qmi-board-id=M[,variant=NAME]`分段打包的多板级容器(WCN6750一份board-2.bin里打包了11组不同board-id,其中`qmi-board-id=25,variant=Qualcomm_rb3gen2`即专门对应RB3gen2参考板),内核dts侧对应用`qcom,calibration-variant`属性声明要匹配哪个variant字符串。已在QLI2.0内核树里实测核实这条链路真实生效:`qrb2210-rb1.dts`/`qrb4210-rb2.dts`声明`Thundercomm_RB1`,`qcs6490-rb3gen2.dts`声明`Qualcomm_rb3gen2`(与board-2.bin里的variant字符串对应),`talos-evk-som.dtsi`(被`iq-615-evk`使用的`talos-evk.dtb`引用)声明`QC_QCS615_Ride`,`lemans-ride-common.dtsi`(`qcs9100-ride`/`sa8775p-ride`使用)声明`QC_SA8775P_Ride`——即定制RF校准数据的通道在QLI2.0是真实可用且已有多个Qualcomm参考板在用的机制,不是完全空白;但`iq-9075-evk`实际用的`lemans-evk.dts`本身未声明`qcom,calibration-variant`,即该机型目前落到board-2.bin里的通用/默认board-id项,若其天线设计与默认项不匹配,仍需新增一条variant声明+向board-2.bin提交对应校准数据。
- `firmware-ath6kl_git.bb`引用的独立固件仓库(`github.com/qca/ath6kl-firmware`)注释明确写明"不会被并入linux-firmware",这是社区2017年就定下的永久性排除决定,不是临时缺口。该仓库维护状态已核实:`https://github.com/qca/ath6kl-firmware/commits/master.atom`显示master分支最后一次提交是2014-06-17("ar6004: hw1.3 and hw3.0: add firmware 3.5.0.349-1..."),距今超过11年无任何新提交,上游已确认处于无人维护状态。

## 影响与风险

- 这是五个多媒体/连接子系统中变动最彻底、认证/合规风险最高的一项:驱动栈(CLD/Prima→ath1xk)、芯片族(downstream(maili)支持的handset WLAN/BT芯片 vs QLI2.0的WCN6750/WCN6855/WCN7850/QCA6698AQ/QCA2066等)、主机蓝牙栈(Fluoride→BlueZ)三者同时切换,理论上意味着Wi-Fi联盟认证、Bluetooth SIG认证、射频法规(FCC/CE)测试均需重新走一遍流程。
- 任何依赖Android HIDL蓝牙API或PRIMA/CLD专有vendor扩展(如特定快速漫游、Wi-Fi Direct/SoftAP定制行为)的上层应用/中间件需要针对nl80211+wpa_supplicant/hostapd及BlueZ D-Bus重新实现。
- 未见`qsaharaservice`/`ftm`等效替代(`meta-qcom/recipes-test/diag-router_1.0.2.bb`+`libdiag_1.0.5.bb`只承接了诊断日志路由这部分能力,不含Sahara固件下载协议或WLAN工厂测试模式本身),如量产制造测试(RF校准、工厂测试模式)流程依赖这些工具,需在SOP冻结前明确替代方案。
- BT音频链路同时受本条目(Fluoride→BlueZ)与Audio.md(PulseAudio→PipeWire)双重影响,A2DP/HFP编解码协商、SCO语音通路需要联合回归测试,风险叠加。

## 待确认

- **Sahara固件下载/WLAN FTM的等效工具链**——新架构下`diag-router`/`libdiag`只覆盖诊断日志通路(见"影响与风险"),不含Sahara固件下载协议或FTM工厂测试模式,代码库内没有找到对应物。本次进一步解包`linux-firmware_20260519.tar.xz`核实`ath11k`/`ath12k`全部136个固件文件里没有任何`utf`/`test`/`ftm`命名的工厂测试专用固件变体(ath10k生态里常见的"UTF" Unified Test Framework固件模式在这份linux-firmware快照里不存在),即FTM等效能力不仅在recipe层找不到,连固件包本身的物料也没有对应变体,确证代码/物料侧都是空白。确认步骤:产品/制造测试团队确认现有量产SOP是否仍依赖Sahara固件下载或WLAN FTM(例如RF一致性/产线校准),若需要则要求Qualcomm提供ath10k/11k/12k体系下的等效工具(如`ath10k-fwtest`类工具或厂商私有诊断协议)。
- **iq-9075-evk等尚未声明校准variant的目标板是否需要定制天线增益RF校准**——区域码/国家规则已走标准`wireless-regdb`;定制RF校准的机制本身已确认真实存在且在用(`qcom,calibration-variant`属性+`board-2.bin`多variant容器,见"关键差异"新增细节,`rb1`/`rb2`/`rb3gen2`/`iq-615-evk`/`qcs9100-ride`/`sa8775p-ride`均已各自声明专属variant),缺口收窄到:`iq-9075-evk`(lemans-evk)、`iq-x7181-evk`(hamoa)、`iq-8275-evk`等目前未声明`qcom,calibration-variant`的机型,是否需要新增一条属于自己的variant并向`board-2.bin`补充定制校准数据,这取决于实际天线设计而非代码库可查范围。确认步骤:RF/天线团队确认这些机型是否需要区别于board-2.bin现有通用项的定制天线增益校准,若需要则参照已有的`Thundercomm_RB1`/`Qualcomm_rb3gen2`等variant声明,走ath11k/ath12k的board-2.bin定制流程(向Qualcomm或社区提交定制calibration data)。
- **downstream(maili)是否存在使用db845c_gki.fragment切到ath路径的内部/实验性分支**——对该fragment所在git仓库跑`git log --all`/`git branch -a`/`git tag`核实(见"关于downstream(maili)=全专有驱动的核实"),触碰该文件的commit作者全部是Google/Linaro,本地镜像也只有2个非ath相关的远程分支,现有可见历史里没有Qualcomm尝试切换路径的痕迹。本次进一步直接读取该仓库`.git/packed-refs`确认本地实际只镶了1条远程分支的完整历史(另一条是tag型引用),没有被`git branch -a`遗漏的隐藏ref,排除了"本地镜像其实有更多分支只是没列出来"这一可能性,但这仍只能证明"这个本地镜像看不到",不能排除Qualcomm内部另有未镜像到这里的分支。确认步骤:直接联系downstream(maili) BSP/WLAN维护团队,询问是否存在使用`db845c_gki.fragment`的实验性/内部分支或历史尝试从QCACLD切到ath路径。
- **ath6kl legacy路径是否仍在任何在产SKU中使用**——上游`github.com/qca/ath6kl-firmware`的维护状态已核实为2014年起无人维护(见"关键差异"),这部分已有确定结论;本次进一步核实QLI2.0侧当前唯一可见的真实构建产物(`iq-9075-evk`)从内核defconfig(无`CONFIG_ATH6KL`)到rootfs manifest(0命中)全链路均未激活ath6kl(见"关于downstream(maili)=全专有驱动的核实"新增细节),但这只覆盖了本仓库能构建出的这一个机型,不能代表`meta-qcom`其余18个machine conf或客户私有defconfig fragment的情况,唯一剩的缺口收窄为:是否有本仓库看不到的量产SKU真正用到这条legacy路径。确认步骤:与产品团队核实ath6kl(AR6004)覆盖的机型是否仍在任何在产SKU中使用。
