# Platform Features — Flash Process

## 对比范围

- **覆盖**:
  - 真实产线刷机工具链的定位与归属确认(本文纠错核心,本次重新回源码树核实):`poky/meta-qti-bsp/classes/qimage.bbclass`第81-111行(`do_gen_partition_bin`任务依赖`gen-partitions-tool-native`/`ptool-native`/`qdl-native`)+`poky/meta-qti-bsp/recipes-devtools/qdl/qdl_git.bb`+`poky/meta-qti-bsp-prop/recipes-devtools/partition-utils/`+`poky/meta-qti-bsp/recipes-devtools/gen-partitions-tool/gen-partitions-tool-native_1.0.bb`;重新执行`grep -rl "inherit.*qimage" --include="*.bb" .`,命中19个`poky/meta-qti-bsp/recipes-products/images/qti-*-image.bb`产品镜像(如`qti-camera-image.bb`/`qti-generic-image.bb`/`qti-robotics-image.bb`),与正文"约20个"基本一致。
  - `qdl_git.bb`具体拉取来源重新核实:第34-35行`SRCREV = "22234e6af33af1848e36d4d4bc63264087b97892"`、`SRC_URI = "${CLO_LE_GIT}/abozhinov444.qdl.git;branch=caf_migration/abozhinov444/sparse_image_format;..."`,与正文描述一致,文件头注释显示该recipe本身derive自`meta-qcom`上游同名文件,佐证两侧工具链血缘相同。
  - downstream(maili)版本追溯文件重新核实:`sec_aus.txt`内容(`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`、`AU_LINUX_EMBEDDED_LE.FRAMEWORK.3.0_TARGET_ALL.01.310.237`)与`.repo/manifest.xml`里的同名tag逐字比对一致。
  - QLI2.0侧QDL/Firehose刷机文档与命令重新核实:`meta-qcom/docs/flashing.md`全文读取,VID:PID`05c6:9008`、`qdl --debug prog_firehose_ddr.elf rawprogram*.xml patch*.xml`等命令与正文描述一致;`meta-qcom/recipes-devtools/qdl/qdl_git.bb`的`HOMEPAGE`指向`github.com/linux-msm/qdl`。
  - QLI2.0分区静态资源产出重新确认:`meta-qcom/recipes-bsp/partition/qcom-partition-conf_git.bb`存在,产出`rawprogram*.xml`/`patch*.xml`/GPT bin。
  - 首次刷机与OTA升级路径的边界(仅确认两者独立,不深入OTA机制细节)。
- **明确排除**:
  - OTA后续升级路径与差分/回滚机制本身 ——见[OTA_Mechanism](../OTA_Mechanism/OTA_Mechanism.md)
  - 分区表设计与具体分区数量对比(`rawprogram*.xml`/GPT bin实际内容) ——见[Partition_Layout](../../Boot_Architecture/Partition_Layout/Partition_Layout.md)
  - kas`base.lock.yml`集中锁定机制本身(本文仅将其作为`sec_aus.txt`的对应物引用,不展开锁定机制细节) ——见[Build_Tools](../../Build_Architecture/Build_Tools/Build_Tools.md)
- **待定边界**:(无,已核实。本次重新检索`poky/meta-qti-bsp*`及QLI2.0侧`meta-qcom/recipes-bsp/partition`、`meta-qcom/recipes-devtools/qdl`,未发现文档纠错记录之外的新遗漏目录或工具链缺口。)

