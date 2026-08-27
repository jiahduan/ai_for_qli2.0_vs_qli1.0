# System Architecture — Graphics (GPU/Adreno驱动栈)

## 对比范围

- **覆盖**:本文比较GPU驱动栈(内核态kgsl+用户态Adreno专有渲染驱动)的开源化程度、专有二进制交付形态变化、新增开源渲染路径,以及GPU侧对glvnd多vendor共存机制的实际影响;按子项列出双侧锚点:
  - GPU内核驱动(kgsl):
    - QLI1.0:`meta-qti-gfx-kernel/recipes/graphicsdlkm/graphicsdlkm_git.bb`(`LICENSE="GPL-2.0-only"`,`SRC_URI=file://vendor/qcom/opensource/graphics-kernel`本地编译)
    - QLI2.0:`meta-qcom/recipes-graphics/kgsl-dlkm/kgsl-dlkm_1.0.4.bb`(`git://github.com/qualcomm-linux/kgsl.git`,SRCREV锁定)
  - GPU用户态3D驱动(GLES/Vulkan/OpenCL专有blob)及其交付形态:
    - QLI1.0:`meta-qti-gfx-prop/recipes/adreno/adreno_6.0.bb`+`egl-wayland-subdriver.bb`(内部编译)
    - QLI2.0:`meta-qcom/recipes-graphics/adreno/qcom-adreno_1.855.5.bb`(`LICENSE="LICENSE.qcom-2"`,从qartifactory下载预编译包这一事实本身;分发基建的通用机制不在本文范围,见"明确排除")
  - GBM层:QLI1.0厂商fork`libgbm`(基于Mesa gbm 21.1.1) vs QLI2.0独立开源项目`meta-qcom/recipes-graphics/msm-gbm-backend/msm-gbm-backend.bb`(BSD-3-Clause-Clear)
  - 开源渲染路径新增:QLI2.0`meta-qcom/recipes-graphics/mesa/mesa.bbappend`(启用freedreno,含A704支持补丁+UBWC布局修复补丁),QLI1.0侧无对应
  - GPU驱动侧对glvnd多EGL vendor共存机制的实际影响:
    - 锚点:`10_adreno.json`(qcom-adreno固定安装) vs `50_mesa.json`(mesa/freedreno产出)
    - 证据:`libeglvendor.c`(`LoadVendorsFromConfigDir`按文件名字典序`scandir`加载)、`libegl.c`(`GetPlatformDisplayCommon`首个成功者绑定)
    - 说明:与Display.md共用同一份底层机制证据,但本文落点是"GPU用户态驱动与开源mesa如何共存",Display.md落点是显示合成/多输出场景,两者不互相转述
  - 离线shader编译遗留工具:QLI1.0`meta-qti-gfx-prop/recipes/adreno/clangtblgen.bb`(自带`adreno200/llvm`第三套独立LLVM副本,cmake target`Oxili`,专为Adreno 200生成shader工具) vs QLI2.0无对应recipe,全树未见依赖,判定遗留/未激活代码
  - X11子驱动:QLI1.0`meta-qti-gfx-prop/recipes/adreno-subdriver-x11/adreno-subdriver-x11_git.bb` vs QLI2.0无对应物,推测已整合进qcom-adreno预编译包内部打包逻辑
- **明确排除**:
  - SDM/HWC合成服务层、DRM/KMS显示管线、Wayland/Weston合成器与多显示拓扑 ——见[Display](Display.md)
  - GPU专有二进制(qcom-adreno等)预编译分发基建的通用机制(qartifactory/`softwarecenter.qualcomm.com`按组件名+版本/构建日期拉取,对标HY11/HY22变体分发) ——见[HY11_HY22](../Code_Composition/HY11_HY22.md)
  - GPU内核外置驱动模块(`-dlkm`)编译机制的通用框架(独立git仓库+SRCREV模式、`module_conf_`模块黑名单机制,涵盖kgsl但不限于kgsl) ——见[Kernel_Build](../Build_Architecture/Kernel_Build.md)
  - `meta-qti-gfx-kernel`/`meta-qti-gfx-prop` → `meta-qcom`的层归并本身(`recipes-graphics/`目录结构调整) ——见[Layer_Architecture](../Code_Composition/Layer_Architecture.md)
