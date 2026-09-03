# Build Architecture — Build Tools (kas)

## 对比范围

- **覆盖**:
  - kas作为QLI2.0整机构建入口的文件分布判定:已重新`find -iname '*kas*'`核实QLI1.0全部命中均为误报(boringssl`KAS-ECC/FFC-SSC`测试向量、内核`kasan`/`kaslr`/`kasprintf.c`、`asahi-kasei,ak*`devicetree binding);QLI2.0侧已重新计数`meta-qcom/ci`(46个yml)、`meta-qcom-distro/ci`(36个)、`meta-qcom-robotics-sdk/ci`(19个),与规则文件锚点一致
  - 主入口层误判纠错:已重新计数`meta-security/kas`(21个yml)、`meta-updater/kas`(实测11个`*.yml`,含`.gitlab-ci.yml`),并重新`git remote -v`确认两层均为上游独立git checkout(`git.yoctoproject.org/meta-security`、`github.com/uptane/meta-updater`,均`wrynose`分支);真正主入口是`meta-qcom/ci/base.yml`+各机型yml(如`rb3gen2-core-kit.yml`),已重新读取`base.yml`确认repos/local_conf_header声明结构与文档描述一致
  - kas工具自身机制:本机kas 5.5包`kas/schema-kas.json`(`repos:`字段范围)、`kas/repos.py`/`libkas.py`
  - 层锁定文件`base.lock.yml`与生成产物(`build/conf/local.conf`/`bblayers.conf`)的对应关系
- **明确排除**:
  - kas代码同步/版本锁定机制的完整对比(repo vs kas元数据规模、工作树落地方式、锁定粒度、容器化) ——见[Code_Sync_Method](../../Code_Composition/Code_Sync_Method/Code_Sync_Method.md)
  - kas`patches:`跨仓补丁声明机制 ——见[Patch_Management](../../Code_Composition/Patch_Management/Patch_Management.md)
  - host环境最低要求(Python/磁盘/内存/shell强制检查) ——见[Build_Environment](../Build_Environment/Build_Environment.md)
- **待定边界**:`meta-updater/kas/rb3gen2-core-kit.yml`/`common-qcom.yml`两个文件本次核实中新发现实际引用`meta-qcom`仓库、面向Qualcomm机型(非纯粹上游自测配置),更像OTA/aktualizr集成构建示例;是否该在本文"主入口层判定"里补充说明还是归入OTA_Mechanism,目前两处文档都未覆盖,先记录待下次修订处理

## 对比总览

