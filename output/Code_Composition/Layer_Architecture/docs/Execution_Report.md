# Layer_Architecture 执行报告

本文档复盘`../Layer_Architecture.md`的结论是怎么从取证要点(见`rules/Code_Composition/Layer_Architecture.md`"Layer_Architecture专属取证要点"节)一步步落地的,并重点展开本主题的四条纠错记录——每条都说明"最初判断是什么、后来怎么发现问题、修正成了什么"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Layer_Architecture.md`。

## 1. 基础统计:两侧激活层数量与`meta-qti-*`全量普查

**做法**:逐行统计downstream(maili)`build-qti-distro-camerastack-debug/conf/bblayers.conf`的`BBLAYERS`变量路径条目数,以及QLI2.0`build/conf/bblayers.conf`的`BBLAYERS`条目数;`find poky -maxdepth 1 -iname "meta-qti-*"`统计downstream(maili)侧`meta-qti-*`层全量。
**证据**:downstream(maili) 59条,QLI2.0 21条;`meta-qti-*`实测49个子目录(文档正文用"约45个"的宽松估计,是本次报告需要如实指出的口径偏差,详见下方)。
**落到结论**:对比总览表"激活层数量"行、"层数降幅"行(约64%)。

## 纠错记录一:激活层数量——51条订正为59条

**初步判断**:此前统计downstream(maili)`BBLAYERS`条目数为51条。
**发现问题的过程**:重新执行"逐行统计"这一动作(不是凭经验估算,取证要点特别强调"不能凭经验估算,需真正逐行数"),得到与此前不同的结果。
**修正结论**:59条。现有正文对比总览表明确标注"非此前误记的51",把订正过程留痕在文档里,不是静默覆盖。
**这条纠错说明的方法论问题**:大规模列表类证据(如`BBLAYERS`变量的条目数)即使看起来是"数数"这种低风险操作,也存在人工计数误差,唯一可靠的做法是重新逐行核实,而不是信任此前的记忆或估算值。

## 纠错记录二:EVA/CVP硬件证据——从"有效证据"到"误判证据不足"再到"确认为有效证据"

**初步判断**:kernel dts里16个文件的`cvp@`保留内存节点,被判断为"硅片仍带EVA/CVP硬件IP"这一结论的有效证据。
**发现问题的过程**:一度复核时收窄为"证据不足"——因为复核时检索`cvp_kaanapali_hal.c`在两侧代码库均未命中,误判该引用无效。**这次误判的根因是复核路径疏漏**:当时的检索没有覆盖`src/vendor/qcom/opensource/`这个路径。
**修正结论**:本次重新执行检索,在`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`确实找到该文件——Qualcomm署名,600+行完整功能代码,非样板代码,且与QLI2.0`meta-qcom/conf/machine/kaanapali-mtp.conf`这个真实在用机型指向同一SoC代号,可作为"硅片带IP"的有效交叉证据。结论最终收敛为:硅片大概率带IP,但QLI2.0内核基线未随之移植驱动。
**这条纠错说明的方法论问题**:一次检索"没搜到"不代表证据不存在,可能只是检索路径没覆盖到——本条纠错本质是"复核本身犯了规则1禁止的错误(把搜索范围不足等同于目标不存在)",后来靠扩大检索路径才纠正回来,是"证据是否存在"和"检索路径是否够全"两个问题被混淆后又厘清的典型案例。

## 纠错记录三:ss-mgr用户态看门狗逻辑——从"待确认的产品线取舍"到"证实的真实缺口"

**初步判断**:QLI2.0未找到ss-mgr对应新层,记为"可能是产品线取舍,待确认"这类开放性表述,没有下明确结论。
**发现问题/深挖的过程**:进一步核对mainline`remoteproc_sysfs.c`/`qcom_sysmon.c`全文,确认mainline remoteproc核心自带`recovery`sysfs属性(默认`enabled`),子系统崩溃时内核直接调用`rproc_trigger_recovery()`自动重启,不需要用户态daemon;但`crash_cnt`只做日志计数,通读`qcom_q6v5_pas.c`/`qcom_sysmon.c`全文均未发现"连续失败N次后触发系统级reboot/EDL/slot切换"的升级逻辑。同时用`meta-qcom/conf/machine/*.conf`核对实际启用modem硬件路径(`mpss-pas`)的机型(`qcm6490-idp`/`iq-8275-evk`/`iq-9075-evk`/`rb3gen2-core-kit`均带`MACHINE_FEATURES += "...phone"`),确认这些机型走的是`meta-qcom-distro/recipes-products/images/qcom-console-image.bb`拉取的标准`ModemManager`。
**修正结论**:不再停留在"待确认",明确结论为"单次崩溃自动恢复的等价物已核实存在,但多次失败后升级为slot切换/EDL的看门狗逻辑确认没有等价物"——这是真实缺口,不是待人工确认的未知项。
**这条纠错说明的方法论问题**:"找不到对应新层"这个初步观察本身是对的,但停在这一步会让读者误以为"不确定是否移除";真正有价值的结论需要进一步验证"内核态是否有等价能力覆盖了这个缺口",区分"表面缺失"和"是否被更底层机制接管"。

## 纠错记录四:internal测试类层去向——从"疑似缺失"到"证实迁移到公开仓库"

**初步判断**:`meta-qti-internal`/`meta-qti-cta-internal`/`meta-qti-sv-internal`等internal测试类层,在QLI2.0"未找到原样对应物",初步记为疑似缺失。
**发现问题/深挖的过程**:`grep -rli "kernel-tests|stability-tests|memory-error-tests|sat-module"`全树检索确认无残留后,没有止步于"没找到就是没有",而是扩大搜索范围到四个顶层产品的`.github/workflows/test*.yml`与`.github/actions/lava-test-plans/action.yml`,发现其中通过`actions/checkout@v6`显式拉取两个独立仓库(`qualcomm-linux/lava-test-plans`、`qualcomm-linux/qcom-linux-testkit`)。进一步用匿名`curl -s https://api.github.com/repos/qualcomm-linux/lava-test-plans`与`.../qcom-linux-testkit`核实两者`"private": false`,以及`commits/main.atom`确认提交活跃度。
**修正结论**:由"疑似缺失"修正为"已证实迁移到公开独立仓库",且明确不是私有内部仓库——测试执行落在第三方托管的公开LAVA测试实验室`lava.infra.foundries.io`。
**这条纠错说明的方法论问题**:同一类"层内没找到对应recipe"的表面现象,可能对应至少三种不同真相(能力真的没了/能力换了组织形式在别处/能力搬到了外部仓库),必须逐一验证排除,不能把"没在预期位置找到"直接等同于"能力消失"。

## 汇总:四条纠错记录的共同教训

四条纠错记录指向同一个方法论要点:**"没搜到"这个中间结果本身不构成结论,只是提出了下一步该往哪扩大搜索范围的问题**。本文档的《关键差异》第二条"找不到映射的旧layer里真正站得住的能力缺口比表面看到的少"这一整体判断,正是建立在纠错记录二、三、四这三次"扩大检索范围后改判"的基础之上;纠错记录一(层数51→59)则提醒即使是最基础的计数工作也需要重新核实而非信任既有记忆。
