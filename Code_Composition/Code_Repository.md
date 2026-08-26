# Code Composition — Code Repository

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 仓库模型 | 集中对象库(`.repo/projects*`)+分散工作树符号链接 | 标准多仓库(polyrepo),每层独立`.git`目录 |
| 独立clone能力 | 不可脱离`.repo`独立使用 | 每层可单独`git clone`使用/贡献 |
| 版本对应关系 | 单一manifest SHA对应整机版本 | 约21个层各自SHA,靠`base.lock.yml`统一收口 |
| 存储去重 | 有(集中对象库) | 无(未做定量对比) |

## 关键差异

- QLI1.0清理`.repo`会导致全部工作树失效;QLI2.0各层独立,删除互不影响。
- QLI2.0各层可独立打tag,版本追溯更细粒度但也更分散。

## 待确认

- QLI2.0是否有计划提供统一的"超级manifest"仓库汇总所有层版本。
