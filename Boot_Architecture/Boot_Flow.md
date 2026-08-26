# Boot Architecture — Boot Flow

## 对比总览

| 阶段 | QLI1.0 | QLI2.0 |
|---|---|---|
| PBL→XBL→TZ/HYP | 相同 | 相同 |
| 主Bootloader | ABL(基于EDK2定制) | u-boot(github.com/qualcomm-linux/u-boot.git) |
| 二级引导 | 无(ABL即UEFI shell) | systemd-boot |
| 内核镜像格式 | Android boot.img(`mkbootimg`) | UKI(Unified Kernel Image) |
| cmdline生成时机 | ABL运行时动态拼接 | 构建期静态烘焙进UKI |
| initramfs | 有vendor_boot/ramdisk概念 | 移除,依赖UKI内嵌initrd或无initrd |
| root挂载依据 | 运行时slot_suffix判定 | 单一`PARTLABEL=rootfs` |

## 关键差异

- 启动链从专有ABL/EDK2切换为开源u-boot+标准UEFI/systemd-boot/UKI组合。
- cmdline固化时机反转:QLI1.0运行时灵活但审计困难;QLI2.0构建期可审计可复现,但改参数需重新构建签名(详见Bootargs.md)。

## 影响与风险

- u-boot fork(`qualcomm-linux/u-boot`)的安全更新节奏需确认,是否仍有QTI官方长期支持。
- cmdline静态化对产线多SKU切换console/内存参数的场景不友好,需重新设计。
- Recovery/OTA触发路径完全不同,售后SOP需重写(详见Platform_Features/OTA_Mechanism.md)。

## 待确认

- QLI2.0的UEFI与u-boot具体加载关系(XBL→UEFI→u-boot调用链)。
- UKI cmdline是否计划增加dm-verity/measured-boot相关参数。
