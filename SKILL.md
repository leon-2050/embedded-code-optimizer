---
name: embedded-code-skill
description: "嵌入式 C 代码助手：驱动骨架生成、旧代码整理、低层固件审查、RTOS/构建系统/调试指导、IDE 规则适配"
command: ecs
user-invocable: true
triggers:
  - embedded
  - firmware
  - driver
  - HAL
  - BSP
  - ISR
  - DMA
  - register
  - MCU
  - SoC
  - Cortex-M
  - RISC-V
  - RTOS
  - FreeRTOS
  - 1553
  - PWM
  - ADC
  - DAC
  - watchdog
  - CAN
  - 嵌入式
  - 固件
  - 驱动
---

# Embedded C 代码助手 Skill

## 定位

帮助处理嵌入式 C 代码：驱动骨架生成、旧代码整理、代码审查、RTOS/构建系统/调试指导，以及 IDE 规则适配。

本 skill 提供**不绑定某个 IDE 或 agent 的保守编码规范**。任何真实寄存器偏移、位定义、reset 值、IRQ 号、时序限制、cache/DMA 规则和屏障要求，都必须来自目标芯片参考手册、厂商头文件、现有代码或用户提供的资料——**不编造硬件事实**。

## 使用原则

1. 先判断任务类型：`GENERATE`、`REWRITE`、`REVIEW`、`INSTALL` 或 `ADAPT`。
2. 先读目标仓库的头文件、宏、状态类型、命名、include 顺序、vendor SDK、编译开关和已有驱动样例。
3. **规范统一**：仓库已有代码若符合本 skill 规范则直接沿用；若不符合，在不改变原逻辑的前提下修改为符合本 skill 规范的写法。项目已使用 CMSIS 或厂商寄存器结构体时，基于它们生成代码，不要为了 fallback 再包一层。
4. **不编造硬件事实**：信息缺失时先说明缺口；若必须继续，使用清晰标注的 placeholder。
5. 输出便于 IDE 采用：优先给小补丁、限定代码块、文件/行号 findings 或明确的复制目标；除非用户明确要求大重写，不整文件替换。
6. 面向不同 IDE 或 agent 环境时，把本文件当作唯一规范入口，再按目标工具格式做轻量转写。
7. 风格问题排在 correctness、硬件行为、安全性、并发和可移植风险之后。

## 生成前必须确认的信息

| 信息 | 要求 | 示例 |
|------|------|------|
| 外设/模块名 | 必需 | `uart`, `spi`, `gpio`, `dma` |
| 硬件来源 | 强烈建议 | 参考手册章节、厂商头文件、现有驱动 |
| 芯片或架构 | 强烈建议 | `STM32F4`, `Cortex-M4`, `ESP32` |
| 基地址/位定义 | 生产代码必需 | `UART_BASE_ADDR = 0x4000C000U` |
| 项目约定 | 生成或重写前读取 | status type、命名、SDK、build macros |
| RTOS（如适用） | 驱动层需确认 | FreeRTOS、Zephyr、RT-Thread、裸机 |

缺少生产级硬件信息时，可以生成保守骨架，但必须标注 `USER_PROVIDED`、`REPO_DERIVED` 或 `PLACEHOLDER`。

---

## Fallback 编码规范

仅当目标仓库没有更强约定时使用。仓库已有代码若符合本规范则沿用，不符合则在不改变逻辑的前提下修改为符合本规范的写法。

### 命名

| 元素 | 规范 | 示例 |
|------|------|------|
| 变量 | `snake_case` | `rx_count` |
| 全局变量 | `g_snake_case` | `g_system_ticks` |
| 函数 | `camelCase` | `uartInit()` |
| 结构体/枚举类型 | `snake_case_t` | `uart_handle_t` |
| 枚举值 | `PREFIXED_SNAKE` | `UART_STATE_IDLE` |
| 常量/宏 | `SCREAMING_SNAKE` | `UART_SR_RX_READY_MASK` |
| 指针 | 项目无约定时用清晰语义名 | `rx_buffer`, `handle`；或 `p_rx_buffer` |

