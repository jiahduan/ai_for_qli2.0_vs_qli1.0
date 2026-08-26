# Boot Architecture — Bootloader

## 对比总览

| 维度 | QLI1.0(pebble) | QLI2.0(iq-9075-evk) |
|---|---|---|
| 主Bootloader | ABL(基于EDK2) | u-boot-qcom(基于上游u-boot) |
| 来源 | `file://edk2`本地打包,无公开版本号 | `git://github.com/qualcomm-linux/u-boot.git`,SRCREV固定commit |
| 签名工具 | `sectoolv2_sign_abl`(QTI私有) | `qtestsign`(v5/v6 mbn header) |
| EFI二级引导 | 无 | systemd-boot |
| 固件路线 | 单一路线 | 双轨:默认闭源固件+`open-fw.conf`开放固件(TF-A+开源u-boot) |

## 关键差异

- 从闭源专有工具链切换为开源社区维护,版本可追溯、可复现、可提PR上游。
- QLI2.0存在闭源/开放固件双轨制,QLI1.0无此选项。

## 影响与风险

- `qtestsign`看命名像测试签名,量产安全签名链路是否就位需安全团队确认。
- 双轨制增加BSP维护矩阵(两套defconfig+固件依赖),需评估CI覆盖度。

## 待确认

- `qtestsign`是否为量产签名方案最终形态。
- QLI1.0是否存在等价"开放固件"选项。
