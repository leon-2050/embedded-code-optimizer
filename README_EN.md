# embedded-code-skill

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT" />
  <img src="https://img.shields.io/badge/language-C-A8B9CC?style=flat-square&logo=c&logoColor=white" alt="C" />
  <img src="https://img.shields.io/badge/Claude%20Code-5678a0?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Cursor-7C3AED?style=flat-square&logo=cursor&logoColor=white" alt="Cursor" />
  <img src="https://img.shields.io/static/v1?label=&message=VSCode&logo=visualstudiocode&logoColor=ffffff&color=007ACC&style=flat-square" alt="VSCode" />
  <img src="https://img.shields.io/badge/RTOS-FreeRTOS%20%7C%20Zephyr%20%7C%20RT--Thread-orange?style=flat-square" alt="RTOS" />
</p>

> Embedded C code assistant for driver skeletons, legacy-code cleanup, low-level firmware review, RTOS guidance, build system configuration, and adapting one rule set to different IDE or agent environments.

[简体中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md)

---

## What This Repository Is

This repository has one rule entrypoint: `SKILL.md`.

`SKILL.md` helps the model produce stable, conservative, reviewable output when:

- writing new Embedded C driver skeletons (with function-level templates)
- cleaning up legacy driver, HAL/BSP, or register-access code
- reviewing ISR, DMA, cache, volatile, race, timeout, and overflow risks
- guiding RTOS task design, thread safety, and priority inversion prevention
- guiding build system configuration (CMake cross-compilation, linker scripts, startup code)
- guiding HAL-layer testing and on-target debugging strategies
- aligning repo code with skill rules: reuse if conformant, adapt without logic changes if not
- extracting the same rules for Cursor, VS Code, Claude-compatible agents, or `AGENTS.md`

It is **not** a substitute for a vendor reference manual, real register map, IRQ table, barrier rule, cache/DMA rule, timing requirement, or certification artifact.

---

## Quick Start

```bash
/ecs Generate an STM32 UART driver skeleton, base address 0x4000C000
/ecs Clean up this SPI init code, preserving register write sequence
/ecs Review this DMA ISR for race, volatile, or cache issues
/ecs Generate Cursor .cursor/rules/*.mdc rule content
/ecs Design FreeRTOS task priorities and stack sizes
/ecs Help me write CMake cross-compilation config and linker script
```

---

## Work Modes

| Mode | Purpose |
|------|---------|
| `GENERATE` | Write the smallest maintainable module; use labeled placeholders when hardware facts are missing |
| `REWRITE` | Clean up code while preserving public behavior, ABI, register write order, and timing-sensitive sequences |
| `REVIEW` | Lead with findings; prioritize correctness, hardware behavior, races, and portability risk |
| `INSTALL` / `ADAPT` | Convert `SKILL.md` guidance into target IDE or agent instruction files |

---

## Skill Architecture

`SKILL.md` is the single entrypoint. Its structure is organized as request classification, repository context, work mode, subdomain rules, and output contract.