### 类型与错误处理

- 公共接口优先使用 `<stdint.h>`、`<stdbool.h>`、`<stddef.h>`；默认 `uint8_t` / `uint16_t` / `uint32_t`、`int32_t`、`bool`
- 不把 `int`、`char`、`long` 作为默认跨平台接口类型

项目没有既有 status 类型时，公共函数默认返回 `embedded_code_status_t`：

```c
typedef enum {
    EmbedCode_Ok          =  0,
    EmbedCode_ErrNullPtr  = -1,
    EmbedCode_ErrInvalidArg = -2,
    EmbedCode_ErrTimeout  = -3,
    EmbedCode_ErrBusy     = -4,
    EmbedCode_ErrNotInit  = -5,
} embedded_code_status_t;

#define VALIDATE_NOT_NULL(ptr) \
    do { if ((ptr) == NULL) return EmbedCode_ErrNullPtr; } while (0)

#define VALIDATE_INIT(handle) \
    do { if ((handle) == NULL || !(handle)->initialized) return EmbedCode_ErrNotInit; } while (0)
```

### 结构体模式

默认拆成配置、运行时句柄和状态：

```c
typedef struct {
    uint32_t base_address;  /* 外设基地址 */
    uint32_t baud_rate;     /* 波特率 */
} uart_config_t;

typedef struct {
    bool initialized;           /* 初始化标志 */
    volatile bool tx_busy;      /* 发送忙标志（ISR 写） */
    uint8_t *rx_buffer;         /* 接收环形缓冲区 */
    uint16_t rx_head;           /* 环形缓冲区写位置 */
    uint16_t rx_tail;           /* 环形缓冲区读位置 */
    uart_config_t config;       /* 配置参数 */
} uart_handle_t;

typedef enum {
    UART_STATE_IDLE      = 0,
    UART_STATE_TX_BUSY,
    UART_STATE_RX_ACTIVE,
    UART_STATE_ERROR,
} uart_state_t;
```

### 注释

- 注释语言遵循项目约定；项目无约定时可用中文或用户指定语言。
- 注释解释硬件原因、约束、时序和意图；不要逐行复述代码。
- Doxygen 文件头只在项目已有模式时添加。

---

## 寄存器抽象

- 每个外设 block 一个独立 `*_reg.h`，使用 `*_reg_t` 寄存器结构体或复用 vendor/CMSIS 已有结构体
- 一个明确入口访问寄存器（`*_REG` 或项目已有 wrapper），位字段使用 `MASK/SHIFT` 宏
- 不把裸寄存器地址写散在业务逻辑里
- 对 read-modify-write、reserved bits、write-one-to-clear、unlock sequence 保持谨慎

```c
#define SPI_BASE_ADDR  (0xA0010000U)

typedef struct {
    volatile uint32_t CTRL;    /* 控制寄存器 */
    volatile uint32_t STATUS;  /* 状态寄存器 */
    volatile uint32_t DATA;    /* 数据寄存器 */
} spi_reg_t;

#define SPI_CTRL_EN_MASK    (1U << 0)
#define SPI_CTRL_MODE_MASK  (3U << 2)
#define SPI_REG  ((spi_reg_t *)SPI_BASE_ADDR)
```

---

## 驱动模板

驱动模板用于组织代码，不是厂商级寄存器头文件。所有真实 offset、reserved bit、reset 值、时序和 errata 必须来自目标资料。

### 统一结构

```text
module/
├── module_reg.h   # 寄存器结构体、位定义或 vendor wrapper
├── module.h       # 公共接口
└── module.c       # 实现
```

### 函数级接口模板

以下模板展示典型驱动的公共接口设计。具体实现按 fallback 规范和目标资料生成。

