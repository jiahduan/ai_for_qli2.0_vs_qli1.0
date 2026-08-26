# Build Architecture — Bitbake Version

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| bitbake版本 | 2.8.1 | 2.18.0 |
| 版本跨度 | — | 跨5个次要发布周期 |
| 覆盖语法 | `:append`/`:prepend`/`:remove`已是唯一合法语法,旧式`_append`硬性fatal | 相同(无变化,此项非本次升级差异点) |
| ChangeLog可用性 | 停留在1.9.x,无法逐条比对 | 同上 |
| 最低Python版本 | 3.8 | 3.9 |

## 关键差异

- 新旧覆盖语法迁移是更早的dunfell→kirkstone阶段完成的事,不是本次升级要处理的差异。
- 真正风险在fetcher、hash equivalence server等内部API的渐进式变化,无ChangeLog可查。

## 待确认

- 建议对同一批recipe做2.8.1 vs 2.18.0的`bitbake -e`输出diff验证。
- 排查两侧是否有依赖bitbake内部私有API的自定义bbclass。