```mermaid
%%{init: {"flowchart": {"curve": "step"}} }%%
flowchart TB
    A([User request])
    B[SKILL.md single entrypoint]
    C[Read repository context]
    D[Confirm hardware fact boundary]
    E{Select work mode}
    F[GENERATE: smallest module + placeholders]
    G[REWRITE: preserve behavior / ABI / register write order]
    H[REVIEW: findings first / risk ordered]
    I[INSTALL / ADAPT: generate target-repo instructions]
    J[Apply subdomain rules]
    K[Coding Standards]
    L[Driver Templates]
    M[Architecture Rules]
    N[RTOS Guidance]
    O[Build System]
    P[Test & Debug]
    Q[Industry Domains]
    R[Final output contract]

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

## Capability Matrix

| Layer | Coverage |
|-------|----------|
| Entry | Single `SKILL.md` with frontmatter (triggers, command name) |
| Context | Local headers, macros, status types, naming, SDKs, build flags, and existing drivers |
| Fact boundary | Label values as `USER_PROVIDED`, `REPO_DERIVED`, or `PLACEHOLDER`; do not guess hardware details |
| Work modes | `GENERATE`, `REWRITE`, `REVIEW`, `INSTALL`, `ADAPT` |
| Output contracts | Separate response shapes for generated code, rewrites, review findings, and IDE instructions |
| Coding standards | Naming, types, error handling, struct patterns, comments, and dynamic-allocation limits (deduplicated) |
| Driver templates | UART, SPI, I2C, DMA, CAN, GPIO, Timer, Watchdog, MIL-STD-1553 (with function-level skeletons) |
| Architecture rules | Cortex-M, Cortex-A, ESP32/Xtensa, RP2040, NRF52, RISC-V, PowerPC, SPARC V8 |
| RTOS guidance | FreeRTOS, Zephyr, RT-Thread: task design, thread safety, ISR interaction, priority inversion, deadlock prevention |
| Build system | CMake cross-compilation, linker script sections, startup code, compiler attributes |
| Test & debug | HAL mock pattern, assertion levels, on-target debugging conventions |
| Domains | Aerospace, military, industrial safety, automotive functional safety, general embedded |
| Anti-patterns | 5 typical anti-patterns (scattered registers, cache coherency, ISR blocking, volatile misuse, priority inversion) |
| Review checklist | Hardware sources, register access, concurrency, RTOS safety, behavior preservation, IDE-rule conflicts |
| Maintenance check | After skill edits, run manual smoke checks for generate, rewrite, review, RTOS, and domain scenarios |

---

## Core Rules

| Category | Rule |
|----------|------|
| Rule alignment | Reuse repo code if it conforms to skill rules; otherwise adapt to skill rules without changing logic |
| Hardware facts | Do not invent register offsets, bit fields, reset values, IRQs, barriers, or timing requirements |
| Output contract | Generate, rewrite, and review modes each have an IDE-friendly response shape |
| Types | Prefer fixed-width integers and `bool` in public interfaces |
| Error handling | Use `embedded_code_status_t` only when the project has no local convention |
| Register access | Use dedicated register definitions or existing vendor/CMSIS structs |
| Memory | Avoid dynamic allocation and VLAs in low-level drivers by default |
| Concurrency | Treat ISR, DMA, cache, critical sections, and memory ordering conservatively |
| RTOS safety | Never block in ISR; use FromISR APIs; protect shared data with synchronization primitives |

---

## Subdomain Coverage

`SKILL.md` includes these subdomain rule sets directly. They are no longer split into separate directories.

### Coding Standards

- Naming, pointer naming, fixed-width types, and `bool`
- Fallback status type: `embedded_code_status_t` (with `VALIDATE_NOT_NULL` and `VALIDATE_INIT`)
- Config structs, runtime handles, and state enums
- Magic numbers, buffer sizes, timeouts, retry counts, comments, and review checklist

### Driver Templates

- Common structure: `*_reg.h`, `*_reg_t`, `*_REG`, `MASK/SHIFT`
- **Function-level skeletons**: Full patterns for UART/SPI/GPIO/DMA init, transfer, and ISR handler
- Covers UART, SPI, I2C, DMA, CAN, GPIO, Timer, Watchdog, and MIL-STD-1553
- Treats templates as organization examples only; real offsets, reserved bits, reset values, and errata must come from target sources

### Architecture Rules

- Covers ISRs, barriers, DMA, cache, interrupt controllers, SMP, memory ordering, and CSR/SPR access
- Includes Cortex-M, Cortex-A, **ESP32/Xtensa**, **RP2040 dual-core**, **NRF52**, RISC-V, PowerPC, and SPARC V8 quick refs
- ESP32-specific patterns: `IRAM_ATTR`, `FromISR` APIs, dual-core workload split, high-level SPI API
- RP2040-specific patterns: Pico SDK, dual-core FIFO, DMA channel allocation
- NRF52-specific patterns: nrfx driver layer, GPIOTE callbacks, SoftDevice priority
- For unknown architectures, require source material; otherwise generate architecture-neutral skeletons with placeholders

### RTOS Guidance

- FreeRTOS, Zephyr, and RT-Thread API comparison table
- Task design: stack size, priority, creation order, watchdog
- Thread-safe data sharing: mutexes, queues, atomics
- ISR-to-RTOS interaction: never block, use FromISR APIs, keep short
- Priority inversion prevention: priority-inheritance mutexes
- Deadlock prevention: fixed lock ordering, timeout waits

### Build System

- Linker scripts: `.text`, `.rodata`, `.data` relocation, `.bss` zeroing
- Startup code: data copy, bss clear, SystemInit, main call order
- Compiler attributes: `interrupt`, `section`, `aligned`, `weak`, `always_inline`
- CMake cross-compilation template

### Test & Debug

- HAL mock pattern: function-pointer table for swappable HAL
- Assertion levels: `STATIC_ASSERT`, `ASSERT`, `SOFT_ASSERT`
- On-target debugging: debug pin, error code tracing, stack overflow detection, watchdog, log levels

### Industry Domains

- Covers Aerospace / DO-178C, Military / MIL-STD, Industrial / IEC 61508, Automotive / ISO 26262, General Embedded
- Each domain has default requirements (e.g., no dynamic allocation, safe state, interface isolation), but DAL/ASIL/SIL ratings are not treated as universal defaults

---

## Adapting To IDEs Or Agents

Use `SKILL.md` as the single source, then extract the core rules for the target tool:

These paths are **generated in the target repository**. They are not bundled files in this repository.

- Cursor: `.cursor/rules/*.mdc`
- VS Code / Copilot: `.github/copilot-instructions.md`
- VS Code scoped instructions: `.github/instructions/*.instructions.md`
- Claude-compatible agents: `CLAUDE.md`
- Generic agents: `AGENTS.md`

Prefer one always-on instruction file per target repository to avoid duplicated guidance.

---

## Package Layout

```text
embedded-code-skill/
├── SKILL.md       # Single rule entrypoint
├── install.sh     # Install script
├── README.md      # Chinese readme
├── README_EN.md   # English readme
└── README_JP.md   # Japanese readme
```

---

## License

MIT License