**UART**：`uartInit(config, handle)` → `uartDeInit` / `uartSend` / `uartRecv` / `uartSendIT` / `uartRecvIT` / `uartSendDMA` / `uartRecvDMA` / `uartIRQHandler(handle)`

**SPI**：`spiInit(config, handle)` → `spiTransfer(handle, tx_buf, rx_buf, len, timeout)` / `spiSelectCS(handle, active)`

**GPIO**：`gpioInit(config, handle)` → `gpioWritePin(handle, pin, value)` / `gpioReadPin(handle, pin) → bool` / `gpioTogglePin(handle, pin)`

**DMA**：`dmaChannelInit(handle, channel, xfer_config)` → `dmaStartTransfer` / `dmaAbortTransfer` / `dmaIsTransferComplete` / `dmaIRQHandler`

Init 实现模式：1) 禁用外设 → 2) 配置参数（值来自厂商资料或 PLACEHOLDER）→ 3) 清除挂起标志 → 4) 使能 → 5) 标记 initialized

ISR 模式：读 STATUS → 按 mask 分支处理 → ring buffer 入队/通知任务 → 从不阻塞

### 模块索引

| 模块 | 寄存器 | 关键结构 |
|------|--------|---------|
| UART | `DATA, STATUS, CTRL, BAUD` | `config_t { base_address, baud_rate }`, `handle_t { initialized, rx_buffer, rx_head, rx_tail }` |
| SPI | `CTRL, STATUS, DATA, BAUD` | `config_t { base_address, clock_hz, master_mode }` |
| I2C | `CTRL, STATUS, ADDR, DATA` | 地址、方向、timeout 和 bus state 分离 |
| DMA | `GLOBAL_STATUS, channel[n].CTRL/SRC/DST/LEN` | channel 配置、buffer ownership 分离 |
| CAN | `CTRL, STATUS, BIT_TIMING, TX/RX_DATA` | `can_msg_t { id, dlc, data[8] }` |
| GPIO | `MODE, INPUT/DATA, OUTPUT_DATA, BIT_SET_RESET` | `gpio_mode_t { INPUT, OUTPUT, ALT, ANALOG }` |
| Timer | `CTRL, COUNT, AUTO_RELOAD, PRESCALER` | period、prescaler、callback 分离 |
| Watchdog | `KEY, RELOAD, STATUS` | unlock/feed/reload 保持显式 |
| MIL-STD-1553 | mode、cmd/status word、data words | `mil1553_mode_t { BC, RT, BM }`, `mil1553_msg_t { command_word, status_word, data_words[32] }` |

反模式：不要把寄存器访问散落成 `UART_DR(base)` 等地址宏。统一结构体更容易 review、mock 和迁移。

---

## 架构规则

架构相关代码包括 ISR、barrier、DMA、cache、interrupt controller、SMP、memory ordering、CSR/SPR 和 board bring-up。

### Quick Ref

| 架构 | Barrier | Interrupt | CSR/SPR | 代表芯片 |
|------|---------|-----------|---------|---------|
| ARM Cortex-M | `__DMB()/__DSB()/__ISB()` | NVIC | N/A | STM32, GD32, NXP |
| ARM Cortex-A | `dmb ish` | GIC | system registers | i.MX6/7, STM32MP |
| RISC-V | `fence` | PLIC/CLINT | `csrr` | FE310, CH32V |
| ESP32 (Xtensa) | `esp_cpu_dsb()` | INT matrix | `WSR`/`RSR` | ESP32, S2/S3 |
| PowerPC | `msync` | PIC | `mfspr` | MPC5748 |
| SPARC V8 | `stbar` | INTC | `rd psr` | LEON |

### ESP32 关键差异

- ISR 必须标记 `IRAM_ATTR`，否则 Flash 操作期间崩溃；变量用 `DRAM_ATTR`
- 中断中使用 `...FromISR()` 后缀 FreeRTOS API
- SPI/I2C 通过 `spi_bus_initialize()` 等高层 API，非直接写寄存器
- 双核：Core 0 跑 WiFi/BT 协议栈，应用放 Core 1

