# System Architecture — Yocto

## 对比范围

- **覆盖**:本文比较双侧所依托的Yocto Project发布版本本身(release/codename/组织范式/官方breaking change),以及由此驱动的meta-qti-*层迁移机械性风险评估;按子方向列出双侧锚点:
  - Yocto Release身份与顶层版本证据:
    - QLI1.0:`poky/meta-poky/conf/distro/poky.conf`(`DISTRO_VERSION="5.0.19"`/`DISTRO_CODENAME="scarthgap"`)+`poky/meta/conf/layer.conf`(`LAYERSERIES_COMPAT_core="scarthgap"`,已实测核实)+`poky/bitbake/lib/bb/__init__.py`(仅作版本识别锚点,`__version__="2.8.1"`,已实测核实)
    - QLI2.0:`oe-core/meta/conf/layer.conf`(`LAYERSERIES_CORENAMES="wrynose"`/`LAYERSERIES_COMPAT_core="wrynose"`,已实测核实)+`bitbake/lib/bb/__init__.py`(`__version__="2.18.0"`,已实测核实,`git describe --tags`→`yocto-6.0.1`)+`meta-qcom/README.md`第44-45行("wrynose: LTS branch based on the Yocto Project 6.0 release, used by Qualcomm Linux 2.x.",已核实原文)
  - 顶层组织形态对比(仅作release范式演进的证据,不深挖仓库机制本身):QLI1.0`poky/`单体仓库(bitbake+meta+meta-poky一体)vs QLI2.0`bitbake/`与`oe-core/`独立顶层仓库,已用`ls -d */`两侧实测核实
  - 中间版本(5.1 styhead/5.2 walnascar/5.3 whinlatter/6.0 wrynose)官方breaking change逐条核实:已用户存档的`reference/System_Architecture/Yocto/`9份官网migration/release notes页面核实(本地网络受限无法直连docs.yoctoproject.org);覆盖UNPACKDIR迁移、虚拟工具链provider重命名、`DISTRO_FEATURES_DEFAULTS`/`_OPTED_OUT`默认值机制重构、`kernel-fitimage.bbclass`移除、SPDX/cve-check换代、pkgconfig显式inherit要求等具体条目
  - 官方版本基线交叉验证:Yocto Release官方基线(Linux kernel/gcc/glibc/LLVM/Python最低版本)与本仓库实测值的对照表,仅做"是否贴合官方基线"的交叉验证,不重复各专题文档自身的深度分析
  - meta-qti-*层迁移到wrynose规范的机械性风险扫描(前提:`../Code_Composition/Layer_Architecture.md`已完成的旧layer→新layer映射):
    - `grep -rlE 'S[[:space:]]*=[[:space:]]*"\$\{WORKDIR\}' meta-qti-*`(已复核,510命中)
    - `grep -rlE 'virtual/\$\{(TARGET|HOST|SDK)_PREFIX\}' meta-qti-*`(已复核,0命中)
    - `grep -rl "PKG_CONFIG_PATH" meta-qti-*`(已复核,3命中)
    - 对`Layer_Architecture.md`"未找到对应新层"的7个层/能力点,给出迁移工作量定性评估(零工作量/产品线取舍/需重新架构设计等),不重做映射本身
- **明确排除**:
  - bitbake版本本身的深度差异(内部API依赖排查/hash equivalence/patch差异对照) ——见[Bitbake_Version](../Build_Architecture/Bitbake_Version/Bitbake_Version.md)
  - 构建环境搭建/host依赖与容器化细节(kas-container、host最低配置核实) ——见[Build_Environment](../Build_Architecture/Build_Environment/Build_Environment.md)
  - 构建配置管理工具(kas vs repo)本身的机制对比 ——见[Build_Tools](../Build_Architecture/Build_Tools/Build_Tools.md)
  - GCC/glibc/LLVM/Rust/clang工具链版本与风险的深度分析 ——见[Toolchain](../Build_Architecture/Toolchain/Toolchain.md)
  - 内核构建机制细节(inherit module vs linux-kernel-base、dlkm recipe、KERNEL_MODULE_PROBECONF) ——见[Kernel_Build](../Build_Architecture/Kernel_Build/Kernel_Build.md)
  - 内核代码血统/仓库治理(GKI vs mainline-first、commit标签体系、同源性分析) ——见[Kernel_Code_Architecture](Kernel_Code_Architecture/Kernel_Code_Architecture.md)
  - `meta-qti-*`→`meta-qcom*`逐层映射、层数统计(59→21)、消失layer去向核实 ——见[Layer_Architecture](../Code_Composition/Layer_Architecture/Layer_Architecture.md)
  - 补丁总量统计与补丁存活率抽样分析 ——见[Patch_Management](../Code_Composition/Patch_Management/Patch_Management.md)
  - distro变体矩阵与DISTRO_FEATURES的QLI1.0/QLI2.0产品级对比 ——见[Distro_Version](Distro_Version/Distro_Version.md)
  - 设备树overlay/FIT image具体实现与rootfs overlayfs方案 ——见[Overlay](Overlay/Overlay.md)
  - OTA/OSTree/aktualizr机制与dm-verity/AVB完整性校验消失结论 ——见[OTA_Mechanism](../Platform_Features/OTA_Mechanism/OTA_Mechanism.md)
  - 代码提交/评审/CI/CVE扫描与许可证合规工具细节 ——见[Code_Submission](../Platform_Features/Code_Submission/Code_Submission.md)
  - 顶层仓库形态本身的git机制(symlink vs独立仓库、对象库/清理风险) ——见[Code_Repository](../Code_Composition/Code_Repository/Code_Repository.md)
  - 顶层`src/`汇聚目录消失与源码获取模式(预取vs按需拉取) ——见[Source_Code_Structure](../Code_Composition/Source_Code_Structure/Source_Code_Structure.md)
