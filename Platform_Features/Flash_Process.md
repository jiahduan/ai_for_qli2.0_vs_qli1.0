# Platform Features — Flash Process

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 刷机文档 | 未找到面向终端工程师的完整刷机文档 | `meta-qcom/docs/flashing.md`完整流程 |
| 刷机工具 | 未见QDL/fastboot工具本体 | 编译`github.com/linux-msm/qdl` |
| 刷机协议 | 推测QDL/Firehose(未直接证实) | 明确QDL+Firehose(`prog_firehose_ddr.elf`+`rawprogram*.xml`) |
| 版本追溯文件 | `summary_log.txt`(Gerrit Change-Id清单)、`sec_aus.txt`(AU manifest标签) | 无对应文件,依赖git层tag/commit |
| 与OTA关系 | 首次刷机与recovery-based OTA是独立路径 | 首次刷机(QDL)与OSTree/aktualizr OTA是独立路径 |

## 关键差异

- 两侧底层芯片刷机机制(EDL/Firehose/QDL)大概率一致,是芯片级机制,独立于Yocto版本,OSTree引入不改变首次产线刷机流程。
- QLI1.0缺少集中文档,QLI2.0已标准化文档化,但依赖QLI1.0内部构建基建的现有产线自动化脚本需重新对齐到kas/bitbake标准产物路径。

## 待确认

- QLI1.0实际产线刷机工具链在哪个未展开的仓库(`sdk-tools/scripts/image`是否为入口)。
- QLI2.0是否有等价的"安全基线/AU标签追溯"机制。
- `qcom-distro-sota`与默认`qcom-distro`的镶像格式差异是否会导致刷机脚本/分区表需同步更新。
