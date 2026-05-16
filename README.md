# embedded-code-skill

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT" />
  <img src="https://img.shields.io/badge/language-C-A8B9CC?style=flat-square&logo=c&logoColor=white" alt="C" />
  <img src="https://img.shields.io/badge/Claude%20Code-5678a0?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Cursor-7C3AED?style=flat-square&logo=cursor&logoColor=white" alt="Cursor" />
  <img src="https://img.shields.io/static/v1?label=&message=VSCode&logo=visualstudiocode&logoColor=ffffff&color=007ACC&style=flat-square" alt="VSCode" />
  <img src="https://img.shields.io/badge/RTOS-FreeRTOS%20%7C%20Zephyr%20%7C%20RT--Thread-orange?style=flat-square" alt="RTOS" />
</p>

> 嵌入式 C 代码助手，用于写驱动骨架、整理旧代码、审查低层固件、指导 RTOS 使用和构建系统配置，并把同一套规则适配到不同 IDE 或 agent 环境。

[简体中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md)

---

## 这个仓库是什么

这个仓库只有一个规则入口：`SKILL.md`。

`SKILL.md` 帮助模型在下面这些任务中保持稳定、保守、可审查的输出：

- 写新的嵌入式 C 驱动骨架（含函数级模板）
- 整理旧的驱动、HAL/BSP 或寄存器访问代码
- 审查 ISR、DMA、cache、volatile、竞态、timeout、overflow 等低层风险
- 指导 RTOS 任务设计、线程安全、优先级反转防护
- 指导构建系统配置（CMake 交叉编译、链接脚本、startup 代码）
- 指导 HAL 层测试和 on-target 调试策略
- 仓库代码符合本 skill 规范则沿用，不符合则在不改变逻辑的前提下统一
- 把同一套规则提取成 Cursor、VS Code、Claude-compatible agents 或 `AGENTS.md` 可用的指令

它**不是**芯片厂商参考手册，也不会替代真实寄存器表、IRQ、屏障、cache/DMA 规则、时序要求或认证资料。

---

## 快速开始

```bash
/ecs 生成一个 STM32 UART 驱动，基地址 0x4000C000
/ecs 整理这段 SPI 初始化代码，并保留寄存器写入顺序
/ecs 审查这段 DMA ISR 是否有竞态、volatile 或 cache 问题
/ecs 生成一份 Cursor .cursor/rules/*.mdc 规则内容
/ecs 设计 FreeRTOS 任务优先级和栈大小
/ecs 帮我写 CMake 交叉编译配置和链接脚本
```

---

## 工作模式

| 模式 | 用途 |
|------|------|
| `GENERATE` | 写新的最小可维护模块，缺硬件事实时标注 placeholder |
| `REWRITE` | 整理旧代码，保留外部行为、ABI、寄存器写入顺序和时序敏感序列 |
| `REVIEW` | finding 优先，先看 correctness、硬件行为、竞态和可移植风险 |
| `INSTALL` / `ADAPT` | 把 `SKILL.md` 规则转成目标 IDE 或 agent 的指令文件 |

---

## Skill 架构

`SKILL.md` 是单入口文件，按"请求识别 → 仓库上下文 → 工作模式 → 子领域规则 → 输出契约"的顺序组织。

```mermaid
%%{init: {"flowchart": {"curve": "step"}} }%%
flowchart TB
    A([用户请求])
    B[SKILL.md 单入口]
    C[读取仓库上下文]
    D[确认硬件事实边界]
    E{选择工作模式}
    F[GENERATE: 最小模块 + placeholder]
    G[REWRITE: 保留行为 / ABI / 写寄存器顺序]
    H[REVIEW: findings 优先 / 风险排序]
    I[INSTALL / ADAPT: 生成目标仓库指令]
    J[应用子领域规则]
    K[编码规范]
    L[驱动模板]
    M[架构规则]
    N[RTOS 指导]
    O[构建系统]
    P[测试与调试]
    Q[行业领域]
    R[最终输出契约]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    E --> G
    E --> H
    E --> I
    F --> J
    G --> J
    H --> J
    I --> R
    J --> K
    J --> L
    J --> M
    J --> N
    J --> O
    J --> P
    J --> Q
    K --> R
    L --> R
    M --> R
    N --> R
    O --> R
    P --> R
    Q --> R
```

---

## 功能矩阵

| 层级 | 覆盖内容 |
|------|----------|
| 入口层 | 单一 `SKILL.md`，含 frontmatter（触发词、命令名） |
| 上下文层 | 读取本地头文件、宏、status type、命名、SDK、编译开关、已有驱动 |
| 事实边界 | 缺少资料时标注 `USER_PROVIDED`、`REPO_DERIVED`、`PLACEHOLDER`，不猜硬件细节 |
| 工作模式 | `GENERATE`、`REWRITE`、`REVIEW`、`INSTALL`、`ADAPT` |
| 输出契约 | 生成代码、重写代码、review findings、IDE 指令分别有固定结构 |
| 编码规范 | 命名、类型、错误处理、结构体模式、注释、动态内存限制（已去重合并） |
| 驱动模板 | UART、SPI、I2C、DMA、CAN、GPIO、Timer、Watchdog、MIL-STD-1553（含函数级骨架） |
| 架构规则 | Cortex-M、Cortex-A、ESP32/Xtensa、RP2040、NRF52、RISC-V、PowerPC、SPARC V8 |
| RTOS 指导 | FreeRTOS、Zephyr、RT-Thread：任务设计、线程安全、ISR 交互、优先级反转、死锁预防 |
| 构建系统 | CMake 交叉编译、链接脚本 section、startup 代码、编译器 attribute |
| 测试与调试 | HAL mock 模式、断言分级、on-target 调试约定 |
| 行业领域 | 航空、军工、工业安全、汽车功能安全、General Embedded |
| 反例集 | 5 组典型反例（寄存器散落、cache coherency、ISR 阻塞、volatile 漏用、优先级反转） |
| 回查清单 | 硬件常量来源、寄存器访问、并发安全、RTOS 安全、行为保留、IDE 适配冲突 |
| 维护自检 | 修改 skill 后用 generate、rewrite、review、RTOS、领域场景做人工 smoke check |