- **待定边界**:(无,已核实两处易混淆点均不构成待定:①glvnd底层机制证据被本文与Display.md共用引用,但落点不同(本文关注GPU驱动层vendor共存,Display.md关注显示合成/多输出场景),是有意的双落点而非归属不清;②A704对应具体SKU的待确认事项已在下方"待确认"节妥善承载,是硬件信息缺口而非文档归属问题)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| GPU内核驱动(kgsl) | `meta-qti-gfx-kernel`: `graphicsdlkm_git.bb`(`LICENSE="GPL-2.0-only"`,`RPROVIDES:${PN} += "kernel-module-msm-kgsl-${KERNEL_VERSION}"`,`SRC_URI=file://vendor/qcom/opensource/graphics-kernel`——即使目录名"opensource",实际仍是内部vendor源码树本地编译) | `meta-qcom/recipes-graphics/kgsl-dlkm/kgsl-dlkm_1.0.4.bb`: `SRC_URI="git://github.com/qualcomm-linux/kgsl.git;branch=gfx-kernel.le.0.0..."`,`LICENSE="GPL-2.0-only"` |
| GPU用户态3D驱动 | `meta-qti-gfx-prop`: `adreno_6.0.bb`(`LICENSE="Qualcomm-Technologies-Inc.-Proprietary"`,内部编译)、`egl-wayland-subdriver.bb` | `recipes-graphics/adreno/qcom-adreno_1.855.5.bb`(`LICENSE="LICENSE.qcom-2"`,从qartifactory URL下载,仍为专有二进制,仅下载渠道改变) |
| GBM层 | 厂商fork`libgbm`(基于Mesa gbm 21.1.1) | 独立开源项目`msm-gbm-backend`(BSD-3-Clause-Clear) |
| 开源渲染路径 | 无 | `mesa.bbappend`启用freedreno,含A704 GPU支持补丁+UBWC布局修复补丁 |
| 离线shader编译工具 | `meta-qti-gfx-prop/recipes/adreno/clangtblgen.bb`——自带独立LLVM源码树(`adreno200/llvm`,cmake target `Oxili`),专为极老Adreno 200 GPU(约2010年Snapdragon S1/S2时代)生成shader编译工具,与meta-clang层、AOSP预编译clang均无关,是第三套独立LLVM副本 | 无对应recipe,全树未发现其它recipe依赖它,判断为遗留/未激活代码 |
| X11子驱动 | `adreno-subdriver-x11_git.bb` | 无对应物,可能已整合进qcom-adreno预编译包内部打包逻辑 |

## 关键差异

- GPU内核驱动(kgsl/msm_kgsl):功能上大体延续,但分发链路真正开源化——从"内部专有仓库本地编译"转为"从公开GitHub仓库拉取,SRCREV锁定"。
- GPU用户态3D渲染驱动(GLES/Vulkan/OpenCL)在两侧均为专有二进制黑盒,未发生开源化,是全审计范围内"仍然未开源"的关键组件之一。
- GBM层从厂商fork转为独立开源项目,配合上游Mesa+freedreno。
- 新增对A704等新GPU代际的支持(mesa补丁显示A704被归入A6xx家族分组,与QRB2210 RB1所用的FD702同组),提示目标芯片范围已扩展/切换,但具体对应哪个SoC/评估板仍需硬件团队确认。

## 影响与风险

