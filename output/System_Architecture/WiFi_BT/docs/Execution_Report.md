# WiFi_BT 规则执行逻辑细节报告

本文档记录`WiFi_BT.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/WiFi_BT.md`"WiFi_BT专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../WiFi_BT.md`。

## 1. WLAN驱动栈与平台守护进程核实

**做法**:核对downstream(maili)`meta-qti-wlan`(按芯片/项目拆分的多个recipe)与`meta-qti-wlan-prop`(`cnss-daemon`/`qcacld-utils`/`hal-proxy-daemon`/`qsaharaservice`/`ftm`/`wlan-services`)各自recipe;核对QLI2.0`ath10k`/`ath11k`/`ath12k`随`linux-qcom`内核编译的事实,并用`iq-9075-evk`真实构建产物的defconfig与rootfs manifest核实。
**证据**:downstream(maili)侧专有CLD/PRIMA族驱动+CNSS平台守护进程整套闭源栈;QLI2.0侧全树搜索`meta-qti-wlan-prop`对应能力均零命中,内核`.config`中`CONFIG_CNSS`无匹配(先前grep命中的"cnss"字符串核实为`wcnss.mbn`/`wlanmdsp.mbn`文件名子串假阳性,已排除)。
**落到结论**:对比总览表"WLAN驱动""WLAN平台守护进程"两行,"关键差异"节"专有仓库→标准开源最彻底的案例之一"的判断。

## 2. `MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS`实测核实

**做法**:实测跑`MACHINE=qcom-armv8a bitbake-getvar MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS`(非纯静态阅读,真正跑了一次bitbake解析)。
**证据**:变量解析结果与`packagegroup-rb1/rb2/rb3gen2/rb5-firmware`等静态声明完全一致,配置层面无解析错误或override覆盖问题。
**落到结论**:对比总览表"镜像集成"行关于RB1/RB2/RB3gen2/RB5/SM8550-HDK通过通用机型合并安装固件包这一机制的核实。

## 3. WLAN固件与区域码/RF校准核实

**做法**:核对`linux-firmware_20260410.bb`与`linux-lts-mixins/linux-firmware_20260519.bb`按BitBake规则的版本选择;解包`linux-firmware_20260519.tar.xz`读取`board-2.bin`内`bus=ahb,qmi-chip-id=N,qmi-board-id=M[,variant=NAME]`分段结构;grep`qcom,calibration-variant`属性跨多机型dts。
**证据**:确认已声明variant清单——`qrb2210-rb1.dts`(`Thundercomm_RB1`)、`qcs6490-rb3gen2.dts`(`Qualcomm_rb3gen2`)、`talos-evk-som.dtsi`(`QC_QCS615_Ride`)、`lemans-ride-common.dtsi`(`QC_SA8775P_Ride`)。
**落到结论**:对比总览表"WLAN固件"行,"关键差异"节"定制RF校准数据的通道在QLI2.0是真实可用且已有多个Qualcomm参考板在用的机制,不是完全空白"的判断,以及"待确认"节"iq-9075-evk等尚未声明校准variant的目标板"这一收窄后的开放问题。

## 4. 关于"downstream(maili)=全专有驱动"的核实(本文档取证重点)

**做法**:先确认downstream(maili)内核源码树客观携带完整可编译的`drivers/net/wireless/ath/{ath10k,ath11k,ath12k}`源码,`db845c_gki.fragment`显式启用`CONFIG_ATH10K_AHB=y`;对该fragment所在git仓库(`kernel_platform/common`,remote`quic`)跑`git log --all`核实触碰该文件的commit作者全部是`@google.com`/`@linaro.org`(无一个`@qualcomm.com`/`@quicinc.com`);再核对决定性证据`packagegroup-qti-wifi.bb`对所有列出机型是否均为QCACLD32_LL组合。

**修正结论**:"downstream(maili)所有已知量产机型的packagegroup均强制选择QCACLD"(镜像级/产品级结论)成立;"downstream(maili)代码库完全没有ath代码"(代码库级结论)不成立,是过度简化——即downstream(maili)内核树本身携带完整可编译的ath10k/11k/12k源码,只是从未被任何产品链路的packagegroup挂接使用,这两个层面(代码库存在性 vs 产品链路挂接)是不同问题,不能混为一谈。

本次进一步读取`.git/packed-refs`确认本地实际只镶了1条远程分支的完整历史,排除了"本地镜像其实有更多分支只是没列出来"的可能性,但仍只能证明"这个本地镜像看不到"其他分支,不能排除Qualcomm内部另有未镶像到这里的分支——这一边界已写入"待确认"节。

**落到结论**:"关于'downstream(maili)=全专有驱动'的核实"整节,以及ath6kl legacy路径部分——`iq-9075-evk`实际构建产物defconfig(无`CONFIG_ATH6KL`)与rootfs manifest(0命中)全链路均未激活。

## 5. ath6kl上游维护状态交叉验证

**做法**:WebFetch核实`github.com/qca/ath6kl-firmware/commits/master.atom`。
**证据**:master分支最后一次提交是2014-06-17,距今超过11年无任何新提交,确认上游已处于无人维护状态。
**落到结论**:"关键差异"节"这是社区2017年就定下的永久性排除决定,不是临时缺口"的判断,是规则6"交叉验证"要求下用官方来源核实上游维护状态的具体应用。

## 6. Sahara/FTM等效工具链缺口核实

**做法**:解包`linux-firmware_20260519.tar.xz`,对`ath11k`/`ath12k`全部136个固件文件名做`utf`/`test`/`ftm`关键词检索。
**证据**:零命中,即FTM等效能力不仅在recipe层找不到,连固件包本身的物料也没有对应变体。
**落到结论**:"待确认"节"Sahara固件下载/WLAN FTM的等效工具链"这一缺口从recipe层扩展到固件物料层的双重确证,不是仅凭recipe层空白就下结论。