---

## 核心规则

| 类别 | 规则 |
|------|------|
| 规范统一 | 仓库代码若符合本 skill 规范则沿用，不符合则在不改变逻辑的前提下修改 |
| 硬件事实 | 不编造寄存器偏移、位定义、reset 值、IRQ、屏障或时序要求 |
| 输出契约 | 生成、重写、审查分别有固定输出顺序，便于 IDE 应用 |
| 类型 | 公共接口优先使用固定宽度整数和 `bool` |
| 错误处理 | 项目无约定时使用 `embedded_code_status_t` |
| 寄存器抽象 | 使用独立寄存器定义或复用 vendor/CMSIS 结构 |
| 内存 | 低层驱动默认不使用动态分配或 VLA |
| 并发安全 | ISR、DMA、cache、critical section 和 memory ordering 必须保守处理 |
| RTOS 安全 | ISR 中禁止阻塞，使用 FromISR API；共享数据必须有同步保护 |

---

## 子领域覆盖

`SKILL.md` 里内置以下子领域规则，不再拆成单独目录。

### 编码规范

- 命名、指针命名、固定宽度类型、`bool`
- fallback status type：`embedded_code_status_t`（含 `VALIDATE_NOT_NULL` 和 `VALIDATE_INIT`）
- 配置结构体、运行时句柄、状态枚举的组织方式
- magic number、buffer size、timeout、retry count、注释和 review checklist

### 驱动模板

- 统一结构：`*_reg.h`、`*_reg_t`、`*_REG`、`MASK/SHIFT`
- **函数级骨架**：UART/SPI/GPIO/DMA 初始化、收发、ISR handler 完整模式
- 覆盖 UART、SPI、I2C、DMA、CAN、GPIO、Timer、Watchdog、MIL-STD-1553
- 模板只说明组织方式，真实 offset、reserved bit、reset 值和 errata 必须来自目标资料

### 架构规则

- 覆盖 ISR、barrier、DMA、cache、interrupt controller、SMP、memory ordering、CSR/SPR
- 包含 Cortex-M、Cortex-A、**ESP32/Xtensa**、**RP2040 双核**、**NRF52**、RISC-V、PowerPC、SPARC V8 quick ref
- ESP32 特有模式：`IRAM_ATTR`、`FromISR` API、双核分工、SPI 高层 API
- RP2040 特有模式：Pico SDK、双核 FIFO、DMA 通道分配
- NRF52 特有模式：nrfx 驱动层、GPIOTE 回调、SoftDevice 优先级
- 未知架构时要求资料来源；不能确认时只生成架构无关骨架并标注 placeholder

### RTOS 指导

- FreeRTOS、Zephyr、RT-Thread API 对照表
- 任务设计：栈大小、优先级、创建顺序、看门狗
- 线程安全数据共享：互斥量、队列、原子操作
- ISR 与 RTOS 交互：禁止阻塞、使用 FromISR API、短且快
- 优先级反转防护：优先级继承互斥量
- 死锁预防：固定锁顺序、超时等待

### 构建系统

- 链接脚本：`.text`、`.rodata`、`.data` 搬运、`.bss` 清零
- Startup 代码：data 搬运、bss 清零、SystemInit、main 调用顺序
- 编译器 attribute：`interrupt`、`section`、`aligned`、`weak`、`always_inline`
- CMake 交叉编译模板

### 测试与调试

- HAL mock 模式：函数指针表实现可替换 HAL
- 断言分级：`STATIC_ASSERT`、`ASSERT`、`SOFT_ASSERT`
- On-target 调试：调试引脚、错误码追踪、栈溢出检测、看门狗、日志级别

### 行业领域

- 覆盖 Aerospace / DO-178C、Military / MIL-STD、Industrial / IEC 61508、Automotive / ISO 26262、General Embedded
- 各领域有默认要求（如无动态分配、safe state、接口隔离等），但 DAL/ASIL/SIL 等级不作为通用默认值

---

## 适配到 IDE 或 Agent

以 `SKILL.md` 为唯一来源，再按目标工具需要提取核心规则。

下面这些路径是**目标仓库中的生成位置**，不是本仓库自带文件。

- Cursor：`.cursor/rules/*.mdc`
- VS Code / Copilot：`.github/copilot-instructions.md`
- VS Code scoped instructions：`.github/instructions/*.instructions.md`
- Claude-compatible agents：`CLAUDE.md`
- 通用 agent：`AGENTS.md`

同一个目标仓库里优先启用一份 always-on 指令，避免重复规则互相叠加。

---

## 包结构

```text
embedded-code-skill/
├── SKILL.md       # 唯一规则入口
├── install.sh     # 安装脚本
├── README.md      # 中文说明
├── README_EN.md   # 英文说明
└── README_JP.md   # 日文说明
```

---

## 许可

MIT License