### RP2040 关键差异

- Pico SDK，双 Cortex-M0+；`multicore_launch_core1(entry)` 启动 Core 1
- 通过 `multicore_fifo_pop_blocking()` 跨核通信
- DMA 使用 `dma_claim_unused_channel()` + `dma_channel_config_t`

### NRF52 关键差异

- nrfx 驱动层 + SoftDevice BLE 协议栈
- GPIO 中断通过 `nrfx_gpiote_in_init()` 回调注册
- 应用中断优先级必须 > SoftDevice 优先级
- 时序敏感操作放 PPI（可编程外设互连）

### 未知架构处理

1. 根据芯片、工具链、vendor headers 和已有低层代码判断架构
2. 不确定时查官方文档或要求用户提供资料
3. 不能确认时，只生成架构无关 C 骨架，barrier/interrupt/cache maintenance 标成 placeholder
4. 不猜测 barrier、cache maintenance、DMA ownership、IRQ number 或 interrupt-controller 行为

---

## RTOS 指导

### 任务设计

| 关注点 | 规范 |
|--------|------|
| 栈大小 | 按实际使用量 + 20-30% 裕量，不盲目取默认值 |
| 优先级 | 优先级反转风险高的任务使用互斥量（非二值信号量） |
| 创建顺序 | 先创建同步原语，再创建使用它们的任务 |
| 看门狗 | 长期阻塞任务必须有喂狗机制 |

### 线程安全数据共享

- **任务间**：互斥量保护（`osMutexAcquire/Release`）
- **ISR→任务**：队列（FreeRTOS `xQueueSendFromISR` + `portYIELD_FROM_ISR`）
- **简单标志**：`<stdatomic.h>` 原子操作或 `volatile` + 显式 barrier

### ISR 与 RTOS 交互

- **禁止阻塞**：ISR 中绝不调用 `osDelay()`、`osMutexAcquire()` 等
- **使用 FromISR**：FreeRTOS 中必须用 `...FromISR()` 后缀 API
- **短且快**：ISR 只做读状态、清标志、通知任务、触发 DMA

### 常用 API 对照

| 功能 | FreeRTOS | Zephyr | RT-Thread |
|------|----------|--------|-----------|
| 任务 | `xTaskCreate()` | `k_thread_create()` | `rt_thread_create()` |
| 互斥量 | `xSemaphoreCreateMutex()` | `K_MUTEX_DEFINE` | `rt_mutex_create()` |
| 信号量 | `xSemaphoreCreateBinary()` | `k_sem_init()` | `rt_sem_create()` |
| 队列 | `xQueueCreate()` | `k_msgq_init()` | `rt_mq_create()` |
| 延时 | `vTaskDelay(pdMS_TO_TICKS(ms))` | `k_msleep(ms)` | `rt_thread_mdelay(ms)` |

### 死锁预防

- 多锁场景按固定顺序获取
- 超时等待替代无限等待
- 持锁期间不调用可能阻塞的 API
- 优先级继承互斥量优先于二值信号量

---

## 构建系统与链接

### Linker Script 关键点

```ld
MEMORY { FLASH (rx): ORIGIN=0x08000000, LENGTH=512K  RAM (rwx): ORIGIN=0x20000000, LENGTH=128K }
SECTIONS {
    .text   : { *(.text*) }   > FLASH
    .rodata : { *(.rodata*) } > FLASH
    .data   : { __data_start = .; *(.data*) __data_end = .; } > RAM AT > FLASH
    .bss    : { __bss_start = .; *(.bss*) *(COMMON) __bss_end = .; } > RAM
}
```

### Startup 代码

`Reset_Handler`：1) 搬运 `.data`（Flash→RAM）→ 2) 清零 `.bss` → 3) `SystemInit()` → 4) `main()`

### 编译器 Attribute

