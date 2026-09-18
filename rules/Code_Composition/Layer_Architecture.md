# Layer_Architecture —— 规则

> 本文件对应产出文档 [output/Code_Composition/Layer_Architecture/Layer_Architecture.md](../../output/Code_Composition/Layer_Architecture/Layer_Architecture.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

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
1. `## 对比总览` — 一张`维度 | downstream(maili) | QLI2.0`表格,是文档骨架,让读者10秒内看到全貌
2. (可选)主题专属深挖章节 — 追踪表、抽样统计、专项验证等
3. `## 关键差异` — 综合性洞察,**不是对总览表的复述**,要回答"这些差异放在一起意味着什么"
4. `## 影响与风险` — 对下游团队/决策的具体影响,不做纯技术总结

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

## Code_Composition 专属取证指引

代码组织与协作机制对比。优先证据来源:
- 代码同步:repo manifest / kas yaml等声明式配置文件
- 补丁统计:先确认统计口径(是否含第三方noise文件、工作目录残留),`find`/`grep`前先排除已知噪声源,避免规则1提到的"目录名/关键字搜索"类误判在此处以"总数虚高"的形式出现
- 分支管理:命名规则、跨仓补丁机制(如kas的`patches:`字段与消费方patches目录关系)
- 补丁抽样需按层/按recipe分别统计密度(如患病率≈存活补丁数/原补丁数),不能只看单个recipe就外推整层结论(参见规则3)

## Layer_Architecture专属取证要点

- **关键双侧目录/文件锚点**:
  - 层数统计:downstream(maili)`build-qti-distro-camerastack-debug/conf/bblayers.conf`的`BBLAYERS`变量(59条,此前误记51);QLI2.0`build/conf/bblayers.conf`的`BBLAYERS`变量(21条)
  - downstream(maili)约45个`meta-qti-*`系列层(按prop/internal/core/kernel后缀细分,如`meta-qti-bsp(-prop)`、`meta-qti-camera(-prop)`、`meta-qti-display(-internal/-prop)`、`meta-qti-security(...)`、`meta-qti-ss-mgr(-prop)`);QLI2.0主要层:`meta-qcom`、`meta-qcom-distro`、`meta-qcom-robotics-sdk`、`meta-audioreach`、`meta-updater`、`meta-security`(含`meta-tpm`)、`meta-selinux`、`meta-virtualization`、`meta-ros`(`meta-ros-common`/`meta-ros2`/`meta-ros2-jazzy`)、`meta-lts-mixins`、`oe-core`、`meta-openembedded`
  - ss-mgr相关:`init-mss_2.0.bb`、`init_rproc_mss.service`、`init_mss.rules`、`reboot-daemon`(`SlotSwitchReboot()`);内核config`CONFIG_REMOTEPROC`/`CONFIG_QCOM_RPROC_COMMON`/`CONFIG_QCOM_Q6V5_COMMON`/`CONFIG_QCOM_Q6V5_MSS`/`CONFIG_QCOM_Q6V5_PAS`/`CONFIG_QCOM_Q6V5_ADSP`/`CONFIG_QCOM_PIL_INFO`/`CONFIG_QCOM_SYSMON`;内核驱动`drivers/remoteproc/qcom_q6v5_pas.c`(`.auto_boot`)、`drivers/remoteproc/remoteproc_sysfs.c`、`remoteproc_core.c`、`qcom_sysmon.c`;机型配置`meta-qcom/conf/machine/{qcm6490-idp,iq-8275-evk,iq-9075-evk,rb3gen2-core-kit}.conf`(`MACHINE_FEATURES += "...phone"`);`meta-qcom-distro/recipes-products/images/qcom-console-image.bb`(拉取`modemmanager`)
  - aosphal相关:`libhardware_1.0.bb`、`camera-metadata_1.1.bb`;QLI2.0交叉验证`android-tools_5.1.1.r37.bb`(与HAL无关)、`camxlib-kodiak_1.0.24.bb`的`DEPENDS`
  - CTA/SV/EVA相关:`meta-qti-cta-internal/recipes/cta/cta_1.1_git.bb`;`meta-qti-sv-internal/recipes/sv-internal/sv-internal_git.bb`、`meta-qti-sv-prop/recipes/sv-noship/sv-noship_1.0.bb`、`evass-fw_git.bb`;硬件交叉证据`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`;`meta-qti-eva-devicetree`(`x-ship="hy11"`);QLI2.0机型`meta-qcom/conf/machine/kaanapali-mtp.conf`;共享内核源码树`build/tmp/work-shared/iq-9075-evk/kernel-source`
  - 安全IPC相关:`meta-qti-security-internal-common`(空层);`meta-qti-security-internal`(`minktransport-test.bb`、`qtvm-test.bb`、`securemsm-internal.bb`);QLI2.0`meta-qcom/dynamic-layers/openembedded-layer/recipes-security/minkipc/minkipc_1.2.8.bb`、`mink-idl-compiler_0.2.3.bb`、`qcomtee/qcomtee_git.bb`、`qwes_1.1.bb`;TUI生产证据`build-qti-distro-camerastack-debug/conf/{alor,kera,pebble,sun}_prebuilts.conf`(`securemsm-noship`含`TUICoreService`)
  - 测试类层外移:`oe-core/meta/recipes-extended/ltp/ltp_20260130.bb`、`stress-ng_0.20.01.bb`、`oe-core/meta/lib/oeqa/runtime/cases/ltp.py`;四顶层产品`.github/workflows/test*.yml`、`.github/actions/lava-test-plans/action.yml`;独立公开仓库`qualcomm-linux/lava-test-plans`、`qualcomm-linux/qcom-linux-testkit`;LAVA测试lab`lava.infra.foundries.io`
- **已验证的检索方式**:
  - 逐行统计`bblayers.conf`里`BBLAYERS`变量的路径条目数得出激活层数(不能凭经验估算,需真正逐行数)
  - `grep -rli "kernel-tests|stability-tests|memory-error-tests|sat-module"`全树检索internal测试类layer残留
  - `grep -rli "\bcta\b"`、`grep -rliE "\beva\b|libeva|evass"`、`\bcvp\b|\bicp\b`全树检索(排除build产物噪声)
  - 检索范围从"当前machine的dts"主动扩大到共享内核源码树`build/tmp/work-shared/<machine>/kernel-source`全部`drivers/`+`Documentation/devicetree/bindings/`+`arch/arm64/boot/dts/qcom/`,再用`grep -rliE "qcom,.*-eva\b|qcom,.*cvp|\beva-fw\b"`确认是否真的整套mainline内核代码库都没有该驱动/binding,而不是"当前machine没写"
  - `grep -rli "qseecom|mink-transport|mink_transport"`、`grep -rli "trustedui|trusted-ui|biometric|payment.*secure|fingerprint.*ui|securemsm|gptee"`(后者需扩大到`meta-qcom`/`meta-security`/`meta-updater`全部`.bb`/`.bbappend`/`.inc`/`.conf`)
  - 内核源码全文`grep -rl "pas-auto-boot"`排查"自动上电是否由设备树属性驱动"这一猜测,确认实际是驱动代码内per-SoC匹配表的硬编码字段
  - 匿名`curl -s https://api.github.com/repos/qualcomm-linux/lava-test-plans`与`.../qcom-linux-testkit`核实`"private": false`及提交活跃度(`commits/main.atom`)
  - 抽样约3000条内核commit,按标签前缀`FROMLIST:`/`BACKPORT:`/`QCLINUX:`/`PENDING:`/`WORKAROUND:`分类计数
- **已知易错点/纠错记录**:
  - 激活层数量:初步误记为51条,逐行核实`BBLAYERS`后订正为59条(文档对比总览表已标注"非此前误记的51")
  - EVA/CVP硬件证据(该案例已被README《曾纠正过的结论》表收录):初步判断"kernel dts里16个文件的`cvp@`保留内存节点=硅片仍带EVA/CVP硬件IP";一度复核收窄为"证据不足",误判`cvp_kaanapali_hal.c`两侧代码库检索不到、系无效引用;经本文档实测`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`确实存在(Qualcomm署名,600+行完整功能代码,非样板),与QLI2.0`meta-qcom/conf/machine/kaanapali-mtp.conf`真实在用机型指向同一SoC代号,可作为硅片带IP的有效交叉证据;之前"检索不到"是复核路径疏漏(未搜索`src/vendor/qcom/opensource/`路径)。结论收敛为:硅片大概率带IP,但QLI2.0内核基线未随之移植驱动
  - ss-mgr用户态看门狗逻辑:初步只记为"未找到对应新层,可能是产品线取舍",经进一步核对mainline`remoteproc_sysfs.c`/`qcom_sysmon.c`全文后,确认"连续失败N次后触发系统级reboot/EDL/slot切换"的升级逻辑是**真实缺口、无等价实现**,不再是"待确认"而是明确结论
  - internal测试类层去向:初步只记为"未找到原样对应物",后扩大检索证实测试执行已整体外移到公开仓库`qualcomm-linux/lava-test-plans`+`qualcomm-linux/qcom-linux-testkit`(经GitHub API核实均为公开、非私有内部仓库),结论由"疑似缺失"修正为"已证实迁移到公开独立仓库"