- **待定边界**:(无,已核实三处易混淆边界均不需挪动:①"官方发布版本breaking change本身"与"各专题文档消化这些breaking change的具体实现"——已确认前者是本文独占内容,后者(Toolchain/Kernel_Build/Overlay/Distro_Version/OTA_Mechanism/Code_Submission)均已在原文里显式`详见output/...`交叉引用,边界清晰;②"顶层组织形态"作为release范式证据(本文)与其git机制本身(Code_Repository/Source_Code_Structure)——两者引用的是不同层面的事实,不冲突;③meta-qti-*层迁移工作量评估表与Layer_Architecture.md的层映射——已确认前者显式声明以后者为前提、不重做映射,是同一批事实的两种呈现方式,非重复覆盖)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| Yocto Release | 5.0.19,codename scarthgap(LTS) | 6.0.1,codename wrynose(LTS) |
| 版本证据 | `poky/meta-poky/conf/distro/poky.conf`: `DISTRO_VERSION="5.0.19"`,`DISTRO_CODENAME="scarthgap"`;`layer.conf`: `LAYERSERIES_COMPAT_core="scarthgap"` | `oe-core/meta/conf/layer.conf`: `LAYERSERIES_CORENAMES="wrynose"`,`LAYERSERIES_COMPAT_core="wrynose"` |
| bitbake版本 | 2.8.1(`poky/bitbake/lib/bb/__init__.py`) | 2.18.0(`bitbake/lib/bb/__init__.py`),`git describe --tags`→`yocto-6.0.1` |
| 顶层结构 | `poky/`(bitbake+meta+meta-poky一体化仓库) | `bitbake/`与`oe-core/`独立顶层仓库,无poky整合层 |
| git提交证据 | poky HEAD commit: "poky.conf: Bump version for 5.0.19 release",日期2026-07-02 | — |
| 官方版本对照 | Qualcomm Linux 1.x ↔ scarthgap/kirkstone,对应Yocto 4.0-5.0 | Qualcomm Linux 2.x ↔ wrynose,对应Yocto 6.0(`meta-qcom-distro/README.md`明确写明) |
| 版本跨度 | 一整个LTS到下一个LTS,中间styhead/walnascar/whinlatter等常规版本均被跳过 | 同上 |

## 中间版本(5.1/5.2/5.3/6.0)迁移指南核查结果(已用官网存档页面核实)

> 本地代码仓库均未附带5.1及以后版本的迁移指南(QLI1.0的`poky/documentation/migration-guides/`只到migration-5.0;QLI2.0的`oe-core/`没有documentation目录),直连官网也被环境网络限制拦截。用户已把官网`docs.yoctoproject.org`的9份页面(scarthgap/styhead/walnascar/whinlatter/wrynose的Migration notes与部分Release notes)存档到`reference/System_Architecture/Yocto/`目录下,本节内容已基于这些存档页面逐条核实,不再是推测性内容。

### 版本号交叉验证(存档页面 vs 本仓库实测值)

官网存档页面给出了每个release的默认工具链基线版本,可与前面章节在两侧代码库中实测到的版本号直接对照:

| Yocto Release | 官网基线(Linux kernel / gcc / glibc / LLVM) | 本仓库实测值 | 对照结论 |
|---|---|---|---|
| 5.0 scarthgap | 6.6 / 13.2 / 2.39 / 18.1 | QLI1.0: GCC`13.4%`、glibc`2.39%`(详见output/Build_Architecture/Toolchain/Toolchain.md);meta-clang`LLVMVERSION=18.1.6` | glibc、LLVM与官网基线几乎逐位对上;GCC 13.4是13.x系列内的一个point release,同属官网列出的13.2基线家族;**内核号完全不对应**(QLI1.0实际内核是私有的Android GKI血统6.18.21,不走`linux-yocto`默认recipe,官网"6.6"只是`linux-yocto`参考recipe默认版本,与QLI1.0实际交付内核无关,详见output/System_Architecture/Kernel_Code_Architecture/Kernel_Code_Architecture.md) |
| 6.0 wrynose | 6.18 / 15.2 / 2.43 / 22.1.2 | QLI2.0: GCC`15.%`、glibc`2.43%`(详见output/Build_Architecture/Toolchain/Toolchain.md);`linux-qcom_6.18.bb`版本6.18.30 | gcc、glibc**精确匹配**官网基线;**内核大版本号6.18也与官网基线一致**(QLI2.0的`linux-qcom`虽然走的是独立git仓库而非标准`linux-yocto`,但版本选型6.18与wrynose默认参考内核版本一致,不像QLI1.0那样完全脱节,侧面印证QLI2.0在整体工具链选型上比QLI1.0更贴合Yocto官方LTS基线) |
| 6.0 wrynose(Python) | "Minimum Python version required on the host: 3.9" | `sanity.bbclass`硬编码Python最低3.9(详见output/Build_Architecture/Build_Environment/Build_Environment.md) | 精确匹配,此前的实测发现现已有官方文档依据 |

补充中间版本的基线演进,便于看清QLI2.0选型落在哪个具体节点上(数据来自各版本Release notes的官方New Features摘要,非推测):

| Yocto Release | Linux kernel | gcc | glibc | LLVM |
|---|---|---|---|---|
| 5.0 scarthgap | 6.6 | 13.2 | 2.39 | 18.1 |
| 5.1 styhead | 6.10 | 14.2 | 2.40 | 18.1.18 |
| 5.2 walnascar | 6.12 | 14.2 | 2.41 | 19.1.7 |
| 5.3 whinlatter | 6.16 | 15 | 2.42 | 21.1.1 |
| 6.0 wrynose | 6.18 | 15.2 | 2.43 | 22.1.2 |

可以看到gcc/glibc/LLVM是逐版本单调递增的一条平滑曲线,QLI2.0实测的GCC 15.x、glibc 2.43精确落在6.0这一端点上,而不是任何中间版本,说明QLI2.0团队是直接对齐到最新LTS(wrynose)而非停留在某个中间过渡版本,这与"QLI2.0没有历史包袱、可以一步到位选型最新基线"的判断吻合。

这组对照本身就是一个值得记录的发现:**QLI1.0虽然名义上是scarthgap(5.0),但其内核版本选型与Yocto官方基线完全脱节(私有Android GKI树);QLI2.0虽然内核也走独立仓库,但版本选型(6.18)与wrynose(6.0)的官方基线保持一致**,说明QLI2.0团队在"要不要贴合上游默认版本"这件事上比QLI1.0团队更谨慎,这也从另一个角度印证了output/System_Architecture/Kernel_Code_Architecture/Kernel_Code_Architecture.md里"mainline-first治理模式"的判断。

### 各版本关键breaking change(与本次审计强相关的项,已逐条核实原文)

**5.1 (styhead)**:
- `S = ${WORKDIR}`不再支持,必须改为`S = "${UNPACKDIR}"`;recipe里所有引用`SRC_URI`来的文件路径(常见于`do_configure`/`do_compile`/`do_install`/`LIC_FILES_CHKSUM`)如果用了`WORKDIR`都需要审查改为`S`或`UNPACKDIR`。`do_unpack`产出目录从`WORKDIR/`变为`WORKDIR/sources-unpack/`。
- `OLDEST_KERNEL`维持5.15。
- systemd新增`bpf-framework` PACKAGECONFIG(预编译eBPF,用于`RestrictFileSystems`/`RestrictNetworkInterfaces`)。
- 移除`TCLIBCAPPEND`、`VOLATILE_LOG_DIR`、`VOLATILE_TMP_DIR`等变量;移除`siteconfig.bbclass`。