## 对比总览

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| 刷机文档 | 未找到面向终端的完整QDL/EDL刷机步骤文档(`release/`、`framework_release/`、`sdk-tools/`均偏内部构建/发布基础设施;真正的刷机工具链在`poky/meta-qti-bsp*`里,但也没有配套的整合文档) | `meta-qcom/docs/flashing.md`提供从工具编译到EDL刷写的完整、可复现步骤 |
| 内部构建脚本 | `release/`(`syncbuild.sh`、`create_bin_projects.sh`、`updatepack`、`diffpack`、Klocwork静态扫描配置)与`framework_release/`(`build_levm.sh`、`syncbuild.sh`),服务于内部CI打包(`updatepack`/`diffpack`疑似用于生成升级包/差分包) | 不适用 |
| SDK工具文档 | `sdk-tools/`("QIM SDK")提供`Docker.md`(29KB)、`Host.md`(21KB)、`scripts/host/{docker_env_setup.sh, host_env_setup.sh}`、`scripts/image/{common,device,layers,remote}`、`targets/*.json`(`LE.PRODUCT.*.json`、`LE.QCLINUX.1.0.json`);`Host.md`中出现"Freshly flashed device with metabuild"、"Prepare Device Connected To Local PC After Image Or Metabuild Flash"等章节标题,说明确有刷机后处理步骤文档,但未见QDL/fastboot工具本体或详细刷写命令(`QDL`/`9008`关键字全库命中均为无关的第三方测试向量文件) | 不适用 |
| 刷机流程步骤 | 工具链实际位于`poky/meta-qti-bsp/classes/qimage.bbclass`:`do_gen_partition_bin`任务依赖`qdl-native`(`poky/meta-qti-bsp/recipes-devtools/qdl/qdl_git.bb`,BSD-3-Clause,拉取内部CAF镜像`abozhinov444.qdl.git`分支`caf_migration/abozhinov444/sparse_image_format`)、`ptool-native`(`poky/meta-qti-bsp-prop/recipes-devtools/partition-utils/`,`ptool.py`生成`rawprogram*.xml`/`patch*.xml`/GPT bin,Qualcomm-Technologies-Inc.-Proprietary许可)、`gen-partitions-tool-native`;该class被`qti-camera-image.bb`/`qti-generic-image.bb`/`qti-robotics-image.bb`等约20个真实产品镜像inherit,非测试用途。仅缺一份面向终端工程师的、类似`flashing.md`的整合刷写步骤文档(`sdk-tools/scripts/image`是围绕`adb`/`rsync`的开发态增量包同步工具"QIM SDK",并非此工具链的入口) | 1)从`github.com/linux-msm/qdl`编译QDL工具(识别USB VID:PID `05c6:9008`即EDL模式设备);2)配置udev规则以非root权限访问USB;3)进入RB3 Gen2等板卡的EDL(Emergency Download)模式(拨码开关+F_DL按键);4)执行`qdl --debug prog_firehose_ddr.elf rawprogram*.xml patch*.xml`刷写`build/tmp/deploy/images/<machine>/core-image-base-<machine>.rootfs.qcomflash`产出的固件包 |
| 刷机协议 | 已确认复用同一芯片级机制:downstream(maili)`ptool.py`生成的产物文件名`rawprogram%d.xml`/`patch%d.xml`/GPT bin与QLI2.0命名格式一致,同为QDL/Firehose(EDL 9008);两者差异只在QDL工具本身的源码分发渠道(downstream(maili)走内部CAF镜像分支,QLI2.0直接拉`github.com/linux-msm/qdl`上游) | 明确使用QDL+Firehose(`prog_firehose_ddr.elf`+`rawprogram*.xml`/`patch*.xml`) |
| 版本追溯文件性质 | `summary_log.txt`/`sec_aus.txt`分别是Gerrit Change-Id清单与AU manifest标签快照,用于版本/变更追溯,不是刷机说明;`sec_aus.txt`内容仅两行:`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`、`AU_LINUX_EMBEDDED_LE.FRAMEWORK.3.0_TARGET_ALL.01.310.237`,与`.repo/manifest.xml`中image tag完全对应 | 无同名文件但有等价机制:`meta-qcom/ci/base.lock.yml`为每个layer仓库锁定精确commit hash,由`build-yocto.yml`的`kas-setup` job执行`kas lock`自动生成并作为构建artifact上传,取代人工维护的`sec_aus.txt` |
| 与OTA机制关系 | 首次刷机(已确认QDL/Firehose)与后续recovery-based OTA(详见OTA_Mechanism.md)是两条独立路径 | 首次刷机(QDL)与后续OSTree/aktualizr OTA是两条独立路径,OSTree只影响"刷机后"的增量升级,不改变首刷镶像方式 |

## 关键差异

- 已确认两侧底层芯片刷机机制一致(EDL/Firehose/QDL是芯片级机制,独立于Yocto版本;downstream(maili)`poky/meta-qti-bsp/classes/qimage.bbclass`与QLI2.0`meta-qcom/recipes-bsp/partition/qcom-partition-conf_git.bb`产出的`rawprogram*.xml`/`patch*.xml`/GPT bin命名格式一致),引入OSTree并未改变首次产线刷机流程——产线仍需下载完整rootfs/boot分区镶像通过QDL一次性写入;变化仅体现在"设备出厂后如何升级":downstream(maili)走recovery分区整包/差分刷写,QLI2.0走OSTree commit/deploy(详见OTA_Mechanism.md),因此产线刷机SOP基本可以保持不变,但售后/OTA升级SOP需要重新编写。
- downstream(maili)缺少集中的、面向工程师的刷机文档(分散在`sdk-tools/Host.md`、`Docker.md`等运行环境文档中),而QLI2.0在`meta-qcom/docs/flashing.md`做了标准化、版本可控(随代码仓库演进)的文档化,这本身是流程规范化的提升。

## 影响与风险

- 依赖downstream(maili)内部`release/`/`framework_release/`私有构建基建(syncbuild.sh、CRM相关脚本)的现有产线自动化脚本,需要重新对齐到QLI2.0的kas/bitbake标准构建产物路径(如`build/tmp/deploy/images/<machine>/*.qcomflash`)。
- `summary_log.txt`/`sec_aus.txt`这类基于Gerrit/AU manifest的追溯机制在QLI2.0没有同名对应物,但已确认有等效机制:`meta-qcom/ci/base.lock.yml`由CI自动生成,锁定每个layer仓库的精确commit hash,可以取代人工维护`sec_aus.txt`做"刷入版本安全基线核对"。
- 已核实`qcom-distro-sota`(OSTree-enabled)与默认`qcom-distro`的首刷镶像分区表/QDL脚本完全一致:`gpt_main*.bin`、`rawprogram*.xml`、`patch*.xml`来自`meta-qcom/recipes-bsp/partition/qcom-partition-conf_git.bb`按平台固定部署的静态资源,与DISTRO选择无关,`INITRAMFS_IMAGE`切换只改变`boot.img`里的initramfs内容,因此qcom-distro-sota不需要产线同步更新QDL脚本。
- downstream(maili)实际产线刷机工具链的位置已找到:此前只搜索了`sdk-tools/`、`release/`、`framework_release/`、`qc/`、`vendor/`、`src/`,漏掉了`poky/meta-qti-bsp*`——真正的工具链是`poky/meta-qti-bsp/classes/qimage.bbclass`(`do_gen_partition_bin`任务)+`recipes-devtools/qdl/qdl_git.bb`(qdl-native)+`meta-qti-bsp-prop/recipes-devtools/partition-utils/`(ptool-native,生成`rawprogram*.xml`/`patch*.xml`/GPT bin)+`recipes-devtools/gen-partitions-tool/`,并被`qti-camera-image.bb`等约20个真实产品镜像inherit,不是缺失或需要向产线团队额外索取的外部工具。