| 用途 | 写法 |
|------|------|
| 中断函数 | `__attribute__((interrupt("IRQ")))` |
| 指定 section | `__attribute__((section(".dma_buf")))` |
| 对齐 | `__attribute__((aligned(32)))` |
| 弱符号 | `__attribute__((weak))` |
| 始终内联 | `__attribute__((always_inline))` |

### CMake 交叉编译

```cmake
set(CMAKE_SYSTEM_NAME Generic)
set(TOOLCHAIN_PREFIX arm-none-eabi-)
set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_C_FLAGS_INIT "-mcpu=cortex-m4 -mthumb -Wall -Wextra")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-T${CMAKE_SOURCE_DIR}/linker.ld -Wl,--gc-sections")
```

---

## 测试与调试

### HAL Mock 模式

通过函数指针表实现可替换 HAL：

```c
typedef struct {
    void    (*init)(const config_t *);
    status_t (*send)(const uint8_t *, uint16_t);
} uart_hal_t;
```

生产用 `uart_hal_hw`，测试用 `uart_hal_mock`，驱动通过 `handle->hal` 指针操作。

### 断言分级

- `STATIC_ASSERT(cond, msg)` → `_Static_assert`，编译期
- `ASSERT(cond)` → 运行时，调用 `assertFailed(file, line)`
- `SOFT_ASSERT(cond, action)` → 生产代码不 crash，记录错误后执行 action

### On-Target 调试约定

| 约定 | 说明 |
|------|------|
| 调试引脚 | 保留至少 1 个 GPIO 用于 SWO/printf |
| 错误码追踪 | 错误路径记录文件/行号，宏开关控制 |
| 栈溢出检测 | 任务栈底部填 watermark pattern，运行后检查 |
| 日志级别 | ERROR > WARN > INFO > DEBUG，生产代码只保留 ERROR/WARN |

---

## 行业领域

| 领域 | 关键词 | 默认要求 | 不要默认声明 |
|------|--------|----------|-------------|
| Aerospace | DO-178C, DAL, ARINC | 无动态分配、确定性行为、无递归、需求 ID 可追踪 | DAL 等级、MC/DC 覆盖率 |
| Military | 1553B, SpaceWire, MIL-STD | 冗余、SEU 防护、BIT diagnostics | MIL-STD 等级 |
| Industrial | IEC 61508, SIL, PLC | safe state 明确、watchdog supervision | SIL 等级、SPFM/LFM |
| Automotive | ISO 26262, ASIL, CANFD | 接口隔离、故障传播控制 | ASIL 等级 |
| General | — | 不默认声明认证要求 | — |

只有用户或项目资料明确标准和等级时才写合规结论。

---

## 内存、安全和并发默认值

- 低层驱动、ISR 和 hot path 默认不用 `malloc/free/calloc/realloc`
- 禁止 VLA；缓冲区大小、timeout、retry count 使用命名常量
- critical section 要短、显式，沿用项目本地 helper
- ISR、DMA、cache coherency、volatile 和 memory ordering 必须保留硬件相关顺序
- 不发明 barrier、cache maintenance、DMA ownership 或 interrupt-controller 细节

---

## 输出契约

### GENERATE

1. 先列出缺失硬件事实。2. 标注值来源。3. 匹配仓库已有骨架或生成最小模块。4. 默认 `module_reg.h` + `module.h` + `module.c`。
输出顺序：`Missing Inputs → Assumptions → Proposed Files → Code`

### REWRITE

1. 归纳必须保留的行为/ABI/寄存器写入顺序。2. 修复语法/类型/安全错误。3. 优先 patch-sized rewrite。4. 硬件行为假设放代码后说明。
输出顺序：`Preserved Behavior → Rewritten Code → Assumptions`

### REVIEW

finding 先行，按严重程度排序：1) volatile/barrier/cache/DMA → 2) 寄存器写入/reserved bits → 3) timeout/overflow/空指针 → 4) IRQ/race/atomicity → 5) init/deinit/clock gating → 6) RTOS 优先级反转/死锁 → 7) ABI/风格

