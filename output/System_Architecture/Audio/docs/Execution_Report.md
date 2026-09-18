# Audio 规则执行逻辑细节报告

本文档记录`Audio.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/Audio.md`"Audio专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Audio.md`。

## 1. 框架层/ACDB/服务器/内核驱动锚点核实

**做法**:逐一确认downstream(maili)`meta-iot-audio`(`pal_git.bb`/`agm_git.bb`/`packagegroup-qti-pulseaudio.bb`/`pulseaudio_15.0.bb`)与`meta-iot-audio-prop`(`acdbdata_git.bb`)各自的`SRC_URI`/`LICENSE`字段,以及QLI2.0`meta-audioreach`层的`packagegroup-audioreach.bb`聚合关系、`audioreach-kernel_git.bb`的`SRC_URI`与`VENDOR_QCOM`开关、`audioreach-pipewire-plugin_git.bb`与`wireplumber.conf.d/60-disable-alsa.conf`的搭配关系。
**证据**:确认downstream(maili)侧内部源码树整体拷贝编译、QLI2.0侧`git://`+SRCREV锁定拉取的分发模式差异;`src/audio/vendor/qcom/opensource/audioreach-conf`路径核实存在,证明downstream(maili)音频架构本身已是AudioReach血统。
**落到结论**:对比总览表"音频框架层""内部血统证据""ACDB校准数据库""音频服务器""内核驱动"五行,以及"关键差异"节的分发模式转变判断。

## 2. 专有插件/测试工具消失核实(两轮grep)

**做法**:先按包名`pa-qti-sourcetrack`/`pa-pal-voiceui`/`catf`在`meta-audioreach`全层(含所有子目录)grep,确认零命中;进一步确认WirePlumber lua脚本目录本身为空/不存在,排除"藏在脚本里"的可能。
**证据**:两个维度(包名+脚本目录)都指向"这几项当前没有开源等价物",不是搜索方法不够全面导致的假阴性。
**落到结论**:"影响与风险"节"确实缺失而非藏在别处"的判断。

## 3. catf测试框架的功能对比核实

**做法**:读取downstream(maili)`catf_git.bb`的`DEPENDS`字段,确认其依赖`qal`(闭源Qualcomm Audio Library)及可选`gstreamer`/`glib`插件;再读QLI2.0`pipewire_1.6.3.bb`带的`pw-cli`/`wpctl`工具定位,逐项功能比对。
**证据**:`catf`是针对音频链路的脚本化自动化测试框架,`pw-cli`/`wpctl`只是PipeWire自带的节点查看/音量控制通用CLI,二者能力范畴不同。
**落到结论**:"影响与风险"节"二者不是同类工具,不能算等价替代"的判断。

**执行中的一处路径纠偏**:本次复核发现`catf_git.bb`真正生效的路径是`poky/meta-iot-audio-internal/recipes/audio-test-framework/catf_git.bb`(`DEPENDS="glib-2.0 pal"`),而不是rules文件与正文最初引用的`meta-qti-atf/recipes/audio-test-framework/`——后者只存在于已废弃的`disregard/`备份层内,`DEPENDS="qal"`,是历史版本的旧记录未同步更新。这一纠偏不影响"非同类工具"这一最终结论(两条路径描述的都是依赖闭源音频库的专用测试框架),但取证时必须以实际生效路径为准,不能沿用旧路径记录直接下结论。

## 4. 无ADSP场景支持(ARE on APPS)实际启用状态核实

**做法**:逐一读取QLI2.0各机型conf里`are_on_apps` PACKAGECONFIG的实际赋值。
**证据**:所有Qualcomm机型(qcs6490/qcs8300/qcs9100/hamoa等)均未启用该开关,仅raspberrypi4 CI参考配置启用。
**落到结论**:对比总览表"无ADSP场景支持"行的具体表述("目前只用于raspberrypi4 CI参考配置"),避免读者误以为该能力已在Qualcomm量产机型上生效。

## 纠错记录说明

本主题`rules/System_Architecture/Audio.md`"已知易错点/纠错记录"栏标注为"(暂无纠错记录)"。本次复核未发现某个先前判断被后续证据推翻的情况——上文第3条的"路径纠偏"性质是"引用路径记录有误、更正引用位置",而不是"结论本身被推翻",因此不计入纠错记录,如实按原文标注处理。
