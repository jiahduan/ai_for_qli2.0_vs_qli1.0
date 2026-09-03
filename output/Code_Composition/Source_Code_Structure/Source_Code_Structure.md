# Code Composition — Source Code Structure

## 对比范围

- **覆盖**:
  - 顶层源码汇聚目录存在性对照:QLI1.0`find src -maxdepth 1 -mindepth 1 -type d`(35个子目录,含1个构建残留`build-qti-distro-camerastack-debug`,真实34个专有组件)vs QLI2.0`find <QLI2.0根目录> -maxdepth 1 -iname "src"`确认顶层无同名汇聚目录
  - 两种源码获取模式的架构对照:"预取(pre-fetch)"模式(repo sync统一落地到`src/`)vs "按需拉取(recipe-driven fetch)"模式(以`meta-qcom/recipes-multimedia/camx/camx-dlkm_1.0.3.bb`的`SRCREV`字段为例),及该变化对合规/出口管制审计流程的影响
- **明确排除**:
  - `src/OTA`→`meta-updater`的架构范式替换完整分析 ——见[Layer_Architecture](../Layer_Architecture/Layer_Architecture.md)、[OTA_Mechanism](../../Platform_Features/OTA_Mechanism/OTA_Mechanism.md)
  - `src/security/*`(securemsm等)与`src/mdm-ss-mgr`在QLI2.0公开层树的逐项去向核实(TUI/MDM-QMI栈缺失结论、安全IPC/remoteproc迁移结论) ——见[Layer_Architecture](../Layer_Architecture/Layer_Architecture.md)
- **待定边界**:(无,已核实——现有"待确认"节讨论的"`src/security/*`与`src/mdm-ss-mgr`对应专有组件的用户态/上层部分是否仍以未纳入本次交付快照的私有kas overlay形式存在"是事实性开放问题[与Code_Sync_Method.md核实kas通用私有仓库接入机制是同一类问题的不同侧面],不是文档间归属边界问题)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 顶层src/汇聚目录 | 存在。`find src -maxdepth 1 -mindepth 1 -type d`实测35个子目录,其中1个(`build-qti-distro-camerastack-debug`)是构建工作目录残留,非专有源码组件,排除后剩34个真实组件目录:`adsprpc, android_compat, aosphal-adaptation, audio, bluetooth, bootctrl, coretech-config-vendor, device, diag, display, dspservices_ship, external, filesystems, frameworks, hardware, kernel-6.18, le-bins-1, mdm-init, mdm-ss-mgr, mink, oe-internal-tests, OTA, packages, qmi-framework, remotefs, security, ss-restart, ss-services, system, tftp, time-services, vendor, wlan, wlan-proprietary` | `find /local/mnt/workspace/jiahduan/qli2.0/0817 -maxdepth 1 -iname "src"`无输出,顶层不存在任何src/汇聚目录 |
| 落地方式 | 子目录内部嵌套多层git仓库(如`src/wlan/qcacld-3.0`、`src/security/securemsm`、`src/OTA/recovery`),均通过符号链接指向`.repo/projects/src/...`,本质是repo manifest中`path="src/..."`的项目落地位置 | 对应的专有/半专有组件改为在各layer的`recipes-*/*.bb`中通过`SRC_URI`/`SRCREV`从远端git拉取源码到bitbake的`WORKDIR`,而非预先checkout到一个固定的顶层源码目录,例:`meta-qcom/recipes-multimedia/camx/camx-dlkm_1.0.3.bb`: `SRCREV="56b463cba50c1db1f2cc53ddd8790730f14bd8a8"` |
| 获取模式 | "预取(pre-fetch)模式"——manifest驱动`repo sync`时把所有专有源码(内核、图形、相机、安全、OTA等)一次性拉到统一的`src/`目录树下,构建时recipe通过本地路径引用 | "按需拉取(recipe-driven fetch)模式"——不存在集中`src/`汇聚目录,每个recipe自带`SRC_URI`+`SRCREV`,由bitbake的fetcher在构建时下载到`DL_DIR`/`WORKDIR`,遵循标准Yocto/OE recipe惯例 |

## 关键差异

- QLI1.0:"预取模式",专有源码统一汇聚到src/之下,可一次性盘点审计。
- QLI2.0:"按需拉取模式",构建更贴近标准Yocto习惯,recipe与源码引用强绑定、可复用性和上游可贡献性更高,不依赖外部manifest隐式约定路径。

## 影响与风险

- 集中`src/`目录的优点(所有专有代码可一眼盘点、便于一次性打包审计/出口管制审查)在QLI2.0中消失,审计需要转向"遍历所有层的recipe SRC_URI"这种更分散的方式,增加合规审查复杂度。
- 需要确认原`src/`下大量专有闭源模块(如`src/security/securemsm`、`src/mdm-ss-mgr`)在QLI2.0中到底是被开源化收编进某个新recipe(SRC_URI指向新公开仓库),还是仍以私有方式存在于本次未展示的其它私有layer/manifest中(本次交付的QLI2.0目录未见任何私有安全/mdm相关recipe)。
- `src/OTA`(QLI1.0的Android式bsdiff+recovery A/B升级)的承载方式已明确:由全新独立层`meta-updater`(aktualizr/OSTree OTA)整体替代,不是开源化收编也不是私有overlay,是架构范式整体替换,详见output/Code_Composition/Layer_Architecture/Layer_Architecture.md"旧layer→新layer映射表"及output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md。

## 待确认

- **`src/security/*`(securemsm等TrustZone/QSEE专有组件)与`src/mdm-ss-mgr`在QLI2.0中的确切承载方式**——经Layer_Architecture.md逐层核实,这两块专有组件在QLI2.0公开层树(`meta-qcom`/`meta-qcom-distro`/`meta-security`/`meta-updater`等)关键字搜索(`securemsm`/`mink-transport`/`subsys_modem`/`ssreq`/`pdc.daemon`/`trustedui`等)均无命中,生产态TUI本体和MDM/QMI专属用户态栈均确认缺失;安全IPC底层能力与modem内核态remoteproc框架则已分别确认迁移到主线Linux TEE子系统+`qcomtee`+`minkipc`、`CONFIG_QCOM_Q6V5_*`。唯一无法从代码库判断的是:这两块专有组件的用户态/上层部分是否仍以未纳入本次交付快照的私有kas overlay形式存在——这属于"快照之外的私有信息",判断方法与Code_Sync_Method.md核实kas通用鉴权机制(`SSH_PRIVATE_KEY`/`GIT_CREDENTIAL_HELPER`/`NETRC_FILE`等环境变量,详见该文档)是同一类"kas本身支持接入私有仓库,但QLI2.0具体是否真的挂了一个私有overlay"的问题——kas机制层面已确认支持私有仓库接入,但这不能反过来证明TrustZone/mdm-ss-mgr私有overlay确实存在,本地静态分析已到极限,需直接询问QLI2.0安全团队/BSP团队该私有overlay是否存在。