| 维度 | QLI1.0(repo) | QLI2.0(kas) |
|---|---|---|
| kas文件分布 | 无(全树`find -iname '*kas*'`命中全部误报:boringssl的KAS-ECC-SSC/KAS-FFC-SSC测试向量、Linux内核`skas`/`sys_mikasa.c`/`kasprintf.c`、传感器devicetree binding`asahi-kasei,ak*.yaml`) | meta-qcom(46个ci/kas yml)、meta-qcom-distro(36个)、meta-qcom-robotics-sdk(19个)、meta-security(21个)、meta-updater(10个) |
| 主入口层判定 | 不适用 | meta-security/kas和meta-updater/kas是上游OE社区层自带的"自测/CI"kas配置(面向qemux86-64等仿真机型,用于该层自身oe-selftest,与整机构建无关);真正承载"一键搭建整机"职责的是meta-qcom/meta-qcom-distro/meta-qcom-robotics-sdk下的ci/*.yml;进一步核实,meta-qcom是唯一有"Quick build"命令行示例的官方文档化主入口,meta-qcom-distro只是被其`includes`引用的distro配置片段层,二者非并列入口 |
| 官方一键命令 | `repo init -u <manifest-url> -b <branch> -m default.xml` + `repo sync -j<N>` | `kas build meta-qcom/ci/<machine>.yml:meta-qcom/ci/<distro>.yml`(如`kas build meta-qcom/ci/rb3gen2-core-kit.yml:meta-qcom/ci/qcom-distro.yml`) |
| 环境搭建脚本 | `poky/qti-conf/set_bb_env.sh`:检查shell为bash;用`xmllint`从manifest读revision;调`parse_imageinfo.py`得推荐machine/distro;若变量未设用whiptail/dialog弹交互菜单;调`get_bblayers.py "meta*" --lookup-paths`动态扫描磁盘meta*目录生成bblayers.conf;拷贝`poky/qti-conf/local.conf`;从manifest git describe生成BUILDNAME/SDK_VERSION;`source oe-init-build-env` | `kas-container`一行命令,host无需装kas/bitbake/python依赖 |
| repos声明与目录对应 | 不适用 | meta-qcom/ci/base.yml声明repos(meta-qcom、oe-core@openembedded-core、meta-lts-mixins、bitbake@2.18分支)、machine:unset、target:core-image-base,以及local_conf_header片段(base/diskmon/clo-mirrors/cmdline/qcomflash/extra/os-release);顶层目录与repos声明的仓库名逐一对应,`build/conf/local.conf`按注释分段与local_conf_header字典键逐条对应,`build/conf/bblayers.conf`的BBLAYERS列表精确等于kas yml中repos:/layers:声明的集合——证明该工程通过kas build一步生成 |
| 层锁定文件 | 无(仅manifest revision) | `base.lock.yml`对每个依赖仓库锁定精确commit,等价lock文件 |
| 机型/distro组合方式 | 静态conf文件矩阵手工维护 | `meta-qcom-distro/ci/qcom-distro.yml`追加meta-openembedded各子层、meta-virtualization、meta-audioreach、meta-selinux、meta-updater、meta-security(+meta-tpm)等;机型文件如`meta-qcom/ci/rb3gen2-core-kit.yml`仅`includes: [ci/base.yml]`+`machine:`,靠kas include/多文件合并机制组合完整配置 |

## 关键差异

- 一步vs三步:QLI2.0一条`kas build <yml组合>`同时完成"拉代码+生成build配置+触发构建";QLI1.0需要`repo init/sync`(拉代码)→编辑/依赖预置`poky/qti-conf/local.conf`(配置)→`source setup-environment`(生成build目录并交互选择MACHINE/DISTRO)→再手动`bitbake <target>`。
- 声明式可复现vs脚本式动态发现:kas yml用显式列表声明每个repo的url/branch/layers与最终bblayers.conf内容一一对应,天然可diff、可版本化;QLI1.0的`get_bblayers.py "meta*" --lookup-paths`是运行时对磁盘目录名做通配扫描,行为随磁盘上实际存在哪些meta*目录变化,同一份manifest在不同签出方式(如混用EXTRALAYERS环境变量)下可能生成不同bblayers.conf。
- 环境隔离/容器化:QLI2.0提供kas-container路径,host上无需安装bitbake/python依赖;QLI1.0要求host显式满足`/bin/sh->bash`、`$SHELL`为bash、且需要装whiptail/dialog,不满足直接`return 1`报错退出。
- CI友好度:kas yml天然是CI系统的第一公民(`meta-qcom/ci/ci.yml`、`world.yml`、`schemacheck.py`均在同一目录下,CI直接消费同一份yml,人工命令行与CI用的是同一份声明);QLI1.0的交互式whiptail菜单在无人值守CI下必须靠预设`MACHINE=`/`DISTRO=`环境变量绕过交互,容易在新增机型/新增层时因忘记设置变量而静默走错分支或卡在`read -r`等待输入。
- 人工出错点:QLI1.0的local.conf采用"拷贝+追加"策略(整份cat进build目录,首行写"DO NOT EDIT,每次source都会重新生成"),意味着任何针对某个board的定制都要么写死进这份公共local.conf,要么靠EXTRALAYERS环境变量拼接(sed -i硬编码进bblayers.conf),配置耦合度高;kas侧通过header.includes分层组合(base.yml+机型yml+distro yml+可选selinux.yml等fragment)实现按需拼装,新增board只需新增一个几行的yml并`includes: [ci/base.yml]`。

## 影响与风险

- QLI2.0的kas方式显著降低"环境搭建"这一环节的人工失误概率(无需手动repo init/sync参数、无需人工比对local.conf、无需管理shell环境),也让CI与本地开发用完全相同的输入,复现问题更容易。
- 风险在于团队若不熟悉kas的include合并顺序(header.version、多文件`:`拼接顺序影响变量覆盖),排障时需要理解kas的合并规则,学习曲线与repo+手工方式不同但方向相反(新问题变成"理解yml合并语义"而非"记住一堆手工步骤")。
- meta-security/kas、meta-updater/kas这两个目录(题目最初指向的目录)实际是上游社区层自带的自测配置,不是QLI2.0团队自己维护的主入口,如果审计报告只看这两个目录会得出"kas只是零星测试用途"的误判;真正承载"一键搭建整机"职责的是meta-qcom系列层的ci/*.yml。已用`git remote -v`核实两层都是独立git checkout(meta-security指向官方`git.yoctoproject.org/meta-security`,meta-updater指向`github.com/uptane/meta-updater`,均为`wrynose`分支),`kas/`目录内容是上游自己的提交历史产物,并非QLI2.0团队fork或添加。
- 已直接读取本机安装的kas 5.5包(`kas/schema-kas.json`+`kas/repos.py`/`libkas.py`)核实`repos:`条目的schema:字段严格限定在`name`/`url`/`type`/`commit`/`branch`/`tag`/`refspec`/`signed`/`allowed_signers`/`path`/`layers`/`patches`,且`additionalProperties: false`,不允许挂任何自定义扩展字段——即kas原生没有能直接承载QLI1.0 manifest里`x-quic-distributable`/`x-ship`这类扩展属性的位置;认证方式上kas不在yaml里存token/凭证,而是把`SSH_AUTH_SOCK`等环境变量透传进容器/git操作,完全依赖标准git认证(SSH agent/git credential helper),不是manifest声明式的凭证机制。这一子问题(kas侧技术可行性)已有明确答案,若要迁移,`x-quic-distributable`/`x-ship`及内网认证只能靠kas之外的wrapper脚本或CI层逻辑实现,不能靠repos:语法本身表达。QLI1.0是否真的有迁移到kas的计划,是路线图决策,已归入README《待拍板事项汇总》,此处不再重复列待确认。