- GPU用户态3D渲染驱动依旧闭源,升级/安全补丁节奏仍完全依赖Qualcomm发布,BSP团队对该层的可控性未提升,是本次架构升级中"开源化程度最低"的子系统之一。
- freedreno(开源)与闭源Adreno blob共存,且已确认两者都会向同一个`${datadir}/glvnd/egl_vendor.d/`(及Vulkan icd.d)目录注册vendor json,存在真实的多vendor场景。核实`msm-gbm-backend.bb`后确认它本身不注册glvnd vendor,只是mesa的`libgbm`在msm平台dlopen的GBM后端插件;真正与`qcom-adreno`(`10_adreno.json`)竞争EGL vendor身份的是mesa自身——`mesa.bb`默认`PACKAGECONFIG`经`DISTRO_FEATURES`过滤器纳入`glvnd`(qcom-base.inc已声明该feature),`meta-qcom/recipes-graphics/mesa/mesa.bbappend`又追加启用`freedreno`,即mesa以`-Dglvnd=enabled`编译并生成自己的vendor json。两个json的实际文件名已从构建产物核实:`qcom-adreno`固定装`10_adreno.json`,mesa/freedreno实际产出的是`50_mesa.json`(`build/tmp/sysroots-components/armv8-2a/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json`)。`qcom-multimedia-proprietary-image.bb`显式拉入`qcom-adreno`,其继承的基础镜像同样带`glvnd`+`freedreno`的mesa,两者间未见`RCONFLICTS`,确认是真实同镜共存而非包管理层面互斥。全层未见任何`PREFERRED_PROVIDER`/优先级配置;libglvnd虽是上游git fetch、源码不在层内,但SRCREV锁定的源码已实际下载在`build/downloads/git2_gitlab.freedesktop.org.glvnd.libglvnd.git.tar.gz`,取出读`src/EGL/libeglvendor.c`确认了真实机制:`LoadVendorsFromConfigDir()`用`scandir()+strcmp`按文件名字典序枚举目录下全部`*.json`并逐一加载,`10_adreno.json`/`50_mesa.json`两个vendor都会被加载,不是二选一互斥关系;真正决定"某次调用归谁"的是`libegl.c`里`GetPlatformDisplayCommon()`——每次`eglGetDisplay`/`eglGetPlatformDisplay`按vendor list顺序(即文件名字典序,adreno在前)依次调用各vendor的`getPlatformDisplay`,第一个返回非`EGL_NO_DISPLAY`的vendor赢得那一次的display绑定,不是merge per-function也不是一次性选定唯一vendor。落到本场景:两个vendor若都能识别同一native display,字典序更靠前的`10_adreno.json`会先被尝试,探测成功即直接绑定,`50_mesa.json`只有在adreno显式返回`EGL_NO_DISPLAY`时才会被换上——默认场景下adreno实际胜出,根源是"文件名字典序决定探测顺序+先成功者绑定"这一通用规则的副作用而非glvnd对adreno的特殊优待,若两个json文件名前缀对调,结果会反转。
- 新GPU代际(A704)支持意味着即便芯片型号相同,也可能存在与QLI1.0时期不同的GPU IP版本,需按新硬件对待,而非简单假设"同代际换包"。该补丁(`0001-freedreno-Add-support-for-A704.patch`)是backport自mesa上游commit`8055fefea12c0e0527f425306617bb40fafc466a`的GPU ID枚举补丁,新增`chip_id=0xffff07000400`且沿用`CHIP.A6XX`分组(与QRB2210 RB1所用FD702同组),命名方式(`0xffff0700xxxx`)与FD702的"无speedbin fallback"写法(`0xffff07002000`)同构,即这是一个尚未绑定具体产品speedbin的通用占位ID。对当前linux-qcom 6.18.30内核里hamoa/lemans/monaco/sar2130p/talos等全部已知机型的dts做了`qcom,adreno-*` compatible字符串扫描,未发现任何一块现有dts声明为A704,即A704目前尚未出现在任何已知目标板的设备树中,是提前为未来/未上机型号做的驱动侧准备。公开渠道(mesa上游commit、Qualcomm产品页)未检索到"Adreno 704"对应的具体SoC/评估板型号,判断是尚未公开发布的新机型。

## 待确认

- **A704对应的具体SKU/评估板**——已确认该补丁是backport自上游mesa commit的通用GPU ID枚举补丁,chip_id是无speedbin绑定的占位值,当前代码库内全部已知机型dts均未声明A704,machine.conf/kernel dts也不含对应硬件识别信息,公开渠道也查不到"Adreno 704"对应的产品名(见"影响与风险"),已经是静态代码/公开资料能做到的极限。确认步骤:联系Qualcomm GPU团队确认A704对应哪个具体SoC/评估板型号,并据此规划该型号专属的图形一致性/兼容性测试计划。
