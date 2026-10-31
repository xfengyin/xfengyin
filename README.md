# xfengyin

AI systems engineer. I build LLM agents and Go infrastructure, and port both onto ARM boards.
Every claim below links to code, so you can check it rather than trust it.

**Shipped:** [kongming-agent](https://github.com/xfengyin/kongming-agent) · [jciyuan-spider](https://github.com/xfengyin/jciyuan-spider) · [DAQ Insight](https://github.com/xfengyin/daq-insight) · [picoclaw overlay](https://github.com/xfengyin/picoclaw-opi-zero3-overlay) · [site](https://xfengyin.github.io)

## Three layers, each with something behind it

| Layer | What I write | Proof |
| --- | --- | --- |
| **AI agents** | LLM client, local retrieval, tool pre-check, MCP | [kongming-agent](https://github.com/xfengyin/kongming-agent) — Go, 4 direct deps, v0.7.0 |
| **Go systems** | Framework API, bounded concurrency, middleware | [jciyuan-spider](https://github.com/xfengyin/jciyuan-spider) — Go, 81 files, v0.5.0 |
| **Edge** | LED signalling, thermal watchdog, systemd on H618 | [picoclaw overlay](https://github.com/xfengyin/picoclaw-opi-zero3-overlay) — 2 hook lines, no fork |

## Selected work

### [kongming-agent](https://github.com/xfengyin/kongming-agent) — local-first LLM agent CLI

**Problem.** Arithmetic, a passage from local notes, a directory listing should not cost a model round-trip — and the CLI should work with no API key.
**Built.** `Ask` runs in a fixed order — tool pre-check, local retrieval, then the LLM. First-match tool registry ([registry.go:31](https://github.com/xfengyin/kongming-agent/blob/master/pkg/tools/registry.go#L31)); calculator over `govaluate` that never evaluates code ([calculator.go:6](https://github.com/xfengyin/kongming-agent/blob/master/pkg/tools/calculator.go#L6)); stdio MCP servers whose tools join that registry ([mcp.go:64](https://github.com/xfengyin/kongming-agent/blob/master/pkg/tools/mcp.go#L64)); Markdown knowledge ranked by term hits, no vector store ([knowledge.go:198](https://github.com/xfengyin/kongming-agent/blob/master/pkg/knowledge/knowledge.go#L198)); session save/load ([session.go:45](https://github.com/xfengyin/kongming-agent/blob/master/pkg/session/session.go#L45)).
**Trade-off.** Tools fire on a name rule, not function calling: the model does not choose tools yet. Deterministic and testable offline (`go test -race`, mock provider) instead of flexible. Boundaries are written up in the repo.

### [jciyuan-spider](https://github.com/xfengyin/jciyuan-spider) — Go crawler framework

**Problem.** Scrapers rot once concurrency, retries and rate limits get copy-pasted per site.
**Built.** One interface — `Name / Fetch / Parse / Extract` ([crawler.go:73](https://github.com/xfengyin/jciyuan-spider/blob/main/crawler/crawler.go#L73)) — run by an engine with a bounded worker pool and finite retries with back-off ([engine.go:142](https://github.com/xfengyin/jciyuan-spider/blob/main/crawler/engine.go#L142)); implementations register through an SPI keyed by config `crawler.type`. Cross-cutting behaviour is fetcher middleware: retry with jitter, a three-state circuit breaker, trace IDs, logging that redacts `Cookie` / `Authorization` ([logging.go:60](https://github.com/xfengyin/jciyuan-spider/blob/main/internal/fetcher/middleware/logging.go#L60)). Pluggable storage plus a resume manager that persists crawl status ([internal/resume](https://github.com/xfengyin/jciyuan-spider/blob/main/internal/resume)).
**Trade-off.** The promised API stays two types; heavier pieces are reference implementations under `internal/`, not surface area.

### [DAQ Insight](https://github.com/xfengyin/daq-insight) — instrument data workbench

**Problem.** A DAQ970A / 34970A export is a messy text dump; splitting columns, inferring types and cleaning units is manual.
**Built.** A desktop pipeline — detect → parse → identify → clean → analyse → export — one module per stage under [`core/`](https://github.com/xfengyin/daq-insight/blob/main/core), a path guard constraining file access ([pathguard.ts](https://github.com/xfengyin/daq-insight/blob/main/core/security/pathguard.ts)), Vitest coverage for parser, identifier, exporter, path guard and edge cases. React 19 + TypeScript, 51 source files, Chinese UI.
**Trade-off.** Electron instead of a web app: instrument exports never leave the machine, so the tool is offline by construction.

### [picoclaw-opi-zero3-overlay](https://github.com/xfengyin/picoclaw-opi-zero3-overlay) — board support as an overlay

**Problem.** Upstream [sipeed/picoclaw](https://github.com/sipeed/picoclaw) has no Orange Pi Zero3 support, and forking it makes every upstream move a merge.
**Built.** 21 added files and exactly two one-line hooks on base commit `49183d7`: status-LED language, thermal watchdog, an `opi-info` diagnostic binary, systemd units ([README](https://github.com/xfengyin/picoclaw-opi-zero3-overlay#the-two-hooks)). The board package builds and tests green on an unmodified upstream tree, build tags and `CGO_ENABLED=0`.
**Trade-off.** Staying additive caps what the overlay may change, in exchange for rebase-ability.

## Also public

- [Protocol-algorithm](https://github.com/xfengyin/Protocol-algorithm) — WSN / LEACH simulation, registry-dispatched protocols, AI cluster-head selection, benchmark harness (Python).
- [FnDepot](https://github.com/xfengyin/FnDepot) — a gateway packaged as a native fnOS `.fpk`, plus a spec-conformant app index.
- [xfengyin.github.io](https://github.com/xfengyin/xfengyin.github.io) — the Zola site above: 17 posts, 21 in-repo check scripts (contrast, CLS, reduced motion, print).

## Decisions I would make the same way

1. **Pre-check before the model.** Anything the runtime can answer deterministically should not become a token spend ([agent.go:86](https://github.com/xfengyin/kongming-agent/blob/master/pkg/agent/agent.go#L86)). Price: a name rule instead of function calling. Gain: a loop testable offline.
2. **Retry policy belongs to the transport, not the scraper.** One middleware chain gives every crawler retry, breaker, trace and redaction ([middleware.go](https://github.com/xfengyin/jciyuan-spider/blob/main/internal/fetcher/middleware.go)).

## How I work

- CI and cross-compiled release binaries (linux, darwin-arm64, windows, checksums) on three tools: [kongming](https://github.com/xfengyin/kongming-agent/tree/master/.github/workflows) v0.7.0 / 7 releases, [jciyuan](https://github.com/xfengyin/jciyuan-spider/tree/main/.github/workflows) v0.5.0 / 5, [DAQ Insight](https://github.com/xfengyin/daq-insight) v0.1.0.
- Small dependency graphs on purpose: kongming runs on 4 direct modules ([go.mod](https://github.com/xfengyin/kongming-agent/blob/master/go.mod)).
- This page has one gate that really runs: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for layout and failure history, [scripts/check.sh](scripts/check.sh) for the checks.

## Contact

- [Open an issue](https://github.com/xfengyin/xfengyin/issues) — the channel I actually watch.
- [xfengyin.github.io](https://xfengyin.github.io) — longer notes in Chinese: hardware testing, PCB, sensors, Go.

> From cloud to edge: build the system, then prove it runs.
