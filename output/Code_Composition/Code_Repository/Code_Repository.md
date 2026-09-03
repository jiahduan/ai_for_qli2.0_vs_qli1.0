# Code Composition — Code Repository

## 对比范围

- **覆盖**:
  - 仓库存储模型对照:QLI1.0`.git`符号链接机制(`poky/.git`→`../.repo/projects/poky.git`、`src/security/securemsm/.git`、`qc/display-kernel.lnx/cd/.git`同样模式)+`.repo/project-objects`集中对象库(89个project-object目录)vs QLI2.0各顶层目录为真实独立git仓库(`meta-qcom/.git`/`meta-audioreach/.git`/`meta-updater/.git`/`oe-core/.git`/`bitbake/.git`均已用`stat`确认为真实目录而非软链)
  - 独立clone能力、清理风险(`rm -rf .repo`影响面)、版本发布方式(单一manifest SHA vs 各层独立git tag)对照
  - `base.lock.yml`两层锁定结构细节(本条是Branch_Management.md"分支语义"覆盖字段中明确指向本文档的部分):`meta-qcom/ci/base.lock.yml`与`meta-qcom-robotics-sdk/ci/base.lock.yml`锁定的12个公共OE生态层repo清单(已核对两份lock文件内容完全一致)+各产品顶层repo在自己消费方yml(如`meta-qcom-robotics-sdk/ci/qcom-robotics-distro.yml`)单独锁commit的第二层结构
  - 存储去重能力差异(集中对象库 vs polyrepo各自独立`.git`)
- **明确排除**:(无)
- **待定边界**:polyrepo总体磁盘占用是否确实高于集中对象库去重方案——本文档已提出`du -sh */.git`核实思路但未做定量对比,留待下次修订本文档时补测,不是文档间归属边界问题

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| `.git`性质 | 符号链接,指向`.repo/projects/<path>.git`(`ls -la poky/.git` → `-> ../.repo/projects/poky.git`;`src/security/securemsm/.git` → `-> ../../../.repo/projects/src/security/securemsm.git`;`qc/display-kernel.lnx/cd/.git`同样模式) | 真实目录(`stat -c "%N type=%F" meta-qcom/.git meta-audioreach/.git meta-updater/.git oe-core/.git bitbake/.git`全部`type=directory`) |
| 对象库组织 | 集中存放于`.repo/projects*`与`.repo/project-objects`(89个project-object目录),repo工具标准"分离对象库+多工作树"存储模型 | 每个顶层目录本身是完整独立git仓库,各自对应GitHub上独立开源仓库(如`github.com/qualcomm-linux/meta-qcom`) |
| 独立clone能力 | 不可脱离`.repo`独立使用(单个子目录无法独立clone) | 可被单独`git clone`并独立使用/贡献(README中演示`git clone https://github.com/qualcomm-linux/meta-qcom.git`) |
| 版本发布方式 | 单一manifest SHA对应整机版本 | 各层可独立发版本tag(README提到"Milestone releases...using git tags") |
| 清理风险 | 若`rm -rf .repo`会导致全部工作树失效(符号链接失联) | 每层删除互不影响其余层 |
| 存储去重 | 有(集中对象库,多个project共享pack) | 无(polyrepo各自独立`.git`,总体磁盘占用可能更高,未做定量对比,建议用`du -sh */.git`核实) |

## 关键差异

- "仓库边界"从manifest这一个中心化元数据搬到了"每个层自己是一个完整git仓库"上,直接改变了两类行为:清理磁盘的安全操作(`rm -rf .repo`在QLI1.0是全局性灾难,在QLI2.0是层级隔离、可逐个执行的操作),以及对外开源贡献的门槛(QLI1.0的子目录离开`.repo`就是一份无法独立clone的不完整代码,QLI2.0的每一层天然就是可以直接PR给上游的独立开源仓库)。
- "整机固件版本"的定义方式随之改变:QLI1.0是单一manifest SHA天然对应一份完整快照;QLI2.0没有这个单点,版本由`base.lock.yml`收口的12个公共OE生态层commit+各产品顶层repo在自己yml里单独锁的commit这两层结构共同决定,复现性完全依赖这套锁定文件被严格使用,而不是"checkout到某个SHA"这一个单一动作就能保证。
- 存储去重优势的让渡(集中对象库→polyrepo各自独立`.git`)是这次架构切换里少数量化上偏"倒退"的指标,但相对于开源贡献门槛降低、层级清理安全性提升带来的收益,是可接受的代价。

## 影响与风险

- QLI2.0各层可独立发版本tag(版本可追溯性更细粒度),但"整机固件版本"不再对应单一manifest SHA,而是21个层各自SHA的组合,需要靠`base.lock.yml`统一收口。
- 若沿用QLI1.0习惯直接`rm -rf .repo`清理磁盘,会导致QLI1.0全部工作树失效(符号链接失联);QLI2.0则没有此风险,每层删除互不影响其余层。
- 存储空间:QLI1.0的集中对象库有去重优势(多个project共享pack),QLI2.0 polyrepo各自独立`.git`,总体磁盘占用可能更高(未做定量对比,建议后续用`du -sh */.git`核实)。
- `base.lock.yml`并非"全量超级manifest",而是两层锁定结构里的"公共社区层"那一层:实测`meta-qcom/ci/base.lock.yml`、`meta-qcom-robotics-sdk/ci/base.lock.yml`内容完全一致,锁定`oe-core`/`meta-lts-mixins`/`bitbake`/`meta-arm`/`meta-qcom-distro`/`meta-openembedded`/`meta-virtualization`/`meta-audioreach`/`meta-selinux`/`meta-updater`/`meta-security`/`meta-dpdk`共12个repo各一个commit(`meta-openembedded`整体锁一个commit,其内部子layer天然随之约束,不存在单独漂移的可能);各产品自己的顶层repo(如`meta-qcom`、`meta-ros`)的commit则锁在各自消费方yml里(如`meta-qcom-robotics-sdk/ci/qcom-robotics-distro.yml`),不在`base.lock.yml`内。即"公共OE生态层集中锁`base.lock.yml`+各产品顶层repo在自己的产品yml里单独锁commit"的两层模型,覆盖是完整的,不存在计划外的统一超级manifest设想。
