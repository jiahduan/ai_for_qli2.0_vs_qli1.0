# Code_Repository 执行报告

本文档复盘`../Code_Repository.md`的结论是怎么从取证要点(见`rules/Code_Composition/Code_Repository.md`"Code_Repository专属取证要点"节)一步步落地的——按锚点/检索方式逐条展开"做了什么检索→得到什么证据→支撑了哪个结论"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Code_Repository.md`。

## 1. `.git`性质的坐实——符号链接 vs 真实目录

**做法**:`ls -la`检查downstream(maili)侧`poky/.git`、`src/security/securemsm/.git`、`qc/display-kernel.lnx/cd/.git`三处的实际指向;`stat -c "%N type=%F"`检查QLI2.0侧`meta-qcom/.git`、`meta-audioreach/.git`、`meta-updater/.git`、`oe-core/.git`、`bitbake/.git`五处的文件类型。
**证据**:downstream(maili)三处均为符号链接,指向`.repo/projects/<path>.git`(`poky/.git` → `../.repo/projects/poky.git`;`src/security/securemsm/.git` → `../../../.repo/projects/src/security/securemsm.git`);QLI2.0五处`stat`结果全部为`type=directory`,即真实完整git仓库。
**落到结论**:对比总览表"`.git`性质"行,是《关键差异》第一条"仓库边界从manifest这一个中心化元数据搬到每个层自己是一个完整git仓库"这一判断的直接证据来源。

## 2. 对象库组织方式的坐实

**做法**:确认downstream(maili)侧集中对象库的目录结构与规模(`.repo/projects*`与`.repo/project-objects`)。
**证据**:`.repo/project-objects`下89个project-object目录,是repo工具标准"分离对象库+多工作树"存储模型的直接体现。
**落到结论**:对比总览表"对象库组织"行、"存储去重"行。

## 3. 独立clone能力与版本发布方式的交叉验证

**做法**:核对QLI2.0各层是否确实能脱离整体独立使用,并检查其README是否有独立clone/独立发版本的文字证据。
**证据**:README中演示`git clone https://github.com/qualcomm-linux/meta-qcom.git`;README提到"Milestone releases...using git tags"。
**落到结论**:对比总览表"独立clone能力"行、"版本发布方式"行;《关键差异》第一条"对外开源贡献的门槛"论证的依据。

## 4. `base.lock.yml`两层锁定结构——本主题承接的交叉引用

**做法**:读取并逐行对比`meta-qcom/ci/base.lock.yml`与`meta-qcom-robotics-sdk/ci/base.lock.yml`的repo/commit清单是否一致;进一步核对产品顶层repo自己的锁定位置(如`meta-qcom-robotics-sdk/ci/qcom-robotics-distro.yml`)。
**证据**:两份`base.lock.yml`内容完全一致,共同锁定`oe-core`/`meta-lts-mixins`/`bitbake`/`meta-arm`/`meta-qcom-distro`/`meta-openembedded`/`meta-virtualization`/`meta-audioreach`/`meta-selinux`/`meta-updater`/`meta-security`/`meta-dpdk`共12个repo各一个commit;各产品顶层repo(如`meta-qcom`、`meta-ros`)的commit另锁在各自消费方yml里,不在`base.lock.yml`内。
**落到结论**:《对比范围》"覆盖"字段第三条明确标注"本条是Branch_Management.md分支语义覆盖字段中明确指向本文档的部分"——这是范围交叉一致性规则(规则7)在执行层面的体现:Branch_Management.md只取"分支名≠实际锁定版本"这一层关系,把"锁定结构本身怎么组织"这一具体问题转交给本文档;《影响与风险》最后一条"公共OE生态层集中锁+各产品顶层repo在自己产品yml里单独锁commit"的两层模型描述,即由此证据直接支撑。

## 5. 存储去重的定性判断与"未做定量对比"的明确标注

**做法**:取证要点记录了`du -sh */.git`这一核实思路,但明确标注为"未做定量对比"。
**证据**:定性层面可判断——downstream(maili)集中对象库支持多project共享pack(去重),QLI2.0polyrepo各自独立`.git`无此能力;定量层面(具体磁盘占用差多少)未执行。
**落到结论**:对比总览表"存储去重"行按定性结论呈现,并在《对比范围》"待定边界"字段如实标注"polyrepo总体磁盘占用是否确实高于集中对象库去重方案——已提出`du -sh */.git`核实思路但未做定量对比,留待下次修订本文档时补测",遵循规则3"抽样声明"关于不得直接外推为总体结论的要求,不虚构一个未执行的定量结果。

## 本主题无纠错记录的说明

取证要点明确标注本文档"暂无纠错记录"。本报告不虚构"初步判断被推翻"的过程——本主题的执行路径是直读文件系统状态(符号链接指向、`stat`类型、锁定文件内容比对),证据本身是直接可验证的事实,没有出现需要二次纠偏的中间结论。