**5.2 (walnascar)**:
- **`debug-tweaks`从`IMAGE_FEATURES`移除**,需手动拼接`allow-empty-password allow-root-login empty-root-password post-install-logging`。**这与QLI2.0侧qcom镜像(`qcom-minimal-image.bb`等)实测的IMAGE_FEATURES列表(`splash tools-debug allow-root-login post-install-logging`,详见output/System_Architecture/Overlay/Overlay.md/Display.md)高度吻合**,说明meta-qcom确实已经按新规范显式列出了这些feature,而不是依赖已废弃的debug-tweaks,是QLI2.0侧正确跟随wrynose规范的一个具体证据。
- systemd:split-usr/unmerged-usr支持被移除(systemd 255之后usrmerge默认隐含,不再是PACKAGECONFIG选项);journald持久化日志目录改为`/var/log/journal`(需设`Storage=persistent`);若`pni-names`不在DISTRO_FEATURES,Predictable Network Interface Names特性会被禁用(**QLI2.0的`qcom-base.inc`确实把`pni-names`加进了DISTRO_FEATURES**,详见output/System_Architecture/Distro_Version/Distro_Version.md,这与该行为衔接一致)。
- **虚拟工具链provider重命名**:`virtual/${TARGET_PREFIX}gcc`→`virtual/cross-cc`,`virtual/${HOST_PREFIX}binutils`→`virtual/cross-binutils`等。这是**meta-qti-*层recipe迁移时的具体机械性风险点**——任何引用旧式`virtual/${TARGET_PREFIX}xxx`语法的`DEPENDS`/`PREFERRED_PROVIDER`赋值都需要按新语法改写。
- Git fetcher:`branch=`参数现在是必填项,缺失会报错(此前只是警告)。
- `UBOOT_ENTRYPOINT`现在要求带`0x`前缀。

**5.3 (whinlatter)**:
- **poky仓库master分支不再更新**,官方转为推荐`bitbake-setup`工具或独立clone bitbake/openembedded-core/meta-yocto/yocto-docs——这与QLI2.0已经是"bitbake/oe-core独立顶层仓库"结构(详见output/System_Architecture/Yocto.md开头及output/Build_Architecture/Build_Tools/Build_Tools.md)完全吻合,说明QLI2.0采用独立仓库结构不是Qualcomm自己的选择,而是跟随了Yocto 5.3/6.0本身官方推荐的组织方式变化。
- `S = ${WORKDIR}/something`彻底不支持(5.1只处理了`S=${WORKDIR}`裸引用,5.3进一步覆盖带子路径的情况),Git fetcher不再解压到`git/`子目录而是`BB_GIT_DEFAULT_DESTSUFFIX`(默认等于`${BP}`)。官方甚至给出了批量sed修复脚本。
- **`kernel-fitimage.bbclass`被移除**,替换为`kernel-fit-image`class,且要求"创建一个新的专属recipe来构建FIT image"而不是复用基础kernel recipe(如从`bitbake linux-yocto`变为`bitbake linux-yocto-fitimage`)。**这精确解释了QLI2.0侧`meta-qcom/classes-recipe/dtb-fit-image.bbclass`+独立的`do_generate_qcom_fitimage`任务为什么要这样设计**(详见output/System_Architecture/Overlay/Overlay.md、output/Build_Architecture/Kernel_Build/Kernel_Build.md)——不是Qualcomm自己发明了一套新机制,而是必须遵循wrynose/whinlatter之后官方"FIT image必须走独立recipe"的强制要求,原来那种直接在kernel recipe里内建FIT逻辑的老方法已经被上游删除。
- systemd:`pni-names`默认策略从强制"mac"改为跟随systemd上游默认(255.8的`99-default.link`)。
- fitImage类型的`KERNEL_IMAGETYPE`不再支持(与上一条联动)。
- 移除未授权的linux-firmware固件(`REMOVE_UNLICENSED`)、`libsoup-2.4`、`babeltrace`、`rust-llvm`(**这与output/Build_Architecture/Toolchain/Toolchain.md里"Rust改为依赖llvm recipe而非私有rust-llvm"的实测发现完全对应**,现在有了官方commit依据)。

