# Display 规则执行逻辑细节报告

本文档记录`Display.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/Display.md`"Display专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Display.md`。

## 1. 合成服务层整体消失的核实

**做法**:对全库(`meta-audioreach`/`meta-lts-mixins`/`meta-openembedded`/`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-ros`/`meta-security`/`meta-selinux`/`meta-updater`/`meta-virtualization`/`oe-core`,排除`build`/`downloads`)检索`sdm|displayengine|libdisplayconfig|display-hal|display composer`关键词组合。
**证据**:零命中。
**落到结论**:对比总览表"合成服务层"行"无对应物……SDM Composer/HWC合成服务层已完全消失"的判断,是本文档最核心的一条否定性结论,依据规则1"禁止仅凭目录名断言"的要求,展示了实际检索命令与零命中证据而非直接下结论。

## 2. 图形栈整合方式核实

**做法**:核对downstream(maili)`gbm_21.1.1.bb`(厂商fork libgbm)、`weston_13.0.1.bbappend`与QLI2.0`msm-gbm-backend.bb`(`git://github.com/qualcomm-linux/gbm-msm-backend.git`)、`weston_15.0.0.bbappend`、`mesa.bbappend`(启用freedreno)三份文件是否真实存在。
**证据**:三份QLI2.0侧文件均已核实真实存在(非规划中的占位)。
**落到结论**:对比总览表"图形栈"行,"关键差异"节"libgbm被独立开源项目msm-gbm-backend取代"的判断。

## 3. glvnd多EGL vendor共存机制的源码级核实(与Graphics.md共用证据,落点不同)

**做法**:读取mesa侧`mesa.bb`默认`PACKAGECONFIG`是否经`DISTRO_FEATURES`过滤器纳入`glvnd`(确认`qcom-base.inc`已声明该feature)、`meta-qcom/recipes-graphics/mesa/mesa.bbappend`是否追加`freedreno`;取出`libglvnd`已下载源码(`build/downloads/git2_gitlab.freedesktop.org.glvnd.libglvnd.git.tar.gz`)里的`src/EGL/libeglvendor.c`读`LoadVendorsFromConfigDir()`,以及`libegl.c`读`GetPlatformDisplayCommon()`。
**证据**:确认`10_adreno.json`(qcom-adreno固定安装)与`50_mesa.json`(mesa/freedreno产出,已在构建产物`build/tmp/sysroots-components/armv8-2a/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json`核实文件名)会被`scandir()`按文件名字典序全部加载,不是互斥关系;真正决定绑定结果的是"按字典序顺序尝试、首个成功者胜出"这一通用规则,adreno在前故默认胜出。
**落到结论**:"关键差异"节glvnd共存机制的完整解释段落。本文档在这一条上明确说明:此证据链与Graphics.md共用同一份libglvnd源码阅读结果,但本文档落点是"显示合成/多输出场景下最终绑定给谁",Graphics.md落点是"GPU用户态驱动与开源mesa如何共存",两文分别展开、不互相转述。

## 4. 并发多显示拓扑硬件实证——假设被推翻

**做法**:对`iq-9075-evk`(lemans-evk)、hamoa-iot-evk、sm8550-hdk三块目标板的kernel dts分别用`grep -n "mdss0_dp\|edp"`、`grep -n "mdss_dp"`实测核实DP/eDP controller节点数量。
**证据**:`lemans-evk.dts`确认`mdss0_dp0`/`mdss0_dp1`两路独立eDP;`hamoa.dtsi`确认`mdss_dp0`~`mdss_dp3`四路DP(第6115/6203/6291/6378行);`sm8550-hdk.dts`确认HDMI(`lt9611_codec`桥接)+DP组合。
**假设被推翻的过程**:在深入核实这几块dts之前,"影响与风险"节曾可能默认"单一输出场景故不需要"来判断并发多显示拓扑与SDM/HWC能力缺口的相关性不大;逐一读取上述三块目标板的dts后,该假设不成立——至少lemans/hamoa/sm8550-hdk三个板级是真实存在的多输出硬件配置,只有talos-evk/qrb2210-rb1/qrb4210-rb2/qrb5165-rb5等板级才是单一HDMI输出。
**落到结论**:"影响与风险"节"已核实单一输出场景故不需要这一假设不成立"的完整表述。

## 5. QDCM色彩管理/HDR tone-mapping能力缺口核实

**做法**:全树(排除`sstate-cache`)检索`qdcm`关键词,分别统计downstream(maili)与QLI2.0侧命中数。
**证据**:downstream(maili)侧303个文件命中(recipe层`QDCM_S`路径/`--enable-qdcm_socket`,预编译库`libhdr_tm.so`/`libsnapdragoncolor-qdcm.so`等);QLI2.0侧全库零命中。
**落到结论**:"覆盖"字段QDCM锚点小节与"影响与风险"节"SDM/HWC特有能力在新栈中无直接对应组件"判断的其中一项具体支撑证据。

## 纠错记录说明

本主题不是标准的"初步判断→核实后结论"两栏表格式纠错,而是上文第4条描述的"一处假设被核实推翻"的形态:最初可能默认多显示拓扑与本机型无关,经逐一dts核实后确认假设不成立。这是如实反映`rules/System_Architecture/Display.md`原文记录的形态,不套用其他主题的两栏表格式。