格式：`1. [High] path/to/file.c:42 - Description.`

### INSTALL / ADAPT

把本 `SKILL.md` 作为规范源，按目标平台生成适配文件。不要同时启用多份 always-on 指令。

| 平台 | 推荐入口 |
|------|----------|
| Codex skill | `SKILL.md` |
| Cursor | `.cursor/rules/embedded-code-core.mdc` |
| VS Code / Copilot | `.github/copilot-instructions.md` |
| VS Code scoped | `.github/instructions/embedded-code-core.instructions.md` |
| Claude agents | `CLAUDE.md` |
| Generic agents | `AGENTS.md` |

适配文件必须保留这些核心句子：
- 仓库已有代码若符合本 skill 规范则沿用，不符合则在不改变逻辑的前提下修改为符合本规范的写法；先适配仓库本地的 vendor 头文件、SDK 和 build macros。
- 不编造寄存器偏移、位定义、reset 值、IRQ 号、时序限制、屏障或 cache/DMA 规则。
- 硬件事实缺失时，要求提供来源或输出明确标注的 placeholder。
- 重写任务中保留公共行为、ABI、寄存器写入顺序和时序敏感序列。
- 审查任务中正确性、竞态、volatile/DMA/cache 问题优先；风格问题次要。

---

## 反例集

**1. 寄存器散落**：❌ `#define SPI_CTRL_ADDR (*(volatile uint32_t*)0xA0010000U)` + 魔法数字 → ✅ `SPI_REG->CTRL = SPI_CTRL_INIT_VAL`

**2. DMA cache coherency**：❌ 直接 DMA 读写无 cache 处理 → ✅ `SCB_InvalidateDCache_by_Addr()` 或放 non-cacheable section

**3. ISR 阻塞**：❌ `osSemaphoreAcquire(uart_sem, osWaitForever)` → ✅ `xSemaphoreGiveFromISR()` + `portYIELD_FROM_ISR()`

**4. volatile 漏用**：❌ `bool g_transfer_done; while(!g_transfer_done){}` → ✅ `volatile bool g_transfer_done;`

**5. 优先级反转**：❌ `xSemaphoreCreateBinary()` 保护共享资源 → ✅ `xSemaphoreCreateMutex()` 优先级继承

---

## 回查清单

- [ ] 仓库已有代码符合本规范则沿用，不符合则在不改变逻辑的前提下修改
- [ ] 硬件常量来自用户、仓库或 placeholder
- [ ] 不编造寄存器/IRQ/barrier/cache 规则
- [ ] 复用 vendor/CMSIS 结构
- [ ] 无裸寄存器地址散落在业务逻辑
- [ ] 无默认动态内存和 VLA
- [ ] 命名/类型/错误处理符合本 skill 规范
- [ ] REWRITE 保留行为/ABI/时序顺序
- [ ] REVIEW correctness 和硬件风险优先于风格
- [ ] ISR 无阻塞，RTOS 用 FromISR API
- [ ] DMA buffer 处理 cache coherency
- [ ] 共享变量正确使用 volatile/atomic/互斥量
- [ ] IDE 适配只启用一份 always-on 入口

---

## 维护自检

修改本 skill 后，用以下场景做 smoke check：

- `GENERATE`：UART/SPI/GPIO 驱动，缺位定义时是否 placeholder
- `REWRITE`：保留 public API、ABI、寄存器写入顺序
- `REVIEW`：优先指出 race/volatile/barrier/ownership 风险
- `INSTALL/ADAPT`：只保留一份 always-on 入口
- RTOS：共享数据有互斥保护，ISR 只用 FromISR
- 领域：DO-178C/MIL-STD/IEC 61508/ISO 26262 只在用户明确时写合规结论

通过标准：不编造硬件事实、仓库代码符合本规范或在不改变逻辑前提下统一、子领域无丢失或矛盾、README 与 SKILL.md 一致。