**6.0 (wrynose,QLI2.0对应版本,已完整核实)**:
- **默认`INIT_MANAGER`改为systemd**(此前nodistro默认是none);Poky蒸馏本身仍默认SysVinit不受影响。
- **DISTRO_FEATURES/MACHINE_FEATURES的默认值机制重构**:`DISTRO_FEATURES_BACKFILL`/`_BACKFILL_CONSIDERED`/`_DEFAULT`等变量全部废弃,改用`DISTRO_FEATURES_DEFAULTS`+`DISTRO_FEATURES_OPTED_OUT`(以及MACHINE版本)。**这精确解释了QLI2.0侧`qcom-distro-sota.conf`里`DISTRO_FEATURES_OPTED_OUT += " ptest"`这个写法**(详见output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md)——`OPTED_OUT`正是wrynose引入的新变量名,不是Qualcomm自造的命名。
- 默认新增以下DISTRO_FEATURES(写死在`bitbake.conf`里,不再需要distro层显式添加):`multiarch`、`opengl`、`ptest`、`vulkan`、`wayland`。**已核实实际范围比这5项更大**:`oe-core/meta/conf/distro/include/default-distrovars.inc:28-32`里`DISTRO_FEATURES_DEFAULTS`的完整列表是`acl alsa bluetooth debuginfod ext2 ipv4 ipv6 wifi xattr nfs zeroconf pci 3g nfc x11 vfat seccomp pulseaudio gobject-introspection-data ldconfig opengl ptest multiarch wayland vulkan`;对比`meta-qcom-distro/conf/distro/include/qcom-base.inc:15-27`里`DISTRO_FEATURES:append`真正由meta-qcom主动追加的只有`efi glvnd kvm minidebuginfo opencl overlayfs pam pni-names polkit security tpm2 virtualization`(其中`wifi`/`x11`是对官方默认值的重复声明,不算新增)。结论:wayland/vulkan/opengl/ptest/multiarch,以及bluetooth/x11/pulseaudio这些经常被拿来讲"QLI2.0选择了开源图形/音频栈"的feature,**全部是wrynose官方默认值,不是meta-qcom的架构选择**;meta-qcom真正主动决定的是efi/glvnd/kvm/pni-names/polkit/security/tpm2/virtualization/overlayfs这一组,这才是做"专有→开源"叙事时应该归功于QLI2.0团队的部分。
- `meta-poky/conf/templates/default`默认配置模板被移除,统一到`oe-core/meta/conf/templates/default`。
- U-Boot多配置声明方式变更:旧式`UBOOT_CONFIG[foo]="config,images,binary"`单变量逗号语法拆分为`UBOOT_CONFIG[foo]="config"`+独立的`UBOOT_CONFIG_IMAGE_FSTYPES[foo]`/`UBOOT_CONFIG_BINARY[foo]`/`UBOOT_CONFIG_MAKE_OPTS[foo]`/`UBOOT_CONFIG_FRAGMENTS[foo]`。旧语法仍兼容但官方已声明"下一版本移除"。**已核实QLI2.0无风险**:读了`oe-core/meta/classes-recipe/uboot-config.bbclass`的实际解析逻辑——它按逗号切分`UBOOT_CONFIG[foo]`的值,只有`len(items) > 1`(即写了`config,images,binary`这种多段式)时才会触发"Legacy use...is deprecated"警告。`meta-qcom/conf/machine/include/qcom-u-boot-common.inc`里全部7个机型(iq-615-evk/iq-9075-evk/qcs9100-ride-sx/qcs615-ride/qcs6490-rb3gen2/qrb2210-rb1/sdm845-db845c)的`UBOOT_CONFIG[x]`都只写了单个defconfig名字,没有逗号,且全层grep`UBOOT_CONFIG_IMAGE_FSTYPES`/`_BINARY`/`_MAKE_OPTS`/`_FRAGMENTS`均为0命中,所以QLI2.0从一开始就没有用过要被移除的legacy三段式写法,官方后续彻底删除legacy分支不会影响QLI2.0的构建。
- pkgconfig相关变量(`PKG_CONFIG_PATH`等)不再由`bitbake.conf`自动`export`,recipe需要显式`inherit pkgconfig`才能拿到这些变量——**这是meta-qti-*层recipe迁移时又一个具体的机械性风险点**,任何隐式依赖这些变量导出、但没有显式inherit pkgconfig的老recipe搬过去会构建失败。
- **SPDX 2.2支持彻底移除,只保留SPDX 3.0**(`create-spdx-2.2`class删除,commit `12abd05`);**`cve-check`class被移除,替换为`sbom-cve-check`class**(commit `00de455`),原来的`INHERIT += "cve-check"`要改成`OE_FRAGMENTS += "core/yocto/sbom-cve-check"`,产出文件命名和格式也变了(`.sbom-cve-check.yocto.json`/`.sbom-cve-check.spdx.json`取代`.cve.txt`)。**已核实QLI2.0侧无残留风险**:对QLI2.0已检出的全部层(meta-qcom/meta-qcom-distro/meta-audioreach/meta-security/meta-updater等)grep`cve-check`/`create-spdx`/`sbom-cve-check`/`INHERIT.*cve-check`,零命中——没有任何层的`.conf`/`.inc`/CI`.yml`里显式`INHERIT`过`cve-check`或`sbom-cve-check`,即CVE扫描在已检出源码里根本没被主动打开,不存在"还在用旧格式cve-check"的残留风险。若确实有CVE扫描在跑,必然是靠某个未提交进git的本地`local.conf`临时加的,需要找安全/合规团队要一份实际构建日志或`local.conf`模板核实(详见output/Platform_Features/Code_Submission/Code_Submission.md关于repolint.json的部分)。
- systemd彻底移除SysVinit兼容支持,`systemd`和`sysvinit`两个DISTRO_FEATURES不能再共存(此前是逐步弱化,6.0是彻底切断)。
- BitBake层面移除npm/npmsw、Bazaar、OSC、CVS四种fetcher。
- 移除`oelint.bbclass`;`vex`输出JSON文件后缀从`.json`改为`.vex.json`。

