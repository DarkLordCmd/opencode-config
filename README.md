# opencode-config

Приватный репозиторий с конфигурацией и библиотекой установленных скилов для [opencode](https://opencode.ai) — CLI-агента для разработки.

> Репозиторий **приватный** и предназначен для персонального бэкапа и переноса настроек между машинами.

## Содержимое

| Путь | Что это |
|------|---------|
| `opencode.json` | Основной конфиг: провайдеры, плагины, MCP-серверы |
| `AGENTS.md` | Инструкции-правила для агента (distillation, репауза и т.п.) |
| `skills/` | 422 скила из `~/.config/opencode/skills` |
| `agents-skills/` | 61 скил из `~/.agents/skills` |

Исключено из репозитория через `.gitignore`: `node_modules`, `package.json`, `bun.lock`, `package-lock.json` — зависимости при переносе ставятся заново.

## Установка на новую машину

### 1. Клонировать репозиторий

```powershell
git clone https://github.com/DarkLordCmd/opencode-config.git
cd opencode-config
```

### 2. Скопировать конфиг и скилы на место

Windows:

```powershell
# конфиг
Copy-Item .\opencode.json $env:USERPROFILE\.config\opencode\opencode.json
Copy-Item .\AGENTS.md     $env:USERPROFILE\.config\opencode\AGENTS.md

# скилы opencode (копируется содержимое папки skills)
robocopy .\skills $env:USERPROFILE\.config\opencode\skills /E

# скилы из ~/.agents
robocopy .\agents-skills $env:USERPROFILE\.agents\skills /E
```

macOS / Linux:

```bash
cp opencode.json AGENTS.md ~/.config/opencode/
cp -r skills/* ~/.config/opencode/skills/
cp -r agents-skills/* ~/.agents/skills/
```

### 3. Поставить зависимости конфига

Конфиг ссылается на плагин `superpowers` (см. `opencode.json`). Установка в директории конфига:

```powershell
cd $env:USERPROFILE\.config\opencode
npm install   # или: bun install
```

Плагин подтянется по ссылке `superpowers@git+https://github.com/obra/superpowers.git`.

### 4. Внешние зависимости (не в репозитории)

Часть скилов вызывает внешние CLI, которые ставятся отдельно:

| Скил | Внешний инструмент |
|------|-------------------|
| `github-cli`, `gitlab-cli`, `slack-cli`, `jenkins-cli`, `grafana-cli`, `prometheus-cli`, `aws-cli`, `azure-cli`, `gcloud`, `aliyun-cli` | соответствующий CLI (`gh`, `glab`, `slack`, `jenkins-cli`, `curl` и т.д.) |
| `kubectl-basics`, `helm`, `pod-management`, `service-ingress`, `deployment`, `configmap-secret` | `kubectl`, `helm` |
| `terraform`, `investigate-drift`, `recover-state-lock`, `create-terraform-helm-upgrade-plan` | `terraform` |
| `mysql`, `postgresql`, `mongodb`, `redis`, `elasticsearch` | соответствующие клиенты БД |
| `agent-browser` | браузерная автоматизация (agent-browser CLI) |
| `mcp-builder` | Node.js + MCP SDK |
| `pdf`, `docx`, `pptx`, `xlsx` | Python-библиотеки (зависимости скила) |

### 5. Проверка

```powershell
opencode
# в сессии: перечислить доступные скилы и убедиться, что они подхватились
```

## Обновление бэкапа

Чтобы залить свежую версию скилов с текущей машины обратно в репозиторий:

```powershell
$repo = "$env:USERPROFILE\AppData\Local\Temp\opencode\opencode-config-staging"

# пересобрать содержимое
robocopy $env:USERPROFILE\.config\opencode\skills  $repo\skills        /E /XD node_modules
robocopy $env:USERPROFILE\.agents\skills        $repo\agents-skills /E
Copy-Item  $env:USERPROFILE\.config\opencode\opencode.json $repo\
Copy-Item  $env:USERPROFILE\.config\opencode\AGENTS.md    $repo\

cd $repo
git add -A
git commit -m "sync: update skills"
git push
```

## Каталог скилов

Ниже — полный список скилов по категориям с кратким описанием назначения. Каждый скил — это папка с файлом `SKILL.md` (и, часто, референсами), которые агент подгружает автоматически при совпадении задачи.

### AI и агентные системы

| Скил | Назначение |
|------|------------|
| `advanced-evaluation` | This skill should be used for advanced LLM evaluation: LLM-as-judge systems, direct scoring, pairwise comparison, rubric calibration, evaluator bias mitigation, confidence scoring, and automated quality assessment. |
| `agent-memory` | Session memory management, browser-based QA testing, and multi-agent coordination skill. Use when the user wants to persist learnings across sessions, review what the agent has learned about their codebase, prune stale knowledge, run browser-based testing with real Chromium, coordinate multiple A... |
| `agent-ui-design` | Design patterns for chat interfaces, agent UX, streaming UI, and tool visualization. Covers chat architecture, message types, streaming rendering, tool execution cards, and sandbox UI derived from 21st.dev Agents SDK documentation and templates. |
| `ai-engineer` | Expert AI/LLM engineering guidance. Use when the user asks about RAG, OpenAI, Azure OpenAI, prompt engineering, AI agents, MCP, vector databases, or evaluation pipelines. |
| `bdi-mental-states` | This skill should be used when modeling agent mental states with BDI concepts: beliefs, desires, intentions, RDF-to-belief transformations, rational agency traces, cognitive agents, BDI ontologies, and neuro-symbolic AI integration. |
| `context-compression` | This skill should be used when long-running agent sessions need context compression, structured summarization, compaction, token-per-task optimization, or durable handoff summaries that preserve decisions, files, risks, and next actions. |
| `context-degradation` | This skill should be used for diagnosing and mitigating context degradation: lost-in-middle failures, context poisoning, context clash, context confusion, attention-pattern issues, and agent performance degradation caused by accumulated or conflicting context. |
| `context-fundamentals` | This skill should be used to explain or reason about the foundational concepts of context engineering: what context is, the anatomy of a context window, how attention mechanics work, the U-shaped attention curve, why context quality matters more than quantity, and the mental models needed to inte... |
| `context-optimization` | This skill should be used for improving context efficiency: context budgeting, observation masking, prefix or KV-cache strategy, partitioning, token-cost reduction, retrieval scoping, and extending effective context capacity without lowering answer quality. |
| `core-actionbook` | Internal support skill for actionbook MCP selectors used by Rust documentation research workflows. Use only when another rust-skills workflow explicitly requests actionbook-backed selectors. |
| `core-agent-browser` | Internal support skill for agent-browser CLI workflows used by rust-learner, docs-researcher, and crate-researcher. Use only when browser automation is explicitly required. |
| `core-dynamic-skills` | Internal command support for dynamic Rust crate skill management. Use only when explicitly invoked by /sync-crate-skills, /clean-crate-skills, or /update-crate-skill. |
| `core-fix-skill-docs` | Internal maintenance support for checking and fixing generated Rust skill documentation references. Use only when explicitly invoked by /fix-skill-docs. |
| `create-skill` | Create a new SKILL.md file based on a guided conversation about a task or workflow. |
| `delegate` | Передача задачи сабагенту с сохранением контекста: основной агент держит только сжатое резюме. |
| `evaluation` | This skill should be used when building agent evaluation systems: deterministic checks, regression suites, multi-dimensional rubrics, quality gates, production monitoring, baseline comparison, and outcome measurement for agent pipelines. |
| `explore-docs` | Параллельное чтение и суммаризация всей markdown-документации проекта без загрузки главного контекста. |
| `filesystem-context` | This skill should be used when agent work needs file-backed context: durable scratchpads, tool-output offloading, just-in-time discovery, cross-agent handoff files, filesystem memory, or cleanup policies for context stored outside the prompt. |
| `harness-engineering` | This skill should be used when designing autonomous agent harnesses: research loops, evaluation scaffolds, locked and editable surfaces, durable logs, novelty gates, pruning, rollback, PR preparation, and human approval boundaries. |
| `hosted-agents` | This skill should be used when designing hosted or background agent infrastructure: sandboxed execution, remote coding environments, warm pools, session persistence, multiplayer collaboration, self-spawning agents, or Modal-style sandboxes. |
| `latent-briefing` | This skill should be used when the user asks to \"share memory between agents\", \"KV cache compaction for multi-agent\", \"orchestrator worker context\", \"latent briefing\", \"reduce worker tokens\", \"cross-agent memory without summarization\", or discusses Attention Matching compaction, recur... |
| `long-horizon-prompting` | This skill should be used when writing, enhancing, or evaluating the launch prompt for a long-running autonomous agent or a parallel multi-agent orchestration attacking a hard problem: pseudo-formal task briefs that define terms and an exact success predicate linguistically, enumerate non-countin... |
| `mcp-builder` | Build production-grade MCP (Model Context Protocol) servers that connect AI agents to external APIs, databases, and services. Use when the user wants to build an MCP server, integrate an external API with Claude or any AI agent, create custom tools for an AI agent, expose a service via MCP, or as... |
| `memory-systems` | This skill should be used for persistent semantic memory in agent systems: cross-session knowledge retention, entity tracking, temporal validity, graph or vector retrieval, memory consolidation, and memory benchmark selection. Route file-backed scratchpads to filesystem-context, handoff summaries... |
| `meta-cognition-parallel` | EXPERIMENTAL: Three-layer parallel meta-cognition analysis. Triggers on: /meta-parallel, 三层分析, parallel analysis, 并行元认知 |
| `multi-agent-patterns` | This skill should be used when designing multi-agent systems that need context isolation, supervisor or swarm coordination, explicit handoffs, parallel execution, or a decision on whether multiple agents are justified. |
| `project-development` | This skill should be used for project-level decisions about LLM-powered systems: whether an LLM is the right primitive for the task at hand, the shape of a multi-stage batch or agent pipeline, token and cost estimation, choosing between single-agent and multi-agent at the project level, structure... |
| `prompt-engineer` | Design, iterate, test, and version prompts for LLMs — system prompts, few-shot examples, chain-of-thought, structured output, and agentic tool-use prompts. Use when the user asks to write a prompt, improve an existing prompt, design a system prompt, add few-shot examples, control LLM output forma... |
| `research-agent` | Deep research and R&D investigation skill. Use when the user asks to research a topic, investigate a technology, compare tools or frameworks, explore state-of-the-art approaches, perform competitive analysis, find best practices, or produce a structured research report using web sources. |
| `self-improvement` | Captures learnings, errors, corrections, and feature requests to enable continuous improvement. Use when: (1) User corrects Claude ('No, that's wrong...', 'Actually...'), (2) User requests a capability that doesn't exist, (3) Claude realizes its knowledge is outdated or incorrect, (4) A better ap... |
| `self-improvement-loops` | This skill should be used when the harness, scaffold, workflow, or optimizer itself is the optimization target: recursive self-improvement (RSI) loops, meta-harnesses, self-improving harnesses that mine their own failures and propose bounded edits, evolutionary or population-based search over age... |
| `self-improving` | Self-reflection + Self-criticism + Self-learning + Self-organizing memory. Agent evaluates its own work, catches mistakes, and improves permanently. Use when (1) a command, tool, API, or operation fails; (2) the user corrects you or rejects your work; (3) you realize your knowledge is outdated or... |
| `tool-design` | This skill should be used for the tool-interface layer of an agent system specifically: writing tool descriptions agents can route on, designing tool schemas and response formats, naming conventions, actionable error recovery messages, MCP server design, tool-set consolidation, and deciding when ... |

### Rust

| Скил | Назначение |
|------|------------|
| `backend-rust` | Rust gRPC backend patterns, folder structure, module anatomy, and infrastructure wiring for the Anachak multi-tenant SaaS platform. |
| `coding-guidelines` | Use when asking about Rust code style or best practices. Keywords: naming, formatting, comment, clippy, rustfmt, lint, code style, best practice, P.NAM, G.FMT, code review, naming convention, variable naming, function naming, type naming, 命名规范, 代码风格, 格式化, 最佳实践, 代码审查, 怎么命名 |
| `domain-cli` | Use when building CLI tools. Keywords: CLI, command line, terminal, clap, structopt, argument parsing, subcommand, interactive, TUI, ratatui, crossterm, indicatif, progress bar, colored output, shell completion, config file, environment variable, 命令行, 终端应用, 参数解析 |
| `domain-cloud-native` | Use when building cloud-native apps. Keywords: kubernetes, k8s, docker, container, grpc, tonic, microservice, service mesh, observability, tracing, metrics, health check, cloud, deployment, 云原生, 微服务, 容器 |
| `domain-embedded` | Use when developing embedded/no_std Rust. Keywords: embedded, no_std, microcontroller, MCU, ARM, RISC-V, bare metal, firmware, HAL, PAC, RTIC, embassy, interrupt, DMA, peripheral, GPIO, SPI, I2C, UART, embedded-hal, cortex-m, esp32, stm32, nrf, 嵌入式, 单片机, 固件, 裸机 |
| `domain-fintech` | Use when building fintech apps. Keywords: fintech, trading, decimal, currency, financial, money, transaction, ledger, payment, exchange rate, precision, rounding, accounting, 金融, 交易系统, 货币, 支付 |
| `domain-iot` | Use when building IoT apps. Keywords: IoT, Internet of Things, sensor, MQTT, device, edge computing, telemetry, actuator, smart home, gateway, protocol, 物联网, 传感器, 边缘计算, 智能家居 |
| `domain-ml` | Use when building ML/AI apps in Rust. Keywords: machine learning, ML, AI, tensor, model, inference, neural network, deep learning, training, prediction, ndarray, tch-rs, burn, candle, 机器学习, 人工智能, 模型推理 |
| `domain-web` | Use when building web services. Keywords: web server, HTTP, REST API, GraphQL, WebSocket, axum, actix, warp, rocket, tower, hyper, reqwest, middleware, router, handler, extractor, state management, authentication, authorization, JWT, session, cookie, CORS, rate limiting, web 开发, HTTP 服务, API 设计, ... |
| `m01-ownership` | CRITICAL: Use for ownership/borrow/lifetime issues. Triggers: E0382, E0597, E0506, E0507, E0515, E0716, E0106, value moved, borrowed value does not live long enough, cannot move out of, use of moved value, ownership, borrow, lifetime, 'a, 'static, move, clone, Copy, 所有权, 借用, 生命周期 |
| `m02-resource` | CRITICAL: Use for smart pointers and resource management. Triggers: Box, Rc, Arc, Weak, RefCell, Cell, smart pointer, heap allocation, reference counting, RAII, Drop, should I use Box or Rc, when to use Arc vs Rc, 智能指针, 引用计数, 堆分配 |
| `m03-mutability` | CRITICAL: Use for mutability issues. Triggers: E0596, E0499, E0502, cannot borrow as mutable, already borrowed as immutable, mut, &mut, interior mutability, Cell, RefCell, Mutex, RwLock, 可变性, 内部可变性, 借用冲突 |
| `m04-zero-cost` | CRITICAL: Use for generics, traits, zero-cost abstraction. Triggers: E0277, E0308, E0599, generic, trait, impl, dyn, where, monomorphization, static dispatch, dynamic dispatch, impl Trait, trait bound not satisfied, 泛型, 特征, 零成本抽象, 单态化 |
| `m05-type-driven` | CRITICAL: Use for type-driven design. Triggers: type state, PhantomData, newtype, marker trait, builder pattern, make invalid states unrepresentable, compile-time validation, sealed trait, ZST, 类型状态, 新类型模式, 类型驱动设计 |
| `m06-error-handling` | CRITICAL: Use for error handling. Triggers: Result, Option, Error, ?, unwrap, expect, panic, anyhow, thiserror, when to panic vs return Result, custom error, error propagation, 错误处理, Result 用法, 什么时候用 panic |
| `m07-concurrency` | CRITICAL: Use for concurrency/async. Triggers: E0277 Send Sync, cannot be sent between threads, thread, spawn, channel, mpsc, Mutex, RwLock, Atomic, async, await, Future, tokio, deadlock, race condition, 并发, 线程, 异步, 死锁 |
| `m09-domain` | CRITICAL: Use for domain modeling. Triggers: domain model, DDD, domain-driven design, entity, value object, aggregate, repository pattern, business rules, validation, invariant, 领域模型, 领域驱动设计, 业务规则 |
| `m10-performance` | CRITICAL: Use for performance optimization. Triggers: performance, optimization, benchmark, profiling, flamegraph, criterion, slow, fast, allocation, cache, SIMD, make it faster, 性能优化, 基准测试 |
| `m11-ecosystem` | Use when integrating crates or ecosystem questions. Keywords: E0425, E0433, E0603, crate, cargo, dependency, feature flag, workspace, which crate to use, using external C libraries, creating Python extensions, PyO3, wasm, WebAssembly, bindgen, cbindgen, napi-rs, cannot find, private, crate recomm... |
| `m12-lifecycle` | Use when designing resource lifecycles. Keywords: RAII, Drop, resource lifecycle, connection pool, lazy initialization, connection pool design, resource cleanup patterns, cleanup, scope, OnceCell, Lazy, once_cell, OnceLock, transaction, session management, when is Drop called, cleanup on error, g... |
| `m13-domain-error` | Use when designing domain error handling. Keywords: domain error, error categorization, recovery strategy, retry, fallback, domain error hierarchy, user-facing vs internal errors, error code design, circuit breaker, graceful degradation, resilience, error context, backoff, retry with backoff, err... |
| `m14-mental-model` | Use when learning Rust concepts. Keywords: mental model, how to think about ownership, understanding borrow checker, visualizing memory layout, analogy, misconception, explaining ownership, why does Rust, help me understand, confused about, learning Rust, explain like I'm, ELI5, intuition for, co... |
| `m15-anti-pattern` | Use when reviewing code for anti-patterns. Keywords: anti-pattern, common mistake, pitfall, code smell, bad practice, code review, is this an anti-pattern, better way to do this, common mistake to avoid, why is this bad, idiomatic way, beginner mistake, fighting borrow checker, clone everywhere, ... |
| `rust-call-graph` | Visualize Rust function call graphs using LSP. Triggers on: /call-graph, call hierarchy, who calls, what calls, 调用图, 调用关系, 谁调用了, 调用了谁 |
| `rust-code-navigator` | Navigate Rust code using LSP. Triggers on: /navigate, go to definition, find references, where is defined, 跳转定义, 查找引用, 定义在哪, 谁用了这个 |
| `rust-daily` | Новости и ежедневные/недельные дайджесты по экосистеме Rust. |
| `rust-deps-visualizer` | Visualize Rust project dependencies as ASCII art. Triggers on: /deps-viz, dependency graph, show dependencies, visualize deps, 依赖图, 依赖可视化, 显示依赖 |
| `rust-learner` | Use when asking about Rust versions or crate info. Keywords: latest version, what's new, changelog, Rust 1.x, Rust release, stable, nightly, crate info, crates.io, lib.rs, docs.rs, API documentation, crate features, dependencies, which crate, what version, Rust edition, edition 2021, edition 2024... |
| `rust-refactor-helper` | Safe Rust refactoring with LSP analysis. Triggers on: /refactor, rename symbol, move function, extract, 重构, 重命名, 提取函数, 安全重构 |
| `rust-router` | Маршрутизатор для всех вопросов по Rust: ошибки компиляции, проектирование, сравнения. |
| `rust-skill-creator` | Use when creating skills for Rust crates or std library documentation. Keywords: create rust skill, create crate skill, create std skill, 创建 rust skill, 创建 crate skill, 创建 std skill, 动态 rust skill, 动态 crate skill, skill for tokio, skill for serde, skill for axum, generate rust skill, rust 技能, cra... |
| `rust-symbol-analyzer` | Analyze Rust project structure using LSP symbols. Triggers on: /symbols, project structure, list structs, list traits, list functions, 符号分析, 项目结构, 列出所有, 有哪些struct |
| `rust-trait-explorer` | Explore Rust trait implementations using LSP. Triggers on: /trait-impl, find implementations, who implements, trait 实现, 谁实现了, 实现了哪些trait |
| `unsafe-checker` | CRITICAL: Use for unsafe Rust code review and FFI. Triggers on: unsafe, raw pointer, FFI, extern, transmute, *mut, *const, union, #[repr(C)], libc, std::ffi, MaybeUninit, NonNull, SAFETY comment, soundness, undefined behavior, UB, safe wrapper, memory layout, bindgen, cbindgen, CString, CStr, 安全抽... |

### Frontend и UI-дизайн

| Скил | Назначение |
|------|------------|
| `a11y` | Systematically audit and remediate accessibility issues in UI, focusing on keyboard navigation, screen reader support, color contrast, semantic HTML, ARIA usage, and motion sensitivity. Use when the user wants to improve accessibility, make a component accessible, fix WCAG violations, add keyboar... |
| `accessibility` | WCAG conformance, BFSG compliance, semantic HTML, ARIA, keyboard navigation, contrast, forms, and assistive technologies. Defines binding rules for accessible web interfaces per WCAG 2.1 AA. |
| `accessibility-audit` | Audit React/Next.js UIs for WCAG 2.2 AA - contrast, ARIA, keyboard, forms, alt text |
| `accessible-components` | Use when building or reviewing interactive UI that must meet WCAG 2.2 AA — focus management, ARIA roles and states, keyboard navigation, labels, and visible focus. Covers the accessibility mistakes agents make most. |
| `adapt` | Adapt designs for narrow, medium, wide, embedded, or print web contexts without losing usability, hierarchy, or target sizing. Use when the user mentions responsive design, breakpoints, narrow layouts, viewport changes, touch-capable browsers, or cross-context adaptation. |
| `add-ui` | Generate 5 distinct, production-grade UI variations for a requested new or existing section, component, page, flow, or shell, then help the user preview and apply one. Use when the user asks to add or redesign UI like a hero, pricing, navbar, auth flow, dashboard shell, ecommerce surface, or data... |
| `animate` | Improve or implement purposeful motion systems, micro-interactions, gestures, and transition behavior for production-grade UI. Use when the user mentions animation, motion, transitions, micro-interactions, hover states, drawers, toasts, gestures, or making the UI feel more alive. |
| `arrange` | Improve layout composition, spacing systems, grouping, and visual rhythm. Use when the user mentions weak layout structure, arbitrary spacing, weak grouping, crowded composition, or layout monotony rather than priority/emphasis problems. |
| `audit` | Run technical quality checks across accessibility, performance, theming, responsive design, and anti-patterns. Generates a scored report with P0-P3 severity ratings and actionable plan. Use when the user wants measurable accessibility, performance, responsive, theming, or anti-pattern findings—no... |
| `bolder` | Increase visual impact, contrast, personality, and compositional confidence when a design feels bland, generic, or too safe. Use when the design needs more energy, confidence, or memorability—not when the real problem is clutter, over-intensity, or micro-detail polish. |
| `clarify` | Improve UX writing, marketing copy, labels, microcopy, instructions, and error messages so interfaces and product messaging are easier to understand and act on. Use when the user mentions confusing copy, unclear labels, bad error text, weak CTAs, hard-to-follow instructions, or wanting better UX ... |
| `colorize` | Build or refine UI color systems, warmth, semantic color, and color-based hierarchy in designs that are too gray, monochromatic, or missing color meaning. Use when the user mentions dull colors, gray UI, missing warmth, weak semantic color, or a need for stronger color hierarchy. |
| `color-theory` | Color models, palettes, contrast, color psychology, color harmonies, and dark mode for web projects. Defines the 60-30-10 rule, semantic color coding, design tokens, and WCAG contrast requirements. |
| `competitor-experience-audit` | Audit the brand, UX, and site design of the leading sites in a vertical as a set of observable cross-site patterns, producing the experience bar a new build must meet or beat. Use this skill whenever the user wants to assess the competitive design field, capture vertical conventions, identify the... |
| `critique` | Evaluate an interface from a UX perspective, assessing hierarchy, information architecture, emotional resonance, cognitive load, and overall quality with quantitative scoring and actionable feedback. Use when the user wants an overall design or UX review—not when the main need is measurable acces... |
| `dashboard-layout` | Use when building a dashboard or overview page — stat/KPI cards, chart placement, responsive grids, and a scannable hierarchy. Covers metric cards with deltas, where charts go, and loading/empty states for data. |
| `delight` | Add moments of joy, personality, and surprise through success states, empty states, loading moments, hover details, and celebratory polish once the fundamentals already work. Use when the user wants delight, charm, personality, or memorable micro-interactions—not when the main need is baseline cl... |
| `depth` | Add or refine depth through elevation systems, raised and inset surfaces, layered overlap, and meaningful shadow behavior so interfaces feel structured instead of flat. Use when the user mentions depth, elevation, shadows, layering, flat cards, pressed states, drag feedback, or inset controls. |
| `design-explorer` | Visual design exploration and design system creation skill. Use when the user wants to explore multiple design directions, generate design variants, build a design system from scratch, convert a mockup to production HTML, compare design options, or needs a design partner to challenge aesthetic ch... |
| `design-process` | Briefing, concept development, wireframing, prototyping, visual design, review, and handoff -- the structured path from requirements to finished design. |
| `design-standards` | Apply production-grade design standards when building or reviewing pages, components, or UI. Use this skill whenever the user asks to build a page, design a component, lay out a section, review the UI, fix the layout, or check design quality. Triggers on build a page, create a component, design a... |
| `design-system` | Build or audit a design system including component library, design tokens, naming conventions, contribution model, and documentation. Use this skill whenever the user wants to build a design system, audit an existing system, define design tokens at the system level, structure a component library,... |
| `design-tokens-theming` | Use when setting up a design system — color, typography, and spacing scales as CSS variables, the shadcn/ui theme, and dark mode. Covers semantic tokens, Tailwind wiring, and consistent theming across components. |
| `design-trends` | Current award-winning design patterns and emerging techniques in web design (Q1/Q2 2026). Covers motion, typography, color, layout innovations, and interaction patterns derived from Awwwards, CSSDA, Godly, and SiteInspire analysis. Structured for periodic updates. |
| `distill` | Simplify cluttered UI by removing unnecessary elements, choices, features, and structural complexity. Use when the problem is too many controls, options, features, or competing elements—not when the structure is sound and the real issue is only visual intensity or lack of personality. |
| `effective-ui-design` | Профессиональные гайдлайны UI: OKLCH-палитры, 8pt сетка, типографика clamp(), доступность WCAG. |
| `empty-and-loading-states` | Use when handling the non-happy UI states — skeleton loaders, empty states with a clear CTA, error states with retry, and optimistic updates. Covers the states agents forget that make an app feel broken or polished. |
| `empty-state` | Design focused empty states for zero-data, no-results, permission, and error situations with clear value framing, strong CTAs, and less dead chrome. Use when the user mentions blank pages, zero-data screens, no results, permission states, or dead controls—not broader onboarding strategy. |
| `extract` | Extract reusable components, product patterns, and design tokens into a clearer design system with shared APIs, documented defaults, and better reuse. Use when the user wants to refactor repeated UI, consolidate buttons/cards/forms/sections, build a component library, or turn one-off values into ... |
| `forms` | Design, structure, or improve form interfaces for clarity, completion rates, and user confidence. Use when the user asks to build a form, redesign a form flow, improve form conversion, add multi-step forms, fix form UX, or structure field layouts and validation. |
| `form-strategy` | Design forms that convert, validate well, resist spam, and integrate cleanly with downstream systems. Use this skill when designing or auditing any form (contact, signup, checkout, multi-step, embedded), planning validation logic, fighting spam, choosing form tooling, or improving form conversion... |
| `frontend-component-build` | Build production-ready frontend components with accessible markup, sensible props, defined states, and tested behavior. Use this skill whenever the user wants to build a component from scratch, refactor an existing one, design a component API, or implement a UI element with proper states and acce... |
| `frontend-design` | Create distinctive, production-grade frontend interfaces with strong hierarchy, thoughtful systems, and polished implementation that avoid generic AI aesthetics. Use when the user wants to build or redesign web pages, flows, components, or full app surfaces, or when another better-web-ui skill ne... |
| `harden` | Improve interface resilience through better error handling, i18n support, text overflow handling, and edge case management, making interfaces robust and production-ready. Use when the user asks to harden, make production-ready, handle edge cases, add error states, or fix overflow and i18n issues. |
| `hierarchy` | Clarify priority and emphasis by fixing unclear primary actions, competing visual weight, loud section titles, and weak label/value treatment. Use when the user mentions hierarchy, prioritization, too much competition, grayscale confusion, loud headings, or unclear primary actions. |
| `imagery` | Improve how interfaces use photos, screenshots, icons, illustrations, and user-uploaded media so visuals support clarity instead of undermining it. Use when the user mentions images, screenshots, background photos, hero images, icon sizing, user-uploaded media, crops, overlays, or image readability. |
| `images-media` | Image strategy, visual concepts, technical optimization, SVG, icons, lazy loading, and the strategic use of images and media in web design. |
| `information-architecture` | Design the structure of a website or product including sitemap, navigation, URL structure, content types, taxonomy, and labeling. Use this skill whenever the user asks to plan a sitemap, design navigation, structure URLs, define content types, build taxonomies, design site search, or organize con... |
| `internationalization` | Plan and run a multi-language or multi-region site. Use this skill when adding new locales, choosing URL structure for languages (subfolders vs subdomains vs ccTLDs), implementing hreflang, planning translation workflow, handling currency and date formats, designing for RTL languages, or auditing... |
| `localize` | Plan, implement, or improve an internationalization and localization strategy for UI content, formatting, and regional adaptation. Use when the user asks to add i18n, localize, translate, support multiple languages, handle regional formats, manage locale switching, or build a multilingual product. |
| `modals-and-dialogs` | Use when building modals, sheets, drawers, or confirmation flows — choosing Dialog vs Sheet vs Drawer vs AlertDialog, focus trapping, destructive-action confirms, and forms inside overlays without losing data. |
| `navigation-design` | Menu patterns, breadcrumbs, search functionality, information architecture, and user flow. Navigation as the backbone of every website with accessible implementation. |
| `navigation-patterns` | Use when building app navigation — sidebar nav with active states, a command palette (cmdk), tabs, and breadcrumbs. Covers accessible markup, active-route detection, and keyboard-first navigation. |
| `normalize` | Audit and realign UI to match design system standards, spacing, tokens, and patterns. Use when the user mentions consistency, design drift, mismatched styles, tokens, or wants to bring a feature back in line with the system. |
| `notifications-and-toasts` | Use when giving users feedback — toasts (sonner), inline alerts, and a notification center. Covers when to use which, accessible announcements, promise/loading toasts, and not overusing notifications. |
| `onboard` | Design onboarding and activation flows that help users reach value quickly. Use when the user mentions onboarding, getting started, first-time users, activation, aha moments, or new user flows—not when the work is only the empty-state surface itself. |
| `onboarding-flows` | Use when building onboarding — multi-step wizards, setup checklists, progressive disclosure, and first-run empty states. Covers step state, progress indication, skip/resume, and getting users to first value fast. |
| `optimize` | Diagnose and fix UI performance across loading speed, rendering, animations, images, and bundle size. Use when the user mentions slow, laggy, janky, performance, bundle size, load time, or wants a faster, smoother experience. |
| `polish` | Perform a final quality pass fixing alignment, spacing, consistency, and micro-detail issues before shipping. Use when the work is functionally complete and needs finishing touches—not when the hierarchy, structure, tone, or technical foundation still need major changes. |
| `quieter` | Reduce visual intensity, saturation, and noise while preserving hierarchy and character. Use when the structure is basically sound but the design feels too loud, bold, garish, aggressive, or overstimulating—not when the real problem is structural clutter, too many features, or not enough personal... |
| `redesign` | Редизайн кода/модуля по явному запросу пользователя. |
| `responsive-design` | Mobile-first strategy, breakpoints, fluid layouts, content choreography, and cross-device optimization with CSS Grid, Flexbox, and modern responsive techniques. |
| `responsive-layout` | Use when building the app shell or any responsive screen — sidebar + topbar layouts, Tailwind breakpoints, container queries, and fluid grids that hold up from mobile to ultrawide. |
| `search` | Design or improve search experiences, result presentation, and filtering interfaces. Use when the user asks to add search, redesign search results, improve findability, build autocomplete, add filters, or fix zero-results dead ends. |
| `security-ux` | Design security-conscious interfaces that protect users without frustrating them. Use when the user asks about MFA, password UX, breach notifications, trust indicators, secure forms, account recovery, or making security feel safe rather than scary. |
| `semantic-html-css` | Semantic HTML, landmarks, focus, and modern CSS - fast accessible UI that pairs with WCAG audits |
| `settings-pages` | Use when building settings — account, profile, team/members, workspace, and a danger zone. Covers sectioned layouts, sidebar/tab navigation, autosave vs explicit save, and safe destructive actions. |
| `setup` | Gather and persist project design context such as audience, brand personality, UX goals, and implementation defaults for future better-web-ui work. Use when starting a project, defining UI direction, or establishing reusable design guidance before other better-web-ui skills. |
| `showcase` | Create standout, technically ambitious interfaces that feel extraordinary through cinematic transitions, advanced motion, heavy rendering, or other high-ambition implementation work. Use when the user wants to wow, impress, go all-out, or push a feature beyond conventional UI polish—not when simp... |
| `skillcodex-browser-ui` | Full SkillCodex doc browser - skills.sh-style UI, STRICT UI only, design-guidelines |
| `system-feedback` | Проверить, понятно ли пользователю, что произошло после действия, и предусмотрены ли состояния загрузки, пустоты и ошибки. Использовать при реализации сохранения, копирования, удаления, отправки, загрузки и синхронизации; при создании экранов с асинхронными данными; и при разборе интерфейса, кото... |
| `theme-factory` | Generate and apply complete design themes — color palettes, typography pairings, and spacing systems — to any artifact. Use when the user wants to style a presentation, document, landing page, dashboard, or UI component with a cohesive visual theme, pick from pre-built themes, or generate a custo... |
| `typeset` | Improve UI typography by fixing font choices, type scale, hierarchy, weight, and readability so text feels intentional. Use when the user mentions fonts, typography, type scale, readability, text hierarchy, or sizing that feels off. |
| `ui-design` | Layouts, components, visual hierarchy, grid systems, and design systems for professional web interfaces. Defines rules for grid systems, whitespace, styleguides, design tokens, and UI patterns. |
| `ui-patterns` | Proven, real-world UI interaction patterns from shipped products. Covers hero sections, navigation, cards, pricing, testimonials, CTAs, forms, and footer patterns derived from SiteInspire, CSSDA, Godly, Lapa Ninja, and CSS Winner analysis. |
| `usability` | Heuristic evaluation, conversion optimization, form design, error handling, and usability as a measurable quality criterion per ISO 9241 and Nielsen heuristics. |
| `vertical-site-conventions` | Compose pages and sites that read as their vertical: ecommerce-catalog storefronts that look like storefronts, hospitality-food sites that look like restaurants, b2b-manufacturer sites that look industrial. Use this skill whenever the user wants to build a site that looks like the vertical it ser... |
| `visual-direction` | Current visual direction for web projects covering color palettes, font pairings, layout compositions, and imagery (Q1/Q2 2026). Derived from Dribbble trending, Behance top projects, Land-book curation, and Godly featured sites. Structured for periodic updates. |
| `web-design-engineer` | Создание высококачественных визуальных web-артефактов на HTML/CSS/JS/React: страницы, прототипы, дашборды, слайды. |
| `webdesign-review` | Meta-skill for comprehensive web design reviews. Orchestrates all 20 domain skills for systematic analysis of websites, designs, and prototypes against enterprise design standards. |
| `web-typography` | Font selection, font pairing, typographic scales, line height, line length, and CSS implementation for web typography. Defines rules for readable, performant, and hierarchically structured text design. |

### React / Next.js / TypeScript

| Скил | Назначение |
|------|------------|
| `api-handbook` | REST and Next.js Route Handler design - status codes, errors, idempotency, and versioning without bloat |
| `auth-handbook` | Sessions, cookies, OAuth callbacks, and RBAC for Next.js App Router - httpOnly, CSRF-same-site boundaries, complements env-config-agent |
| `auth-screens` | Use when building authentication UI — login, signup, forgot/reset password, email verification, and OAuth buttons. Covers layout, validation, security-conscious UX (no user enumeration), and loading/error states. |
| `billing-and-pricing` | Use when building pricing tables, plan cards, paywalls, and upgrade prompts. Covers monthly/annual toggles, highlighting the recommended plan, usage limits, feature gating UI, and clear upgrade CTAs. |
| `client-data-fetching` | TanStack Query v5 with Next.js App Router - query keys, hydration, staleTime, and server prefetch without double fetch |
| `code-assistant` | React and Next.js coding - small diffs, pnpm, TypeScript TSX, stable versions |
| `component-architecture` | Use when structuring React components in a SaaS app — composing shadcn/ui, cva variants, compound components, controlled vs uncontrolled state, and knowing when to abstract versus inline. |
| `component-patterns` | Modern UI component selection, composition, and theming patterns for web applications. Covers compound components, design tokens, variant systems, responsive patterns, and form architecture derived from 21st.dev SDK, Godly featured products, and current best practices. |
| `container-local-dev` | Docker multi-stage builds and Compose for Next.js on Node LTS with pnpm plus Postgres Redis sidecars and dockerignore hygiene |
| `database-schema-agent` | Design or audit Prisma schemas for Next.js - relations, indexes, naming, migration notes |
| `data-layer-handbook` | Prisma vs Drizzle and SQL in Next.js - when to choose relations migrations serverless drivers and pairing with database-schema-agent |
| `data-tables` | Use when building data tables — sorting, filtering, pagination, row selection and bulk actions with TanStack Table + shadcn/ui, plus the loading, empty, and error states tables almost always forget. |
| `edge-runtime-handbook` | Next.js Edge Runtime limits - what runs where and how to split Node-only code |
| `env-config-agent` | Manage Next.js environment variables safely - .env.example, NEXT_PUBLIC_ rules, typed env, secret leak checks |
| `error-loading-not-found` | Next.js App Router error.tsx, not-found, loading, and global-error - recovery UI, logging, and boundaries users actually see |
| `forms-and-validation` | Use when building forms with react-hook-form + zod and shadcn/ui Form — schema validation, inline errors, accessible fields, async submit with loading and server errors, and avoiding uncontrolled-input bugs. |
| `frontend-skills` | Use when writing, reviewing, or refactoring React 19, Next.js 14+ / 16 App Router, or Tailwind CSS code. Triggers on tasks involving Server/Client Components, data fetching, cache directives, route handlers, image/font optimization, component API design, or Tailwind class composition. |
| `frontend-web` | TanStack Router + React frontend patterns, ConnectRPC gRPC-Web client, Zustand stores, Tailwind v4, i18n, and AppearancePanel theming for the Anachak platform. |
| `github-actions-ci` | GitHub Actions for Next.js and TypeScript - lint test build cache and PR checks |
| `i18n-handbook` | Internationalization for Next.js App Router - locale routing, message files, and RTL layout checks |
| `markdown-pipeline` | Markdown and MDX pipelines with remark rehype - security performance and GFM parity |
| `monorepo-tooling` | pnpm workspaces and Turborepo with Next.js apps - boundaries caching and shared packages |
| `next-server-patterns` | Next.js App Router server components, streaming, caching, and client boundaries without guesswork |
| `observability-handbook` | Structured logs correlation IDs and error reporting for Next.js App Router - PII boundaries and tracing hooks without vendor lock-in |
| `payments-handbook` | Checkout PCI scope card data boundaries - PSP tokens only pair with webhook-receivers never store or log PAN |
| `performance-audit` | Audit Next.js performance - bundle size, images, RSC boundaries, Core Web Vitals checklist |
| `react-email-templates` | Transactional email with React components - layout tables text version and test sends |
| `realtime-handbook` | SSE and WebSockets in Next.js Route Handlers - auth connection limits and when to pick each transport |
| `secure-dependencies` | Lockfiles, audits, install-script risk, and CI dependency review for Node and pnpm - reduce supply-chain surprises |
| `security-headers` | HTTP security headers and CSP for Next.js - safe defaults, nonces, and report-only rollout |
| `server-caching-handbook` | Next.js revalidateTag stampedes unstable_cache external Redis and fetch cache hierarchy for production traffic |
| `storybook-handbook` | Storybook 8 for React TypeScript - CSF3 stories a11y addon and docs aligned with design-guidelines |
| `testing-agent` | Write and improve React/Next.js tests with Vitest, Testing Library, and Playwright E2E |
| `typescript-react-nextjs-patterns` | Продвинутые TypeScript-паттерны для React и Next.js: сужение типов, Props, generics, формы, SSR/CSR. |
| `typescript-refactor` | Refactor JavaScript to strict TypeScript or audit types - incremental .js to .ts with explicit return types |
| `web-design-guidelines` | Web design for SkillCodex doc UIs - React + TypeScript + Tailwind; build or audit per design-guidelines. Prefer div + CSS motion; use framer-motion only in client components. |
| `webhook-receivers` | Secure Next.js Route Handlers for webhooks - signature verify idempotency and replay protection |

### Backend, базы данных и данные

| Скил | Назначение |
|------|------------|
| `api-design` | Design production-grade APIs — REST, GraphQL, gRPC, and WebSocket — with a focus on consistency, versioning, error standards, and developer experience. Use when the user asks to design an API, define endpoints, choose between REST and GraphQL, structure request/response schemas, handle API versio... |
| `backend-dev` | Production-grade backend development guidance — language and framework agnostic. Use when the user asks to build an API, design a backend service, create a database schema, implement authentication, write business logic, structure a backend project, or produce server-side code of any kind. |
| `database-architect` | Expert database architecture and design guidance — schema/data modeling, ER diagrams, indexing, query optimization, partitioning, replication and high availability, transactions and locking, connection pooling, migrations, and multi-tenancy patterns across PostgreSQL, MySQL, MongoDB, and Redis. U... |
| `data-engineer` | Design and build production-grade data pipelines, ETL/ELT workflows, data warehouses, and streaming architectures. Use when the user asks about data pipelines, ETL/ELT, dbt models, Airflow DAGs, Kafka, data warehouses (Snowflake, BigQuery, Redshift), data quality, schema design for analytics, eve... |
| `data-viz` | Design or improve data visualizations, charts, and data presentation interfaces. Use when the user asks to add charts, build dashboards, visualize data, choose chart types, make data accessible, or present metrics and analytics. |
| `data-warehouse-experimentation` | Running experiments out of the data warehouse instead of via dedicated experiment platforms. SQL-based assignment, exposure logging discipline, metric definitions in dbt models, statistical analysis in SQL or Python, variance reduction with CUPED, sequential testing, and the operational tradeoffs... |
| `elasticsearch` | Elasticsearch 集群管理 |
| `mongodb` | MongoDB 数据库管理 |
| `mysql` | MySQL 数据库管理与运维 |
| `postgresql` | PostgreSQL 数据库管理 |
| `python-productive` | Modern Python with uv, Pydantic v2, strict typing, and fast paths - projects, tooling, optional native extensions |
| `redis` | Redis 数据库管理 |
| `sql-optimization` | SQL 优化与调优 |
| `system-design` | Expert system design guidance for architects and senior engineers. Use when the user asks about microservices, monolith design, event-driven architecture, scalability, reliability, caching strategies, queue design, load balancers, or API gateways. |
| `uv-audit` | Аудит безопасности Python-зависимостей через uv (uv-audit / pip-audit). |
| `write-nextflow-local-modules` | Создание и обновление локальных Nextflow-модулей (modules/local/). |

### DevOps, Linux и инфраструктура

| Скил | Назначение |
|------|------------|
| `ansible` | Ansible 自动化运维 |
| `apache` | Apache HTTP Server 配置 |
| `backup-and-disaster-recovery` | Plan and run backups, set recovery objectives, and run disaster recovery drills. Use this skill when defining RPO/RTO targets, designing backup architecture, deciding what to back up and how often, planning for full-region or platform outages, or running a restoration drill. Triggers on backup, r... |
| `backup-strategy` | 备份策略设计 |
| `benchmarking` | 性能基准测试 |
| `ci-cd` | CI/CD 流水线配置 |
| `cloud-backup` | 云备份方案 |
| `compose` | Docker Compose 编排 |
| `configmap-secret` | Kubernetes ConfigMap 与 Secret |
| `container-ops` | Docker 容器操作与管理 |
| `cost-optimization` | Audit and reduce infrastructure and tooling costs without sacrificing reliability or velocity. Use this skill when reviewing monthly cloud or SaaS spend, finding unused resources, rightsizing infrastructure, negotiating vendor contracts, deciding what to consolidate, or planning for budget cuts. ... |
| `create-dockerfile` | Create optimized, secure, production-ready Dockerfiles based on user requirements and application context. |
| `create-terraform-helm-upgrade-plan` | Create a detailed upgrade plan for a Helm release managed by Terraform, comparing the current and desired chart versions including breaking changes and required code changes. |
| `cron` | 定时任务管理 |
| `deployment` | Kubernetes Deployment 管理 |
| `devops-platform` | Production-grade DevOps and platform engineering guidance — Docker, Kubernetes, CI/CD pipelines, Terraform/IaC, GitOps, deployment strategies (rolling/blue-green/canary), monitoring and alerting, and cloud patterns across AWS/Azure/GCP. Use this whenever the user asks about containerizing an app,... |
| `diagnose-crashloop` | Triage pods restarting repeatedly and identify the most likely root cause. |
| `diagnose-imagepullbackoff` | Determine why a pod cannot pull its container image and resolve safely. |
| `disaster-recovery` | 灾难恢复 |
| `dns` | DNS 配置与排查 |
| `dockerfile` | Dockerfile 编写最佳实践 |
| `domain-strategy` | Plan, manage, and optimize a domain portfolio. Use this skill for DNS architecture decisions, redirect strategies, registrar choice, parking unused domains, multi-site setups, and domain consolidation or split planning. Triggers on DNS, domain, registrar, redirect, parking, subdomain, apex, www v... |
| `feature-flagging` | Operational discipline for feature flags as production infrastructure. Flag types, naming, targeting rules, rollout strategy, lifecycle, governance, stale flag management, and the technical debt patterns that bite teams who weren't deliberate about it. |
| `file-operations` | Linux file and directory operations |
| `firewall` | 防火墙配置 |
| `git-advanced` | Git 高级操作 |
| `hardening` | 系统加固 |
| `helm` | Helm 包管理 |
| `image-management` | Docker 镜像管理 |
| `incident-response` | Manage active production incidents through detection, triage, mitigation, communication, and resolution with structured roles and decision-making. Use this skill whenever the user has an active incident, a production issue, a service outage, a security incident, or needs to plan incident response... |
| `investigate-drift` | Determine why actual infrastructure differs from Terraform state and choose a safe reconciliation path. |
| `kubectl-basics` | kubectl 基础操作与常用命令 |
| `land-and-deploy` | Merge, deploy, and verify production skill. Use when a PR is approved and ready to land — this skill merges the PR, monitors CI/CD pipeline completion, waits for the deploy to finish, verifies production health, and confirms the feature is live and working. The final step from "approved" to "veri... |
| `load-balancer` | 负载均衡配置 |
| `log-analysis` | 日志分析与处理 |
| `maintenance-check-aws-eks` | Check everything that can be upgraded for maintenance across an AWS EKS Kubernetes cluster and output a decision file with Jira-formatted tickets for any required upgrades. |
| `maintenance-create-ticket-on-jira` | Create or update a Jira ticket for a workload maintenance upgrade, based on maintenance upgrade check files. |
| `monitoring` | 监控与告警 |
| `monitoring-and-alerting` | Design and run a monitoring system for a website or web app. Use this skill when setting up uptime checks, defining SLOs, configuring error tracking, choosing what to alert on, designing on-call rotations, or fixing alert fatigue. Triggers on monitoring, alerts, uptime, SLO, SLA, error rate, on-c... |
| `networking` | Docker 容器网络 |
| `network-tools` | Linux network tools and diagnostics |
| `nginx` | Nginx configuration and optimization |
| `pod-management` | Kubernetes Pod 管理与调试 |
| `process-management` | Linux process management and control |
| `profiling` | 性能分析 |
| `prometheus-cli` | Query Prometheus metrics using the HTTP API via curl. Use for instant queries, range queries, metadata lookups, and alert/rule inspection. |
| `proxy` | 代理服务器配置 |
| `recover-state-lock` | Safely assess and recover from a stuck Terraform state lock. |
| `rsync` | rsync 文件同步与备份 |
| `safety-guardrails` | AI safety guardrails skill — warn before destructive commands, lock file edits to a specific directory, and prevent accidental damage to production systems. Use when working in a production environment, debugging a live system, doing risky migrations, or whenever the user says "be careful", "don'... |
| `security-baseline` | Establish a security baseline for a website or web app. Use this skill when configuring HTTPS and TLS, setting security headers, planning secrets management, evaluating CSP policies, doing a basic security audit, or hardening a site before launch. Triggers on security headers, HTTPS, TLS, CSP, co... |
| `security-engineer` | Expert application and infrastructure security guidance. Use when the user asks about OWASP Top 10, JWT review, RBAC, OAuth, threat modeling, SSRF, CSRF, XSS, or secret management. |
| `service-ingress` | Kubernetes Service 与 Ingress |
| `sev1-first-15-minutes` | Execute the initial incident workflow to stabilize, communicate, and delegate. |
| `shell-scripting` | Bash Shell 脚本编写 |
| `skills` | Роутер и индекс библиотеки Linux/DevOps скилов: загрузить первым, чтобы найти нужный специализированный скил. |
| `snapshot` | 快照管理 |
| `sre-canary` | Post-deploy monitoring and canary verification skill. Use when the user has just deployed and wants to verify production health, watch for console errors or performance regressions, run a post-deploy monitoring loop, or validate that a canary deployment is stable before rolling out to 100% traffic. |
| `ssh` | SSH 管理与安全 |
| `ssl-tls` | SSL/TLS 证书 |
| `sysadmin-qa` | Linux SysAdmin 核心知識問答 — 284 題精煉版，涵蓋 Junior 到 Guru 級別 |
| `system-admin` | Linux system administration and monitoring |
| `systemd` | Systemd 服务管理 |
| `tar-compression` | 归档与压缩 |
| `tcp-ip` | TCP/IP 网络诊断与排查 |
| `terminal-fish` | Fish shell configuration, aliases, gRPC debugging, PostgreSQL CLI helpers, and dev workflow shortcuts for the Anachak platform. |
| `terraform` | Terraform 基础设施即代码 |
| `traffic-analysis` | 流量分析与抓包 |
| `triage-access-denied` | Identify why an AWS API call is denied and what policy element blocks it. |
| `triage-app-outofsync` | Identify why an Argo CD application is OutOfSync and resolve safely. |
| `triage-cost-spike` | Identify the primary drivers of a sudden cloud cost increase and implement safe mitigations. |
| `triage-eks-node-notready` | Diagnose EKS worker nodes in NotReady and determine safe remediation. |
| `triage-error-budget-burn` | Investigate rapid SLO burn and identify whether the driver is errors, latency, or availability. |
| `triage-latency-regression` | Identify what changed and where latency increased, using logs/metrics/traces. |
| `triage-node-pressure` | Diagnose node-level memory/disk/pid pressure and determine safe mitigations. |
| `triage-pending-pods` | Diagnose pods stuck in Pending and identify scheduling constraints. |
| `triage-quota-exceeded` | Diagnose GCP quota errors and identify the quota, scope, and fastest safe mitigation. |
| `triage-service-dns` | Diagnose in-cluster DNS resolution failures and isolate root causes. |
| `triage-suspected-secret-exposure` | Contain and respond to a suspected credential/secret exposure without increasing blast radius. |
| `troubleshooting` | 性能问题排查 |
| `tuning` | 系统调优 |
| `user-permissions` | Linux user and permission management |
| `vpn` | VPN 配置与管理 |
| `win11-admin` | Windows 11 system administration and hardening. PROACTIVELY activate for: (1) Registry tweaking and optimization, (2) Windows services management and cleanup, (3) Group Policy (GPO) configuration, (4) Debloating and telemetry control, (5) System optimization and performance tuning, (6) CIS/STIG s... |
| `windows-system` | Use when managing, troubleshooting, or inspecting Windows systems — processes, services, disk, network, registry, users, event logs, updates, or system configuration. Covers PowerShell-native commands for system administration. |

### Cloud CLI

| Скил | Назначение |
|------|------------|
| `aliyun-cli` | 阿里云 CLI 操作 |
| `aws-cli` | AWS CLI 操作 |
| `azure-cli` | Azure CLI 操作 |
| `gcloud` | Google Cloud CLI 操作 |
| `github-cli` | Perform GitHub operations on GitHub using the gh CLI. Use for issues, pull requests, pipelines, repositories, and project management. ALSO use this skill when asked to review a GitHub PR — when a GitHub PR URL or PR ID is provided, use gh to fetch and review the diff instead of the code-review sk... |
| `gitlab-cli` | Perform GitLab operations using the glab CLI. Use for issues, merge requests, pipelines, repositories, and project management. ALSO use this skill when asked to review a GitLab MR or PR — when a GitLab MR URL or MR ID is provided, use glab to fetch and review the diff instead of the code-review s... |
| `grafana-cli` | Perform Grafana operations using the Grafana HTTP API via curl. Use for querying dashboards, datasources, alerts, and annotations. |
| `jenkins-cli` | Perform Jenkins operations using the jenkins-cli. |
| `jira-and-confluence-cli` | Perform Jira and Confluence operations using the Atlassian CLI (acli). Use for issues, sprints, boards, pages, spaces, and project management. |
| `slack-cli` | Perform Slack operations using the Slack CLI for app management and the Slack Web API (curl) for messaging, channel, and user operations. |

### Контент, маркетинг и SEO

| Скил | Назначение |
|------|------------|
| `ads-creative-development` | How to produce ad creative that converts at performance scale. Hook patterns, format selection, video pacing, variation systems, sequential testing methodology, fatigue detection, brand-voice alignment without conversion dilution, and platform-specific creative norms. Triggers on ad creative, ad ... |
| `ads-performance-analytics` | How to read paid media dashboards without fooling yourself. Attribution models, platform reporting quirks, multi-platform reconciliation, ROAS vs LTV horizon traps, statistical noise in performance metrics, incrementality testing, and the failure modes that produce expensive lessons. Triggers on ... |
| `calculator-design` | Designing interactive calculators (ROI calculators, pricing estimators, savings projections, mortgage calculators, custom assessments) that deliver real decision-support value while serving as lead magnets and qualified-traffic generators. Honest about vanity-calculator (no real value), lead-trap... |
| `chatbot-flow-design` | Designing conversational flows for website chatbots and AI agents. Intent recognition architecture, branching logic, fallback handling, escalation to human, conversation analytics. Honest about scripted-bot (rigid trees, fail edge cases), hallucinating-bot (LLM without structure, makes things up)... |
| `comparison-tool-design` | Designing side-by-side comparison tools (plan-compare, product-compare, alternative-compare) that help users decide rather than just listing features. Axis selection, default-comparison logic, recommendation discipline. Honest about feature-list-dump (every feature in a row, no decision support),... |
| `content-and-copy` | Write or edit website copy, blog content, and editorial pieces with attention to voice, structure, and goal. Use this skill whenever the user wants to write an article, draft website copy, edit existing content for clarity or voice, write a blog post, or produce general editorial content. Trigger... |
| `content-brief-authoring` | How to author a content brief that actually guides a writer (human or AI) to produce a piece that ranks, converts, or both. Per-piece editorial brief: target keyword and cluster, search intent, audience and JTBD, heading structure, entity coverage for AEO/GEO, internal linking strategy, success c... |
| `content-creator` | Social hooks, scripts, and captions - clear deliverables, no fluff |
| `content-distribution` | Content distribution as a discipline. Owned channels (newsletter, blog, social), earned channels (PR, syndication, mentions), paid channels (boosted posts, syndication networks), and the channel-fit decisions that distinguish strategic distribution from spam-everywhere. Audience-channel matching,... |
| `content-migration` | Move content between platforms, domains, or URL structures while preserving SEO equity, user bookmarks, and integrations. Use this skill when planning a CMS migration, replatforming, consolidating sites, changing URL structures, or merging content from multiple sources. Triggers on content migrat... |
| `content-refresh-system` | Systematic content refresh discipline. Quarterly audits, refresh prioritization (which pieces, when, how deep), refresh-vs-merge-vs-delete decisions, the lifecycle that distinguishes intentional refresh from set-and-forget decay. Builds on the refresh sections of pillar-content-architecture and e... |
| `content-repurposing` | Cross-format content adaptation. Turning one substantial piece into many derivative formats (blog series, email sequences, social posts, webinars, podcasts, video shorts) without losing the original's value or producing AI-slop variants. The discipline of adaptation per medium rather than mass-bl... |
| `content-strategy` | Develop a content strategy covering editorial positioning, content pillars, formats, calendar, governance, and topical authority planning. Use this skill whenever the user wants to plan a content program, define content pillars, build an editorial calendar, structure topic clusters, set up conten... |
| `cro-optimization` | Run conversion rate optimization through hypothesis-driven testing including audit, hypothesis generation, test design, statistical analysis, and rollout decisions. Use this skill whenever the user wants to optimize conversion, run A/B tests, audit a funnel, generate test hypotheses, design exper... |
| `editorial-qa` | Pre-publish QA framework for content. Brief adherence, voice consistency, fact accuracy, structure and clarity, AI-content audit, SEO and AEO compliance, internal linking and schema validation, QA at scale via sampling, the QA workflow, and the discipline that distinguishes catch-problems QA from... |
| `email-deliverability` | Make sure email actually reaches inboxes. Use this skill when setting up email authentication (SPF, DKIM, DMARC), diagnosing emails landing in spam, planning a domain reputation strategy, monitoring sender reputation, or hardening against email spoofing. Triggers on email deliverability, SPF, DKI... |
| `email-sequences` | Design and write email campaigns and sequences including onboarding flows, lifecycle campaigns, transactional emails, newsletters, broadcast sends, and launch and announcement emails. Use this skill whenever the user wants to write email copy, plan an email sequence, design an onboarding drip, or... |
| `evidence-based-reviews` | Produce honest product reviews and buying guides without fabricated first-hand experience, using disclosed evidence tiers: verified specs, owner-experience synthesis at scale, expert triangulation, and hands-on only when true. Use this skill whenever the user wants to write product reviews or buy... |
| `funnel-flow-architecture` | Architecting cross-tool conversion flows that match audience and stage. Landing page to lead magnet to nurture sequence to offer to advanced funnels. Honest about silo-funnels (every tool standalone), kitchen-sink-funnels (every audience squeezed through one path), and matched-funnels (architectu... |
| `interactive-product-tour` | Designing in-product tours, tooltips, and contextual help that teach product capabilities without becoming friction. Trigger logic, tour architecture, contextual placement, completion tracking. Honest about tooltip-spam (visual noise that users develop blindness to), one-and-done (help invisible ... |
| `landing-page-copy` | Write landing page copy with attention to the hero, value proposition, social proof, objection handling, and conversion-focused CTAs. Use this skill whenever the user wants to write a landing page, sales page, hero section, or any conversion-focused web copy. Triggers on landing page, sales page,... |
| `landing-pages` | Conversion-oriented page structure, CTA design, above-the-fold optimization, page types, and A/B testing for maximum conversion rates. |
| `lead-magnet-design` | Designing lead magnets that earn the email. The discipline of building gated content (ebooks, templates, checklists, swipe files, mini-courses, free tools) that delivers genuine standalone value while qualifying the lead and warming them for what comes next. Honest about thin-bait (overpromises, ... |
| `long-form-content-frameworks` | Patterns for individual long-form content pieces. Case studies, whitepapers, research reports, definitive guides, manifestos, ebooks, long-form tutorials. The structural disciplines that distinguish publication-quality long-form from bloggy-long padding or academic bloat. Different from pillar-co... |
| `media-asset-management` | Plan and run a media pipeline for images, video, and downloadable assets. Use this skill when designing image storage and delivery, choosing formats (WebP, AVIF), setting up responsive images, picking a video host, organizing a brand asset library, or auditing a slow image pipeline. Triggers on i... |
| `multi-step-form-design` | Designing forms with multiple steps, progress indicators, conditional logic, and save-and-resume mechanics. The discipline of breaking complex data collection into stages that respect cognitive load while maintaining completion intent. Honest about kitchen-sink-single-page (overwhelms before the ... |
| `onboarding-wizard-design` | Designing first-run product onboarding wizards that get users to the ah-ha moment without overwhelming them. Step architecture, progressive disclosure, escape hatches, completion incentives, drop-off measurement. Honest about tutorial-overload (dump everything upfront), skip-friendly-empty (skipp... |
| `paid-media-strategy` | A discipline for running paid media that does not light money on fire. Hypothesis writing for paid spend, channel selection, budget allocation, audience targeting, bid strategy, campaign types, what NOT to spend on, attribution reality, and the failure modes that produce expensive lessons. Trigge... |
| `pillar-content-architecture` | How to design a content hub that earns topical authority. Pillar topic selection, cluster planning, internal linking architecture, URL structure, pillar and cluster page anatomy, topical authority signals for SEO and AEO/GEO, and the maintenance discipline that distinguishes intentional hubs from... |
| `product-configurator-design` | Designing build-your-own product configurators (Tesla-style, custom-pricing, plan-builders) with constraint logic, real-time pricing, validation, and save-and-share mechanics. Honest about infinite-options (decision paralysis), canned-bundles-only (no real customization), and guided-configuration... |
| `programmatic-seo` | How to design and run a programmatic SEO program that produces durable traffic instead of penalty-bait. Data source identification, template design, schema patterns, quality control at scale, internal linking architecture, crawl budget management, AEO/GEO for programmatic pages, refresh disciplin... |
| `quiz-and-assessment-design` | Designing quizzes, personality assessments, and recommendation tools that segment users into actionable categories rather than generating clicks for clicks' sake. Question architecture, scoring algorithms, result categorization, recommendation mapping, lead capture integration. Honest about click... |
| `scheduler-and-booking-design` | Designing meeting schedulers and booking experiences that qualify leads, set up calls well, and convert at higher rates than a generic Calendly link. Availability logic, qualification gating, prep automation, follow-up sequencing. Honest about any-time-friction (no qualification, just a booking l... |
| `seo-aeo-geo` | Optimize content and site structure for AI-driven search experiences including AI overviews, large language model citations, generative answer engines, and AI assistants. Use this skill whenever the user wants to optimize for AI search, get cited by language models, appear in AI overviews, build ... |
| `seo-audit-orchestration` | Master orchestrator for a full SEO audit suite powered by the Ahrefs MCP. Use this skill when running a comprehensive SEO audit, scoping a quarterly health check, doing pre-acquisition SEO due diligence, or post-migration verification. Triggers on full SEO audit, comprehensive SEO review, SEO hea... |
| `seo-backlink-audit` | Audit a backlink profile using Ahrefs MCP data: profile health, anchor text distribution, toxic link identification, lost link reclamation, and gap analysis against competitors. Use this skill when reviewing backlink health, scoping a disavow project, recovering from a manual action, planning lin... |
| `seo-competitor` | Run a competitive SEO analysis comparing the user's site to chosen competitors across SERP overlap, content depth, backlink profiles, technical posture, and brand presence. Use this skill whenever the user wants to analyze competitors, find content gaps, identify backlink opportunities, understan... |
| `seo-content-audit` | Audit existing content across a site to decide what to keep, update, merge, redirect, or delete. Use this skill whenever the user wants to audit existing content, fix content decay, resolve keyword cannibalization, prune underperforming pages, prioritize content updates, or apply a keep/update/me... |
| `seo-content-gap-audit` | Audit content gaps and decay using Ahrefs MCP data: missing topics, thin coverage, outdated content, and decaying pages. Use this skill when planning a content roadmap, refreshing a stale catalog, building topical authority, or identifying which existing pages need update versus replacement. Trig... |
| `seo-expert` | SEO expert workflow for Next.js - Search Console, intent, metadata, JSON-LD, URL hygiene, CWV field data |
| `seo-keyword` | Run keyword research, classify by search intent, cluster into topical groups, and prioritize for content production. Use this skill whenever the user asks to do keyword research, find target keywords, identify ranking opportunities, classify search intent, build a topical map, or plan a content s... |
| `seo-keyword-gap-audit` | Find keywords competitors rank for that the target property does not, and prioritize them by opportunity. Uses Ahrefs MCP for keyword and competitor data. Use this skill when planning content investment, identifying quick wins, building a content calendar against a competitor set, or scoping a ma... |
| `seo-offpage` | Plan and execute off-page SEO including link building, digital PR, brand mentions, citation building, and external authority signals. Use this skill whenever the user wants to build backlinks, plan a digital PR campaign, list local citations, run guest post outreach, develop linkable assets, reco... |
| `seo-onpage` | Run a comprehensive on-page SEO audit or optimization pass covering title tags, meta descriptions, header structure, content quality, internal links, image optimization, URL hygiene, and on-page schema. Use this skill whenever the user asks to optimize a page, audit on-page SEO, fix titles or met... |
| `seo-rank-tracking` | Set up and run rank tracking using Ahrefs MCP: pick the right keywords to track, segment them by purpose, set baselines, and define alert thresholds. Use this skill when starting a new tracking project, baselining for a campaign, choosing what to monitor, or building a rank reporting cadence. Tri... |
| `seo-site-health-audit` | Triage technical SEO findings from Ahrefs Site Audit (and similar crawlers) by SEO impact, not just severity. Use this skill when reviewing crawl results, prioritizing technical fixes, scoping a technical SEO sprint, or after running any site-wide crawl. Triggers on site audit results, technical ... |
| `seo-technical` | Run a comprehensive technical SEO audit covering crawlability, indexability, rendering, site architecture, structured data, page experience, security, and internationalization. Use this skill whenever the user asks about technical SEO, crawl issues, indexing problems, sitemaps, robots.txt, canoni... |
| `seo-traffic-diagnosis` | Diagnose organic traffic changes (drops, stalls, or unexpected wins) using Ahrefs MCP plus Search Console data. Use this skill when traffic suddenly dropped, has been flat despite investment, after an algorithm update, after a migration or deploy, or when a competitor seems to be taking share. Tr... |
| `upgrade-flow-design` | Designing free-to-paid conversion flows for SaaS products. Trigger moments, paywall design, value demonstration, upsell vs downsell, win-back flows, churn prevention. Honest about paywall-everywhere (gates everything aggressively), free-forever-trap (no upgrade path surfaces), and value-triggered... |
| `website-audit` | Systematic website analysis, relaunch planning, SEO migration, content audit, and post-launch monitoring for data-driven relaunches. |

### Продукт, аналитика и бизнес

| Скил | Назначение |
|------|------------|
| `after-action-report` | Run a structured after-action review (postmortem, retrospective) on a launch, incident, or completed project to capture timeline, root cause analysis, contributing factors, and actionable lessons. Use this skill whenever the user wants to run a postmortem, retrospective, AAR, or after-action revi... |
| `analytics-strategy` | Design measurement frameworks including event taxonomy, KPI hierarchy, dashboard architecture, attribution models, and analytics implementation strategy. Use this skill whenever the user wants to plan analytics, design dashboards, build event taxonomies, define KPIs, set up tracking, or audit exi... |
| `ask-nodumb` | Помогает разобрать продуктовую или UX-задачу до проектирования решения: увидеть скрытое предположение, отделить образ продукта от модели и технологии, найти наиболее ценный вопрос или следующий шаг. Использовать, когда нужно придумать или обсудить фичу, экран, флоу, редизайн, концепт, принцип инт... |
| `autoplan` | Automated full review pipeline skill. Use when the user wants to run a complete plan review in one command, automatically chain CEO review then design review then engineering review then DX review, surface only the decisions that need human taste judgment, or compress the full planning workflow i... |
| `beta-program-management` | Running closed and open betas that produce real signal. Beta participant selection, structured feedback collection, beta-to-GA decision criteria, and the difference between soft-launch (no structure, no signal), kitchen-sink (everyone in, no actionable feedback), and structured beta (calibrated c... |
| `changelog-discipline` | Write and maintain a CHANGELOG that records every completed code change without becoming a commit dump. Use after any code change in a project that has a changelog, when setting one up, when preparing a release, or when the user asks why something was built this way. Keep mechanical entries brief... |
| `customer-journey` | Personas, touchpoint mapping, phase models, onboarding, customer retention, and data-driven journey analysis for user-centered web design. |
| `dependency-management` | Manage third-party libraries, runtimes, and SaaS dependencies. Use this skill when setting an update cadence, responding to security advisories, dealing with deprecated dependencies, evaluating new dependencies, auditing what's installed, or unblocking a dependency upgrade. Triggers on dependency... |
| `dependency-migrations` | Major version upgrades for React Next and toolchain - ordered steps rollback and test gates |
| `design-map` | Маппинг решений из дизайн-документа на фактическое состояние кодовой базы. |
| `devex-engineer` | Developer experience audit and improvement skill. Use when the user wants to review their API, CLI, SDK, or docs from a developer perspective, benchmark their onboarding flow against competitors, measure Time to Hello World (TTHW), trace friction points step-by-step, or improve the developer expe... |
| `discovery-research-synthesis` | Turning research artifacts into actionable PM insight. Customer interviews, user research notes, support ticket reviews, sales call transcripts, survey data, in-app feedback, all synthesized into the decisions they are meant to inform. The discipline of moving from raw discovery data to clear pro... |
| `edge-hunt` | Находит неочевидные корнеры задачи через пересечение состояний, данных, порядка действий, сбоев и параллельных изменений; превращает их в ожидаемое поведение и проверяемые сценарии. Использовать перед реализацией или ревью нетривиальной продуктовой, UX- или технической задачи; при изменении state... |
| `experimentation-analytics` | How to read experiment results without fooling yourself. Confidence intervals, p-values, multiple testing, sequential testing, CUPED, heterogeneous treatment effects, ratio metrics, network effects, dashboard reconciliation, and the interpretation failures that produce confidently wrong shipping ... |
| `experimentation-platform-orchestrator` | A platform decision framework for experimentation. When to use Statsig vs PostHog vs GrowthBook vs Optimizely vs Amplitude vs Eppo vs Kameleoon. How to migrate between them. How to coordinate when multi-platform is genuinely warranted. The decisions that compound for years and the ones you can de... |
| `experiment-design` | A discipline for designing experiments (A/B tests, multivariate, holdouts) so the results actually answer the question you asked. Hypothesis writing, sample size, duration, segment analysis, running discipline, matching a result to a pre-committed decision rule, and the common failure modes that ... |
| `feature-launch-playbook` | The operational playbook for launching a feature well. Positioning, internal alignment, customer comms, sales enablement, support readiness, rollout strategy, monitoring with pre-defined rollback triggers, post-launch measurement against spec hypotheses, and the discipline that distinguishes ship... |
| `forward-deployment-engineer` | Expert guidance for Forward Deployment Engineers (FDEs) — customer-facing technical specialists who deploy, integrate, configure, and operationalize complex software systems at customer sites. Use when the user asks about customer onboarding, on-site deployment, system integration, customer-facin... |
| `internal-comms` | Write clear, well-structured internal communications — incident reports, post-mortems, launch announcements, team updates, all-hands summaries, 3P updates (Progress/Plans/Problems), project status updates, leadership briefings, and FAQs. Use when the user needs to communicate something to their t... |
| `journey-mapping` | Build customer journey maps and service blueprints that visualize the end-to-end user experience including touchpoints, emotions, friction, and underlying systems. Use this skill whenever the user wants to map a customer journey, build a service blueprint, identify friction across an experience, ... |
| `jtbd-framing` | The Jobs-to-be-Done framework as applied product methodology. Job statements, struggling moments, hire and fire criteria, the difference between feature-thinking and job-thinking. Honest about where JTBD adds clarity (discovery, prioritization, positioning) and where it becomes performative ritua... |
| `launch-runbook` | Plan and execute a launch runbook covering pre-launch verification, go-live procedures, DNS cutover, post-launch monitoring, and rollback procedures. Use this skill whenever the user is preparing to launch a website or product, planning a DNS cutover, building a go-live checklist, or executing a ... |
| `nodumb` | Проверить способ решения до того, как цена ошибки выросла. Использовать: перед нетривиальной фичей или дорогой развилкой; когда запрос описывает готовое решение вместо проблемы; при постановке нетривиальной задачи или фиксации предполагаемой причины в трекере; при переносе внешнего факта, исследо... |
| `office-hours` | Pre-code ideation and startup validation skill. Use when the user wants to validate a product idea, stress-test assumptions before building, run a YC-style office hours session, brainstorm feature alternatives, or needs forcing questions that challenge their thinking before writing a line of code. |
| `okr-design` | OKR design as actually shipped, not as conference-talk theory. Outcome statements that drive decisions, key results that measure the right thing, scoring discipline, mid-quarter recalibration, and the difference between sandbagged OKRs (always 100%) and aspirational OKRs (always 30%) and stretch ... |
| `plan-ceo-review` | CEO and founder-lens strategic plan review. Use when the user wants to evaluate a feature or product idea from a business perspective, challenge scope, find the 10-star product inside the request, assess user value and competitive moat, or run a strategic review before engineering begins. |
| `plan-design-review` | Design plan review skill — rate and improve a UI design plan before implementation. Use when the user has a plan, wireframe, or design description for a UI feature and wants a senior designer to rate each design dimension 0-10, explain what a 10 looks like, detect AI slop, and edit the plan to re... |
| `plan-eng-review` | Engineering plan review skill — architecture, data flow, edge cases, and test plan before coding begins. Use when the user has a feature plan or design doc and needs an engineering manager to stress-test the technical approach, surface hidden assumptions, define the data model, identify failure m... |
| `pm-spec-writing` | Translate ideas, feature requests, or vague concepts into specific, actionable dev briefs. Use this skill whenever the user has an idea they want to build, a feature to spec out, a bug to file, a project to scope, or needs to convert a half-formed idea into a clear implementation brief. Triggers ... |
| `product-analytics-setup` | How to actually instrument product analytics correctly. Event taxonomy, property design, naming conventions, schema versioning, identity stitching, funnel design, retention cohorts, North Star metric selection, dashboard hygiene, instrumentation debt, and the failure modes that produce data nobod... |
| `product-engineer` | Expert product engineering guidance for senior engineers and tech leads. Use when the user asks about feature planning, MVP design, user flows, tradeoff analysis, or technical decisions that intersect with product strategy. |
| `release-engineer` | Structured release and ship workflow skill. Use when the user wants to ship code, create a PR, merge to main, deploy to production, run pre-ship checks, bootstrap a test framework, or needs a repeatable release process from final review to live deployment. |
| `retro-engineer` | Engineering retrospective skill for continuous improvement. Use when the user wants to run a weekly or sprint retro, review shipping velocity, analyse test health trends, identify growth opportunities, get per-person breakdowns, or run a cross-project retrospective across all their AI tools and r... |
| `roadmap-planning` | Build a multi-quarter roadmap from a backlog of ideas, requests, and ongoing initiatives. Use this skill when planning the next quarter, sequencing dependent work, balancing build vs improve vs maintain, or making the case for what NOT to do. Triggers on roadmap, quarterly planning, what should w... |
| `stakeholder-communication` | Communicate effectively with stakeholders across functions and seniority levels. Use this skill when writing status updates, preparing executive reviews, sharing technical decisions with non-technical audiences, managing up, communicating bad news, or designing the communication cadence for a pro... |
| `team-onboarding-playbook` | Design a structured onboarding experience that gets new team members productive in 30, 60, and 90 days. Use when a new hire is joining, when contractors or agency partners need to ramp up, when an existing team is restructuring and members are switching focus, or when current onboarding feels cha... |
| `usability-testing` | Plan and run usability tests on existing or prototype designs including test design, task scripts, moderation, observation, and findings synthesis. Use this skill whenever the user wants to test usability, run a moderated test, run an unmoderated test, validate a design, find usability issues, or... |
| `user-feedback-aggregation` | Collecting and synthesizing user feedback across channels (support tickets, NPS, in-app feedback, sales calls, social mentions, customer councils) into a continuous signal that informs product decisions. The triage discipline that distinguishes loudest-voice (whoever complains most wins) from ave... |
| `ux-design` | User research, interaction patterns, information architecture, and UX methods. Defines the five-plane model, user flows, UX laws, and validation methods for user-centered digital products. |
| `ux-research` | Plan and execute user research including research planning, recruiting, interview design, qualitative synthesis, and translating findings into product decisions. Use this skill whenever the user wants to plan user research, design interviews, recruit participants, conduct discovery, run formative... |
| `vendor-evaluation` | Evaluate, select, and contract with vendors and SaaS tools. Use this skill when comparing alternatives, running an RFP, scoring vendors against criteria, negotiating contracts, planning a switch, or assessing a vendor's risk. Triggers on vendor evaluation, RFP, vendor selection, build vs buy, Saa... |

### Бренд и креатив

| Скил | Назначение |
|------|------------|
| `art-direction` | Direct visual and creative work for campaigns, photography, illustration, video, and branded experiences. Use this skill whenever the user wants to brief a photographer, direct illustrators, plan a creative campaign, develop visual concepts, or evaluate creative work for fit. Triggers on art dire... |
| `brand-archetype-system` | Apply pre-composed aesthetic archetype defaults to jumpstart brand design work covering color, typography, layout, voice, and imagery direction. Use this skill whenever the user wants a starting point for brand visual and verbal direction, references a brand they want to design near (for example ... |
| `brand-discovery` | Run upstream brand discovery covering audience research, competitive landscape, category dynamics, problem space, and positioning territory exploration. Use this skill at the very start of a brand or website project when the user needs to understand who they're for, who they compete with, what th... |
| `brand-guidelines` | Apply brand voice, tone, colors, typography, and visual style consistently across any artifact. Use when the user wants to ensure a document, presentation, email, website, or any content matches their brand identity — including color palette, font choices, tone of voice, imagery guidelines, and d... |
| `brand-ideation` | Generate, evaluate, and narrow brand concepts during early ideation including positioning territories, naming candidates, mood directions, and narrative angles. Use this skill whenever the user is in the early phase of brand creation, exploring brand directions, brainstorming names, building mood... |
| `brand-identity` | Design or evaluate a brand visual identity system covering logo, color, typography, imagery direction, iconography, and motion principles. Use this skill whenever the user wants to design a logo, build a visual identity, define brand colors, choose brand typography, develop iconography, plan bran... |
| `branding-identity` | Brand strategy, visual identity, positioning, corporate design, portfolio presentation, and consistent brand management across all digital touchpoints. |
| `brand-style-guide` | Build or audit a comprehensive brand style guide that documents the full brand system including story, logo system, color, typography, imagery, voice, applications, and dos/don'ts. Use this skill whenever the user wants to create brand guidelines, document an existing brand, build a brand book, a... |
| `brand-voice` | Develop or document a complete brand voice and tone system covering voice attributes, tone shifts by context, vocabulary preferences, grammar rules, and copy examples. Use this skill whenever the user wants to define how a brand sounds, write a voice and tone document, audit existing copy for voi... |
| `creative-brief` | Create or refine a creative brief that bridges discovery and execution. Use this skill whenever the user is starting a new project, kicking off a website, beginning a brand build or redesign, briefing a designer or developer or AI agent, or trying to align a team before building. Triggers on crea... |
| `creative-brief-selector` | Produce a creative brief grounded in live reference sites and deliberately distinct from existing demos, for any new brand build. Composes with brand-archetype-system and creative-direction. Use this skill at the start of any brand or microsite build when the result needs to land in a specific ae... |
| `creative-direction` | Walk the user through four directional axes (tone register, aesthetic philosophy, audience relationship, sensory ambition) and produce a structured aesthetic brief that downstream content, copy, design, and art-direction skills consume as required input. The aesthetic depth layer, distinct from `... |
| `integration-orchestrator` | Generate a phased delivery orchestration plan for creative-direction-driven work: which skills run when, what locks at which gate, how handoffs occur, and how the cadence implements in the team's tools (Jira, Linear, Notion, Figma, GitHub) with AI agents via MCP and CLI. A temporal map of phases,... |
| `logo-design` | Generate logo variants for a brand, producing multiple production-grade marks across different architectures (wordmark, lockup, symbol-only, letterform-as-symbol, monogram) with rationale, application specs, and decision-ready presentation. Distinct from `brand-identity`, which produces the compl... |

### Документы и офис

| Скил | Назначение |
|------|------------|
| `ai-content-collaboration` | How humans and AI compose in content workflows. Where AI legitimately participates, where humans must own, hybrid workflow patterns, voice ownership preservation, the AI slop problem, disclosure and transparency, team calibration, and the ethics of intellectually honest AI-assisted content produc... |
| `ai-design-workflow` | AI tool integration into the design process, structured prompting for designers, creative AI usage with clear boundaries, and review workflows. |
| `doc-coauthoring` | Structured co-authoring workflow for PRDs, design docs, RFCs, decision docs, proposals, and any substantial written document. Use when the user wants to write a PRD, design doc, RFC, decision doc, one-pager, proposal, technical spec, or any structured document where quality and completeness matte... |
| `documentation-strategy` | Design and run a documentation system for a team or product. Use this skill when planning what to document, choosing a documentation tool, organizing existing docs, fixing stale documentation, designing a maintenance cadence, or scoping technical writing work. Triggers on documentation, docs, tec... |
| `pdf` | Read, extract, create, merge, split, and manipulate PDF files. Use whenever a .pdf file is involved — extracting text or tables from a PDF, creating a new PDF from content or data, merging multiple PDFs, splitting a PDF into pages, rotating pages, adding watermarks, filling PDF forms, encrypting ... |
| `pptx` | Create, edit, read, and design PowerPoint presentations (.pptx). Use whenever a .pptx file is involved — creating slide decks, pitch decks, or stakeholder presentations; reading or extracting content from an existing .pptx; editing or updating slides; building from a template. Trigger on "deck", ... |
| `skill-creation-walkthrough` | Step-by-step guide for creating your own Claude Skills, from deciding whether a skill is the right tool to writing the SKILL.md file, structuring reference material, and making it trigger reliably. Use when you want to package a workflow, framework, or repeated task into a reusable Skill, when an... |
| `skill-creator` | Author SkillCodex SKILL.md - outcomes, dual GitHub+npm format, safety metadata |
| `spec-author` | Turn vague intent into a precise, executable specification. Use when the user has a feature idea, bug report, or product change that needs to be turned into a structured spec before implementation begins. Also use when creating GitHub issues, writing technical requirements, or producing implement... |
| `technical-writer` | Write, structure, and maintain all forms of technical documentation — READMEs, API docs, runbooks, architecture decision records (ADRs), changelogs, onboarding guides, and user manuals. Use when the user asks to write or improve documentation, create a README, document an API, write a runbook, pr... |
| `write-comments` | Написание, добавление и ревью комментариев в коде. |
| `xlsx` | Create, read, edit, and analyse Excel spreadsheet files (.xlsx, .xlsm, .xltx, .csv, .tsv). Use whenever a spreadsheet file is the primary input or output — adding columns, computing formulas, formatting cells, building financial models, cleaning messy data, extracting tables, creating charts, or ... |

### Тестирование, QA и отладка

| Скил | Назначение |
|------|------------|
| `benchmark` | Performance benchmarking skill — baseline and compare page load times, Core Web Vitals, bundle sizes, and API response times. Use when the user wants to measure performance before and after a change, catch performance regressions in a PR, establish a performance baseline, or understand what is ma... |
| `code-review` | Analyze code changes between two local Git branches and perform a comprehensive code review. Use ONLY for local git branch comparisons. Do NOT use when a GitLab or GitHub MR/PR URL or MR ID is provided — use gitlab-cli or github-cli skill instead. |
| `code-reviewer` | Review code changes for bugs, security issues, performance problems, and style before shipping. Use when the user asks for a code review, wants to check a diff or PR, needs a second opinion on implementation, or says "review this", "check this code", or "is this safe to ship". |
| `code-review-web` | Review web application code for bugs, security issues, performance problems, and stack-specific anti-patterns. Use this skill whenever the user wants to review code, debug a production issue, investigate a build failure, audit security, or check a PR before merging. Triggers on code review, revie... |
| `commit-code` | Analyze code changes to prepare conventional commit message and commit to a new branch. |
| `commit-message` | Write clean Conventional Commits messages and pull request descriptions from staged changes or diffs. Use when the user asks to write a commit message, commit their changes, describe a PR, open a pull request, summarise a branch, or says "write a commit", "create a PR", "what should I call this c... |
| `debugger` | Systematic root-cause debugging skill. Use when the user has a bug, error, crash, unexpected behaviour, failing test, or performance issue and needs to find the root cause before fixing it. Iron law: no fixes without investigation first. |
| `lg-token-saver` | Save 87% token usage. Zero install. Input+Output+Context optimization. 8 rules. 6 months production verified. |
| `performance-optimization` | Diagnose and fix web performance issues including Core Web Vitals (LCP, INP, CLS), bundle size, asset optimization, render performance, and runtime efficiency. Use this skill whenever the user wants to improve page speed, fix Core Web Vitals, optimize assets, reduce bundle size, debug slow render... |
| `performance-optimizer` | Expert performance analysis and optimization guidance. Use when the user asks about frontend optimization, API latency, database optimization, memory leaks, CPU bottlenecks, or profiling. |
| `qa-engineer` | Live QA testing skill that finds bugs, fixes them with atomic commits, and re-verifies. Use when the user wants to test their app in a real browser, find bugs in a running application, run a QA pass before shipping, generate regression tests, or validate that a feature works end-to-end from the u... |
| `qa-testing` | Run QA testing on a page, feature, or full site at one of three depth tiers (smoke, standard, full). Use this skill whenever the user asks to QA a page or site, run a smoke test after a deploy, verify a page before launch, or run a regression sweep. Triggers on QA, QA sweep, smoke test, regressio... |
| `test` | Build or improve a UI testing strategy covering visual regression, interaction testing, and accessibility assertions. Use when the user asks to add tests, set up testing, fix flaky tests, improve test coverage, validate UI behavior, catch visual bugs, or establish confidence in shipping frontend ... |
| `test-writer` | Generate or extend comprehensive test suites — unit, integration, E2E, and contract tests — for any language or framework. Use when the user asks to write tests, add coverage, test a specific function or module, set up a test framework, generate test cases from code, or validate behaviour with au... |
| `token-optimizer` | Практическое руководство по снижению расхода токенов и стоимости API (промпт-кэширование, batch, выбор моделей). |
| `token-saver` | Reduce avoidable token and API cost through task-aware model selection, context hygiene, concise responses, and disciplined tool use. Apply as an advisory policy on every turn. Actual savings vary by agent, model, provider, cache behavior, and workload; measure results instead of assuming a fixed... |
| `token-saviour` | Выбор наиболее эффективного по токенам инструмента для задач кодинга вместо чтения целых файлов. |
| `webapp-testing` | Automated end-to-end web application testing using Playwright. Use when the user wants to write automated tests for a web app, test frontend functionality, verify UI behaviour programmatically, debug interactions in a browser, capture screenshots of a running app, check for console errors, or tes... |

### .agents/skills (отдельная библиотека)

| Скил | Назначение |
|------|------------|
| `academy-guide` | Подбор курсов и обучающих материалов из Claude Academy (academy.claude.com) по продуктам Claude. |
| `agent-browser` | Browser automation CLI for AI agents. Use when the user needs to interact with websites, including navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, or automating any browser task. Triggers include requests to "open a website", "fill out a f... |
| `algorithmic-art` | Creating algorithmic art using p5.js with seeded randomness and interactive parameter exploration. Use this when users request creating art using code, generative art, algorithmic art, flow fields, or particle systems. Create original algorithmic art rather than copying existing artists' work to ... |
| `ask-matt` | Ask which skill or flow fits your situation. A router over the skills in this repo. |
| `ask-nodumb` | Помогает разобрать продуктовую или UX-задачу до проектирования решения: увидеть скрытое предположение, отделить образ продукта от модели и технологии, найти наиболее ценный вопрос или следующий шаг. Использовать, когда нужно придумать или обсудить фичу, экран, флоу, редизайн, концепт, принцип инт... |
| `canvas-design` | Create beautiful visual art in .png and .pdf documents using design philosophy. You should use this skill when the user asks to create a poster, piece of art, design, or other static piece. Create original visual designs, never copying existing artists' work to avoid copyright violations. |
| `changelog-discipline` | Write and maintain a CHANGELOG that records every completed code change without becoming a commit dump. Use after any code change in a project that has a changelog, when setting one up, when preparing a release, or when the user asks why something was built this way. Keep mechanical entries brief... |
| `claude-api` | Справочник по Claude API / Anthropic SDK: модели, цены, параметры, стриминг, tool use, MCP, агенты. |
| `claude-handoff` | Hand the current conversation off to a fresh background agent that picks up the work immediately. |
| `codebase-design` | Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or AI-navigable, or when another skill needs the deep-module vocabulary. |
| `deploy-to-vercel` | Deploy applications and websites to Vercel. Use when the user requests deployment actions like "deploy my app", "deploy and give me the link", "push this live", or "create a preview deployment". |
| `diagnosing-bugs` | Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow. |
| `discernment-nudge` | После содержательного ответа добавляет 2-3 уточняющих вопроса, проверяющих факты и допущения. |
| `docx` | Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of co... |
| `domain-modeling` | Build and sharpen a project's domain model. Use when discussing codebase terminology, writing or editing a CONTEXT.md, or recording or editing an ADR. |
| `edge-hunt` | Находит неочевидные корнеры задачи через пересечение состояний, данных, порядка действий, сбоев и параллельных изменений; превращает их в ожидаемое поведение и проверяемые сценарии. Использовать перед реализацией или ревью нетривиальной продуктовой, UX- или технической задачи; при изменении state... |
| `expo-native-ui` | Framework (OSS). Build beautiful, native-feeling Expo screens. Covers Apple HIG styling, semantic colors, native controls, SF Symbols, media, animations, visual effects, gradients, storage, and responsive layout. For routing and navigation, use the expo-router skill. |
| `find-skills` | Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable ... |
| `git-guardrails-claude-code` | Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code. |
| `grilling` | Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases. |
| `grill-me` | A relentless interview to sharpen a plan or design. |
| `grill-with-docs` | A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. |
| `handoff` | Compact the current conversation into a handoff document for another agent to pick up. |
| `implement` | Implement a piece of work based on a spec or set of tickets. |
| `implement-spec` | Implement a specification in code. |
| `improve-codebase-architecture` | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| `loop-me` | Grill me about specs for the workflows I want to build, within this workspace. |
| `migrate-to-shoehorn` | Migrate test files from `as` type assertions to @total-typescript/shoehorn. Use when user mentions shoehorn, wants to replace `as` in tests, or needs partial test data. |
| `nodumb` | Проверить способ решения до того, как цена ошибки выросла. Использовать: перед нетривиальной фичей или дорогой развилкой; когда запрос описывает готовое решение вместо проблемы; при постановке нетривиальной задачи или фиксации предполагаемой причины в трекере; при переносе внешнего факта, исследо... |
| `prototype` | Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like. |
| `research` | Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent. |
| `resolving-merge-conflicts` | Use when you need to resolve an in-progress git merge/rebase conflict. |
| `retro` | Conduct a retrospective on a coding session. |
| `scaffold-exercises` | Create exercise directory structures with sections, problems, solutions, and explainers that pass linting. Use when user wants to scaffold exercises, create exercise stubs, or set up a new course section. |
| `setup-matt-pocock-skills` | Configure this repo for the engineering skills: set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills. |
| `setup-pre-commit` | Set up Husky pre-commit hooks with lint-staged (Prettier), type checking, and tests in the current repo. Use when user wants to add pre-commit hooks, set up Husky, configure lint-staged, or add commit-time formatting/typechecking/testing. |
| `setup-ts-deep-modules` | Wire dependency-cruiser into a TypeScript repo so each package is a deep module, with implementation hidden in subfolders and reachable only through its entry-point files. User-invoked. |
| `slack-gif-creator` | Knowledge and utilities for creating animated GIFs optimized for Slack. Provides constraints, validation tools, and animation concepts. Use when users request animated GIFs for Slack like "make me a GIF of X doing Y for Slack. |
| `system-feedback` | Проверить, понятно ли пользователю, что произошло после действия, и предусмотрены ли состояния загрузки, пустоты и ошибки. Использовать при реализации сохранения, копирования, удаления, отправки, загрузки и синхронизации; при создании экранов с асинхронными данными; и при разборе интерфейса, кото... |
| `tdd` | Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests. |
| `teach` | Teach the user a new skill or concept, within this workspace. |
| `to-questionnaire` | Turn a decision you can't fully answer into a questionnaire for someone else to fill in. |
| `to-spec` | Turn the current conversation into a spec and publish it to the project issue tracker: no interview, just synthesis of what you've already discussed. |
| `to-tickets` | Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker (edges as text in one file per ticket locally, or native blocking links on a real tracker). |
| `triage` | Move issues and external PRs through a state machine of triage roles, categorise, verify, grill if needed, and write agent-ready briefs. |
| `ui-ux-pro-max` | UI/UX design intelligence for web and mobile. Searchable local database with 50+ styles, 161 color palettes, 57 font pairings, 161 product types, 99 UX guidelines, and 25 chart types across 10 stacks (React, Next.js, Vue, Svelte, SwiftUI, React Native, Flutter, Tailwind, shadcn/ui, and HTML/CSS).... |
| `vercel-cli-with-tokens` | Deploy and manage projects on Vercel using token-based authentication. Use when working with Vercel CLI using access tokens rather than interactive login — e.g. "deploy to vercel", "set up vercel", "add environment variables to vercel". |
| `vercel-composition-patterns` | Паттерны React-композиции, которые масштабируются: compound components, render props, context. |
| `vercel-optimize` | Use for Vercel cost and performance optimization on deployed projects, especially Next.js, SvelteKit, Nuxt, and limited Astro apps. Collect Vercel metrics, usage, project config, and code scan results first; investigate only metric-backed candidates; produce ranked recommendations grounded in ver... |
| `vercel-react-best-practices` | React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns. Triggers on tasks involving React components, Next.js pages, data fetching, bundle optimizati... |
| `vercel-react-native-skills` | Лучшие практики React Native и Expo для производительных мобильных приложений. |
| `vercel-react-view-transitions` | Guide for implementing smooth, native-feeling animations using React's View Transition API (`<ViewTransition>` component, `addTransitionType`, and CSS view transition pseudo-elements). Use this skill whenever the user wants to add page transitions, animate route changes, create shared element ani... |
| `wait-what` | Stop. That last message did not land: re-pitch it. |
| `wayfinder` | Plan a huge chunk of work (more than one agent session can hold) as a shared map of decision tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear. |
| `web-artifacts-builder` | Suite of tools for creating elaborate, multi-component claude.ai HTML artifacts using modern frontend web technologies (React, Tailwind CSS, shadcn/ui). Use for complex artifacts requiring state management, routing, or shadcn/ui components - not for simple single-file HTML/JSX artifacts. |
| `wizard` | Generate an interactive bash wizard that walks a human through steps only they can perform. Use when provisioning infrastructure, setting up credentials or CI secrets, walking an unfamiliar third-party dashboard, or running a one-off migration or cutover. Don't invoke this for steps the agent can... |
| `writing-beats` | Writing, exploit; assemble raw material into a journey of beats, grounding each term before a beat leans on it. |
| `writing-for-agents` | Writing documents for agents. Use when creating or editing skills, or modifying AGENTS.md or CLAUDE.md. |
| `writing-fragments` | Writing, explore: mine raw fragments, no structure yet. |
| `writing-guidelines` | Review docs/prose for Writing Guidelines compliance. Use when asked to "review my docs", "check writing style", "audit prose", "review docs voice and tone", or "check this page against the writing handbook". |
| `writing-shape` | Writing, exploit: shape raw material into an article, paragraph by paragraph. |

## Прочее (без категории)

| Скил | Назначение |
|------|------------|
| `_template` | Шаблон для создания новых скилов. |

