# System Architecture — WiFi/BT

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| WLAN驱动 | QCACLD-3.0/CLD3/PRIMA(`meta-qti-wlan`按芯片拆分多个recipe) | mainline mac80211: `ath10k`/`ath11k`/`ath12k` |
| WLAN平台守护进程 | `cnss-daemon`、`hal-proxy-daemon`、`qsaharaservice`、`ftm` | 全树搜索均零命中,内核`CONFIG_CNSS`无匹配 |
| WLAN固件 | 专有固件包 | 标准`linux-firmware.git`项目(唯一例外:`firmware-ath6kl`社区仓库) |
| wpa_supplicant/hostapd | `wpa-supplicant-qcacld_git.bb`等厂商fork | 标准recipe,无厂商bbappend,仅通用CVE补丁 |
| WLAN测试工具 | `wlan-sigma-dut` | `sigma-dut`(标准WFA认证工具) |
| BT栈 | Fluoride(AOSP派生,含libchrome/HIDL client) | 标准BlueZ5 |
| 内核CONFIG(构建产物验证) | — | `CONFIG_WLAN_VENDOR_ATH=y`,`CONFIG_ATH10K/11K/12K=m`,已写入iq-9075-evk真实rootfs manifest |

## 关键差异

- WLAN从专有CLD/PRIMA栈完全切换为mainline mac80211驱动+标准固件分发,是"专有仓库→标准开源"最彻底的案例之一。
- BT从Android Fluoride栈切换为标准Linux BlueZ5,应用层集成方式(D-Bus vs HIDL/Fluoride API)根本变化。
- `qsaharaservice`(固件下载/diag)、`ftm`(工厂测试模式)、`xpan`(BT跨网络特性)均无对应物。

## 关于"QLI1.0=全专有驱动"的核实

- QLI1.0内核源码树(继承自Google ACK)客观携带完整可编译的ath10k/11k/12k代码及db845c开发板config片段,但该路径未被任何实际产品配置激活(`db845c_gki.fragment`未被任何bb/conf引用,是死配置)。
- 决定性证据:`packagegroup-qti-wifi.bb`对所有列出机型均强制选择QCACLD,无一机型override指向ath系列。
- 结论:"QLI1.0所有量产机型强制用专有驱动"成立,"QLI1.0代码库完全没有ath代码"不成立。

## 影响与风险

- 驱动栈+芯片族(WCN6750/6855/7850、QCA6698AQ/QCA2066)+主机蓝牙栈三者同时切换,Wi-Fi联盟认证/BT SIG认证/FCC-CE射频法规测试大概率需重新走一遍。
- 依赖Android HIDL蓝牙API或PRIMA/CLD专有扩展的上层代码需重新实现。
- BT音频链路同时受BlueZ切换与PulseAudio→PipeWire(详见Audio.md)双重影响,风险叠加。

## 待确认

- `ftm`工厂测试模式、`qsaharaservice`固件下载能力若产线仍需要,等效工具链是什么。
- 目标板级WLAN/BT芯片的认证/合规文件是否需重新申请。
- 天线增益/区域码校准数据在新架构下的配置路径。
- linux-firmware两份recipe(oe-core/meta-lts-mixins)版本选择在不同机型是否一致。