### Release Notes(新特性changelog)补充确认

- 6.0(wrynose)官方New Features摘要原文:"Linux kernel 6.18, gcc 15.2, glibc 2.43, LLVM 22.1.2, and over 300 other recipe upgrades"、"Minimum Python version required on the host: 3.9"——与本仓库实测值逐条吻合(见上表)。
- Clang/LLVM相关变更(6.0):`compiler-rt`移除对`libgcc`的依赖、`libcxx`移除GNU runtime依赖、新增`llvm-libgcc`作为libgcc/crt的替代品——这些是LLVM生态内部演进,不直接影响QLI2.0"内核构建走标准gcc、meta-clang功能并入oe-core主干"的既有结论(详见output/Build_Architecture/Toolchain/Toolchain.md)。

## meta-qti-*层迁移工作量评估

> 前提:output/Code_Composition/Layer_Architecture/Layer_Architecture.md已完成"旧layer→新layer"逐层映射核实,大部分meta-qti-*层(约38个)已能在meta-qcom/meta-qcom-distro/meta-audioreach/meta-security等新层中找到功能对应物,这部分属于"标准迁移"。**但"标准迁移"不等于"零风险的机械劳动"**——结合上一节从官网存档页面核实到的breaking change,这38个层的recipe搬迁过程中至少要过以下几道具体的坎,建议列入排期而不是笼统地写"改一下语法":
> 1. **`S = ${WORKDIR}/xxx`→`S = ${UNPACKDIR}/xxx`审查**(5.1+5.3引入):QLI1.0的meta-qti-*层里有大量`file://`本地拷贝型recipe(如`mmrm-kernel_1.1.bb`这类`inherit linux-kernel-base`的vendor驱动,详见output/Build_Architecture/Kernel_Build/Kernel_Build.md),这类recipe历史上很容易直接写`S = "${WORKDIR}"`或`S = "${WORKDIR}/某子目录"`,是本次核实到的、影响面最广的单一机械性风险点,需要对约4,864个真实补丁(详见output/Code_Composition/Patch_Management/Patch_Management.md)所依附的recipe逐一做`grep -rn 'S[[:space:]]*=[[:space:]]*"\${WORKDIR}'`扫描。
> 2. **虚拟工具链provider重命名审查**(5.2引入):任何`DEPENDS`/`PREFERRED_PROVIDER`里写死`virtual/${TARGET_PREFIX}gcc`等旧语法的recipe需要改为`virtual/cross-cc`等新语法。
> 3. **`inherit pkgconfig`审查**(6.0引入):隐式依赖`PKG_CONFIG_PATH`等变量导出但未显式inherit pkgconfig的recipe会直接构建失败。
> 4. **kernel-fitimage.bbclass用法审查**(5.3移除,已被kernel-fit-image替代):若meta-qti-*层里有任何vendor驱动/BSP recipe用了旧的`KERNEL_IMAGETYPE = "fitImage"`机制,搬到QLI2.0后必须改造为独立的FIT image recipe(QLI2.0侧`meta-qcom/classes-recipe/dtb-fit-image.bbclass`正是这套新规范下的实现,详见output/System_Architecture/Overlay/Overlay.md)。
>
> 这4项都是"确定会遇到、确定要改"的机械性工作,区别于下表列出的、需要业务/架构决策才能启动的7个层/能力点。

### 三项机械性风险的实际扫描结果(已用grep在QLI1.0 poky/meta-qti-*层实测,非估算)

| 风险项 | 扫描命令 | 命中文件数 | 结论 |
|---|---|---|---|
| `S = "${WORKDIR}..."` (5.1+5.3引入的UNPACKDIR迁移) | `grep -rlE 'S[[:space:]]*=[[:space:]]*"\$\{WORKDIR\}' meta-qti-*` | **510个**(裸引用`${WORKDIR}`39个+带子路径`${WORKDIR}/xxx`471个) | **真实的大风险点**,几乎全部集中在`file://`本地拷贝型vendor recipe(如`meta-qti-bsp/recipes-mmrm-kernel/`、`meta-qti-aosphal-adaptation/recipes/libhardware/`等),这类recipe搬到QLI2.0/wrynose后**必须逐一改写**为`S = "${UNPACKDIR}/xxx"`,否则直接报错,是本次审计中量化到的、meta-qti-*层迁移最大的单一机械性工作量来源 |
| `virtual/${TARGET_PREFIX}`/`${HOST_PREFIX}`/`${SDK_PREFIX}` 旧式虚拟工具链provider(5.2引入的cross-cc等新语法) | `grep -rlE 'virtual/\$\{(TARGET\|HOST\|SDK)_PREFIX\}' meta-qti-*` | **0个** | 此前判断"是具体机械性风险点"经实测**不成立**,meta-qti-*层没有用到这套旧语法,可从风险清单中排除 |
| `PKG_CONFIG_PATH`直接引用(6.0要求显式`inherit pkgconfig`) | `grep -rl "PKG_CONFIG_PATH" meta-qti-*` | **3个**(粗筛,未逐一确认是否已inherit pkgconfig) | 风险很小,数量少,可以逐一人工确认而不需要批量脚本处理 |

结论:meta-qti-*层迁移到wrynose规范的机械性工作里,**真正需要投入工程量的只有`S=${WORKDIR}`→`S=${UNPACKDIR}`这一项(510个文件)**,虚拟工具链provider改写不需要做,`inherit pkgconfig`补齐只是零星几处。这把此前"38个层是纯粹工程执行工作"的笼统判断,收窄成了一个具体、可排期、量级明确(510个文件逐一改写+验证)的任务。

> 下表针对Layer_Architecture.md中标记"未找到对应新层"的7个层/能力点,给出工作性质与量级评估,这些是真正需要架构师先做取舍决策、而不是简单搬代码就能解决的部分。

| 层/能力 | 缺失部分 | 工作性质 | 量级评估 | 前置依赖 |
|---|---|---|---|---|
| meta-qti-aosphal-adaptation | 整层(AOSP HAL适配) | 无需迁移 | **零工作量** | 已确认是架构决策性移除(放弃AOSP HAL路线),只需在文档/评审中确认知悉,不构成待办 |
| meta-qti-ss-mgr-prop(MDM/QMI专属栈:ssreq-server/pdc-daemon/psm/qmi-shutdown-modem/diag-reboot-app) | 整套用户态QMI守护进程 | 产品线取舍 | **零工作量或整套移植**,二者之一 | 取决于QLI2.0产品roadmap是否包含独立调制解调器(MDM)SKU;若不包含则零工作量,若包含则需要整套移植到新架构(QMI框架本身在meta-qcom中还在,详见recipes-support/qmi-framework,但这几个具体daemon需要重新适配) |
| meta-qti-cta-internal(CTA测试工具) | 测试App本体 | 随ss-mgr-prop联动 | **零工作量**(若MDM SKU不在范围内则该测试工具自然不需要) | 与上一条同一决策 |
| meta-qti-ss-mgr(用户态reboot-daemon,SSR失败后slot切换/EDL恢复) | 故障恢复策略与实现 | **需要重新架构设计,不是简单迁移** | 中-高:原逻辑依赖A/B分区切换(abctl),但QLI2.0确认是单一rootfs分区(详见output/Boot_Architecture/Partition_Layout/Partition_Layout.md),原方案在新分区模型下不成立,需要重新设计SSR持续失败后的恢复策略(选项包括:仅靠systemd/watchdog自动重启remoteproc、触发OSTree历史commit回滚、或走aktualizr远程干预),涉及安全/可靠性架构决策+中等量的新开发(一个systemd path unit或守护进程+可能的aktualizr API调用) | 需先有OTA/分区终态方案(详见output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md的P0待决策项),该决策会直接决定这里怎么设计 |
| meta-qti-sv-internal/-prop(EVA计算机视觉引擎:libeva固件+驱动+测试套件) | 整套闭源硬件加速能力 | **硬件确认存在,纯软件栈缺失**:`meta-qcom/conf/machine/kaanapali-mtp.conf`是QLI2.0真实定义的机型,QLI1.0的`eva-kernel`驱动里有专为"kaanapali"芯片写的`cvp_kaanapali_hal.c`,两边指向同一SoC,证明该芯片确实带EVA硬件IP(详见output/Code_Composition/Layer_Architecture/Layer_Architecture.md)。工作量:**高,且依赖Qualcomm内部资源**(闭源固件/驱动需针对新内核ABI和TrustZone接口重新编译,libeva可能需要从AOSP HAL风格重写为glib/camx风格接口,只有Qualcomm内部团队能做) | QLI1.0`meta-qti-eva-devicetree`标记`x-ship="hy11"`,EVA本就是HY11(fullstack)专属能力,QLI2.0现在机器人产品线定位下是否还需要这块能力,需产品团队拍板 |
| meta-qti-internal(kernel-tests/stability-tests/sat-module/memory-error-tests等QA工具) | 内部质量保证/基准测试工具集 | 视具体测试项决定移植或替换 | 低-中,且**优先级低**(不影响产品功能,只影响内部测试流程) | 建议按测试项拆分:部分可能有开源等价物可直接采用(如kselftest/LTP/stress-ng对应部分内核压测场景),部分Qualcomm专有的需要单独评估是否还有维护团队;不建议整层照搬迁移 |
| meta-qti-security-internal(minktransport-test/qtvm-test/TUI资源/GPTEE测试) | 内部测试工具(底层Mink IPC/TEE能力本身已迁移到位) | 测试代码重写 | 低-中:底层API已从QSEECom+mink-transport换成主线TEE子系统+qcom-tee+生产版minkipc(详见Layer_Architecture.md),旧测试代码本身无法复用(API完全不同),需要针对新API重写测试用例,难度低于EVA场景但仍需专人投入;**TUI(Trusted UI)生产能力**是否存在是独立更大的问题,若产品需要支付/生物识别等安全UI场景,需与安全团队单独立项确认 | 先确认是否仍需要对TEE/Mink IPC路径做常态化回归测试,若需要则安排重写工作;TUI能力缺口需要先由产品/安全团队定priority |

## 关键差异

- `LAYERSERIES_COMPAT`由scarthgap变为wrynose不是版本号往上挪一格,而是跨过了5.1/5.2/5.3三个完整release的breaking change(UNPACKDIR迁移、虚拟工具链provider重命名、DISTRO_FEATURES默认值机制重构、SPDX/cve-check机制换代等),叠加顶层组织从"厂商fork单体poky"转为"上游oe-core+独立BSP/distro层"的社区化拓扑,是一次架构范式转变而不只是版本升级;但版本号交叉验证表也说明,QLI2.0对Yocto官方基线的贴合程度(GCC/glibc/LLVM/内核大版本号全部精确对上wrynose官方基线)反而比表面上仍标注5.0(scarthgap)、但内核完全私有脱节的QLI1.0更高——版本号本身不能反映"是否真的活在Yocto生态里",要看具体组件版本是否贴基线。
- 三个中间版本的breaking change逐条核实后,真正需要投入工程量的机械性风险高度集中在一个维度上:`S=${WORKDIR}`→`UNPACKDIR`迁移实测510个文件命中,而虚拟工具链provider改写(0个文件)、`inherit pkgconfig`补齐(3个文件)都只是零星几处。"跨版本升级=处处踩坑"的直觉在数据上不成立,风险高度集中,这对排期估算比笼统的"过一遍breaking change清单"更有用。
- 38个已找到新家的meta-qti-*层和卡在决策的7项之间界限清晰:后者没有一项是纯技术难度问题,全部卡在产品线取舍(MDM SKU、EVA机器人产品定位)、架构决策(OTA终态方案先落地才能定SSR恢复策略设计)或事实确认(EVA芯片是否真的要继续支持)三类非技术门槛上——"BSP团队按清单逐层迁移"本身不是瓶颈,瓶颈是决策链没跑完。

## 影响与风险

- 迁移门槛是强制性、无过渡期的:未跟进`LAYERSERIES_COMPAT`声明的meta-qti-*层会在layer加载阶段直接报错,BSP团队必须在真正启动迁移前把约38个已知对应层的breaking change审查排入计划,而不是在迁移过程中逐个踩坑现场修——尤其是`S=${WORKDIR}`审查(510个文件),建议单独立项并给出明确完成节奏,不要和其余零星风险项混在一起估算工时。
- 7项卡在决策的层/能力中,`meta-qti-ss-mgr`(SSR恢复策略,依赖OTA/分区终态先落地)与EVA计算机视觉引擎已进入README《待拍板事项汇总》;`meta-qti-ss-mgr-prop`(MDM/QMI专属栈的产品线SKU取舍)此前只在本文档记录,已同步补充进README——否则容易被下游误判为"技术债务",而不是"需要产品/BSP团队先拍板"的事项。
- 中间版本breaking change里有几项已被QLI2.0现有实现规避而不构成遗留风险(如`kernel-fitimage.bbclass`被移除后,QLI2.0`dtb-fit-image.bbclass`已经是新规范下的实现;U-Boot多配置语法变更QLI2.0全部7个机型都只用了新写法),但这也说明QLI2.0当前实现是"精确踩在最新规范上",Yocto持续演进(下一个LTS)时同样需要持续跟进,不能假设一次迁移后就一劳永逸。
- 三方产品线(camerastack/xr/vnm/host)在QLI2.0是否落地,直接决定这38层迁移工作有多少是"现在就要做"还是"暂不需要"——该决策已记录在output/System_Architecture/Distro_Version/Distro_Version.md的影响与风险中,与本文档的meta-qti-*层迁移评估互为前提,不应分开单独排期。
