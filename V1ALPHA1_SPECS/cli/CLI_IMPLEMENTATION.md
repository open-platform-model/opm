# OPM CLI Technical Implementation Guide

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-03

---

## Overview

This document captures technical implementation decisions, design principles, and areas requiring research for the OPM CLI development.

**Target Audience:** CLI developers and contributors.

---

## Technical Implementation

### CLI Framework: Cobra

**Decision:** OPM CLI uses [Cobra](https://github.com/spf13/cobra) as the command-line framework.

**Rationale:**

- **Battle-tested**: Powers Kubernetes (kubectl), Docker, Hugo, GitHub CLI, and 173,000+ projects
- **Complex command support**: Native support for deeply nested commands with unlimited depth
- **Automatic generation**: Built-in shell completion (bash/zsh/fish/powershell) and man page generation
- **Rich features**: Persistent flags, command aliases, intelligent suggestions, pre/post-run hooks
- **Ecosystem**: Excellent integration with Viper for configuration management
- **UX consistency**: Users expect kubectl-like CLI patterns for platform tools

**Alternatives considered:**

- **Kong**: Lightweight and modern but smaller ecosystem and manual completion setup
- **urfave/cli**: Simpler but limited nesting support for complex command hierarchies

### Dependencies

Core dependencies:

- `github.com/spf13/cobra` - CLI framework
- `github.com/spf13/viper` - Configuration management (integrates with CUE config)
- Additional dependencies TBD (see "Areas Requiring Design Decisions" below)

---

## Design Principles

1. **Consistent Command Structure**: All commands follow `opm <noun> <verb>` pattern
2. **Sensible Defaults**: Common use cases work with minimal flags
3. **Progressive Disclosure**: Basic usage is simple, advanced features available via flags
4. **Composability**: Commands can be piped and combined with standard Unix tools
5. **Machine-Readable Output**: All commands support JSON/YAML output for scripting
6. **XDG Compliance**: Follows XDG Base Directory specification on Linux/Mac
7. **Clear Separation**: Config in `~/.opm/`, cache in `~/.cache/opm` (Linux/Mac)
8. **Explicit Configuration**: No hardcoded or hidden configuration - all defaults are written to `~/.opm/config.cue` on first use, making them visible and editable by users

---

## Areas Requiring Design Decisions

The following areas need research and technical decisions before implementation:

### 1. Output Formatting & Terminal UI ⚠️ HIGH PRIORITY

**Needs:**

- Table rendering for list commands (`opm unit list`, `opm registry list`)
- Colored/styled output for errors, warnings, success messages
- Progress indicators for long-running operations (`opm mod build`, `opm mod apply`)
- Spinners for network operations
- Tree/hierarchical display for nested structures

**Options to research:**

- Table libraries: `tablewriter`, `pterm`, `lipgloss + bubbles`
- Color libraries: `fatih/color`, `charmbracelet/lipgloss`
- Progress/spinners: `schollz/progressbar`, `cheggaaa/pb`, `briandowns/spinner`, `charmbracelet/bubbletea`
- Full TUI framework: `charmbracelet/bubbletea` (for interactive commands like `opm dev watch`)

**Questions:**

- Do we want rich TUI features or simple colored text?
- Should `opm dev watch` be interactive (like `kubectl get -w`) or just log-based?
- How do we handle `--no-color` across all output?

### 2. Logging Framework ⚠️ HIGH PRIORITY

**Needs:**

- Structured logging with levels (debug/info/warn/error)
- JSON output for machine parsing (`--log-format json`)
- Context propagation through command execution
- File logging for debugging complex builds

**Options to research:**

- `uber-go/zap` - Fast, structured, production-grade
- `rs/zerolog` - Zero-allocation, JSON-focused
- `sirupsen/logrus` - Popular but older, slower
- `log/slog` - Go 1.21+ standard library (simple, built-in)

**Questions:**

- Do we need high-performance logging or is stdlib sufficient?
- Should logs go to stderr by default?
- How do we integrate with Cobra's error handling?

### 3. Error Handling & User Feedback ⚠️ MEDIUM PRIORITY

**Needs:**

- User-friendly error messages with actionable suggestions
- Error wrapping and context throughout the stack
- Exit code management (see Exit Codes section in CLI_SPEC.md)
- Validation error formatting (especially for CUE errors)

**Options to research:**

- `pkg/errors` - Error wrapping (classic, but Go 1.13+ has built-in wrapping)
- `hashicorp/go-multierror` - Accumulating multiple errors
- Custom error types with formatting

**Questions:**

- How do we format CUE validation errors for end users?
- Should we show stack traces in `--verbose` mode?
- How do we handle and display transformer errors?

### 4. Testing Strategy ⚠️ MEDIUM PRIORITY

**Needs:**

- Unit tests for command logic
- Integration tests for full command execution
- Mock filesystem and network for testing
- Golden file testing for output formats

**Options to research:**

- `stretchr/testify` - Assertions and mocking (most popular)
- `google/go-cmp` - Deep comparison
- `spf13/afero` - Filesystem abstraction for testing
- Cobra's testing utilities

**Questions:**

- How do we test CUE evaluation in CLI commands?
- Should we use table-driven tests or BDD-style?
- How do we test interactive commands?

### 5. Configuration Management ⚠️ MEDIUM PRIORITY

**Decision:** Use `~/.opm/` as a full CUE module with explicit, user-visible configuration.

**Config Structure:**

```text
~/.opm/                        # Full CUE module (auto-generated on first use)
├── cue.mod/
│   └── module.cue            # CUE module definition
├── config.cue                # Main OPM configuration (all defaults written here)
└── credentials               # Sensitive data (optional, kubectl-style)
```

**Configuration Priority (highest to lowest):**

1. Command-line flags
2. Environment variables (`OPM_*`)
3. `~/.opm/config.cue` (user config with defaults written on init)
4. ❌ No hardcoded defaults in binary (explicit config philosophy)

**Registry Selection Priority:**

1. `OPM_REGISTRY` environment variable (highest priority)
2. `~/.opm/config.cue` → `config.registry.default` field
3. No fallback - if not configured, error with helpful message

**Note:** OPM ignores `CUE_REGISTRY` to avoid confusion. OPM uses `OPM_REGISTRY` for consistency.

**Credential Storage (layered approach):**

- **OCI registries**: CUE automatically reads from `~/.docker/config.json` (Docker/Podman standard)
- **Other secrets**: Store in `~/.opm/credentials` (kubectl-style, base64 encoded or encrypted)

**Example `~/.opm/config.cue` (auto-generated):**

```cue
package opmconfig

config: {
    registry: {
        default: "registry.opm.dev"  // Written on first use, user-editable
    }
    cache: {
        enabled: true
        ttl:     "24h"
    }
    log: {
        level:  "info"
        format: "text"
    }
}
```

**Implementation approach:**

- Use `cuelang.org/go` to load and validate `config.cue` (no Viper needed)
- Generate `~/.opm/` with default config on first CLI invocation or `opm config init`
- Validate config schema on every load
- All defaults are written to config file, not hardcoded in binary

**Questions to research:**

- How to encrypt/protect `~/.opm/credentials` file?
- Should we support credential exec plugins (like kubectl credential plugins)?
- What's the best UX for config migration if schema changes?

### 6. OCI Registry Client ⚠️ HIGH PRIORITY

**Decision:** Use CUE's built-in OCI registry support (`cuelang.org/go/mod/modregistry`).

**Rationale:**

- **CUE compatibility**: Guaranteed compatibility with CUE module format and registry protocol
- **Leverage existing work**: CUE SDK already handles authentication, pulling, pushing, caching
- **Consistency**: Same behavior and configuration as `cue` CLI (reuses `~/.config/cue/logins.json`)
- **Less maintenance**: CUE team maintains registry spec compliance
- **Native integration**: Works seamlessly with CUE's module system

**Implementation packages:**

- `cuelang.org/go/mod/modregistry` - Registry client interface
- `cuelang.org/go/mod/module` - Module metadata and versioning
- `cuelang.org/go/internal/mod/modpkgload` - Package loading (if needed)

**Questions to research:**

- How does CUE handle Docker credentials and authentication stores?
- What APIs are available for registry catalog listing?
- How do we integrate CUE's registry client with OPM's config and cache?
- Does CUE support offline/airgap scenarios?

### 7. Build & Release Tooling ⚠️ LOW PRIORITY

**Needs:**

- Cross-platform builds (Linux, macOS, Windows)
- Version embedding at build time
- Release automation
- Binary distribution

**Options to research:**

- `goreleaser/goreleaser` - Complete release automation
- `mitchellh/gox` - Simple cross-compilation
- GitHub Actions for CI/CD
- Homebrew tap for macOS distribution

**Questions:**

- Where do we host releases (GitHub Releases, OCI registry, custom)?
- Do we need self-update functionality (`opm upgrade`)?
- Should we distribute via package managers (brew, apt, yum)?

### 8. Parallelism & Performance ⚠️ LOW PRIORITY

**Needs:**

- Parallel transformer execution (mentioned in CLI spec)
- Concurrent file I/O for builds
- Context cancellation for Ctrl+C handling
- Resource pooling

**Options to research:**

- `golang.org/x/sync/errgroup` - Concurrent error handling
- Worker pool patterns
- Context propagation best practices

**Questions:**

- How do we show progress for parallel operations?
- Should parallelism be configurable (`--jobs=N`)?
- How do we handle partial failures in parallel execution?

---

## Recommended Research Priority

**Phase 1 (Immediate):**

1. Output Formatting & Terminal UI
2. Logging Framework
3. OCI Registry Client

**Phase 2 (Before beta):**

4. Configuration Management
5. Error Handling & User Feedback
6. Testing Strategy

**Phase 3 (Polish):**

7. Parallelism & Performance
8. Build & Release Tooling

---

## Future Considerations

Commands that may be added in future versions:

1. **`opm platform`** - Manage platform definitions
2. **`opm upgrade`** - Self-update CLI
3. **`opm policy`** - Manage policy definitions
4. **`opm scope`** - Manage scope definitions
5. **`opm plugin`** - Extensibility via plugins

---

## Implementation Roadmap

**Next Steps:**

1. ✅ Choose CLI framework (Cobra selected)
2. Research and decide on areas listed above
3. Design Go project structure
4. Implement core commands (version, config, completion)
5. Implement module commands (init, build, vet)
6. Implement registry commands (unit, trait, blueprint list/describe, cache)
7. Implement provider commands
8. Implement OCI registry commands (login, push, pull)
9. Implement dev tools
10. Write tests and documentation
11. Package and release

---

## Library Research Notes

### Output & Terminal UI

**Candidate: Charm Bracelet Suite (`lipgloss` + `bubbles` + `bubbletea`)**

Pros:
- Modern, composable TUI framework
- Rich styling with `lipgloss`
- Reusable components with `bubbles`
- Full interactive apps with `bubbletea`
- Used by many popular CLIs (gh, glow, soft-serve)

Cons:
- Learning curve for TUI model
- May be overkill for simple colored output

**Candidate: pterm**

Pros:
- Simple API for common patterns
- Tables, spinners, progress bars built-in
- Good for non-interactive CLIs
- Easy to disable with `--no-color`

Cons:
- Less flexible than Charm suite
- Not suitable for interactive UIs

**Recommendation:** Start with `pterm` for simple output, consider `bubbletea` for `opm dev watch`.

### Logging

**Candidate: log/slog (Go 1.21+ stdlib)**

Pros:
- Built-in, no external dependency
- Structured logging with context
- JSON output support
- Handler interface for extensibility

Cons:
- Less feature-rich than zap/zerolog
- Newer, less battle-tested

**Candidate: uber-go/zap**

Pros:
- Extremely fast
- Production-grade
- Rich ecosystem of integrations
- Battle-tested at scale

Cons:
- More complex API
- Heavier dependency

**Recommendation:** Use `log/slog` for simplicity unless performance testing shows need for `zap`.

### Testing

**Candidate: testify + afero**

Pros:
- `testify/assert` and `testify/require` for clean assertions
- `testify/mock` for mocking interfaces
- `afero` for filesystem abstraction (test CUE file operations)
- Industry standard

Cons:
- Adds dependencies

**Recommendation:** Use `testify` + `afero` for comprehensive testing.

### Error Handling

**Recommendation:** Use Go 1.13+ built-in error wrapping with custom error types.

```go
type ValidationError struct {
    Field string
    Value interface{}
    Err   error
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for %s: %v", e.Field, e.Err)
}

func (e *ValidationError) Unwrap() error {
    return e.Err
}
```

For accumulating multiple errors, consider `hashicorp/go-multierror`.

---

## Architecture Notes

### Command Structure

```text
cmd/opm/
├── main.go
├── root.go
├── mod/
│   ├── mod.go (parent command)
│   ├── init.go
│   ├── build.go
│   ├── render.go
│   ├── vet.go
│   ├── apply.go
│   └── show.go
├── bundle/
│   ├── bundle.go (parent command)
│   ├── init.go
│   ├── build.go
│   └── ...
├── registry/
│   ├── registry.go
│   ├── unit.go
│   ├── trait.go
│   ├── blueprint.go
│   └── cache.go
└── ...
```

### Package Structure

```text
pkg/
├── config/           # Configuration loading and management
├── loader/           # CUE file loading and unification
├── registry/         # Definition registry operations
├── transformer/      # Transformer matching and execution
├── renderer/         # Platform resource rendering
├── oci/              # OCI registry client wrapper
├── cache/            # Caching layer
└── version/          # Version information
```

### Data Flow

```text
1. Load Configuration (config.cue + env + flags)
   ↓
2. Parse CUE Files (ModuleDefinition/BundleDefinition)
   ↓
3. Flatten Blueprints (Module/Bundle)
   ↓
4. Match Transformers (Provider-specific)
   ↓
5. Execute Transformers (Generate platform resources)
   ↓
6. Render Output (YAML/JSON files)
```

---

## Contributing

When implementing features, follow these principles:

1. **User-first**: Optimize for clarity and usability
2. **Fail loudly**: Clear error messages with actionable guidance
3. **Test thoroughly**: Unit tests for logic, integration tests for workflows
4. **Document inline**: Code comments for complex logic
5. **Benchmark critical paths**: Module building and rendering performance matters

---

## Related Documentation

- [CLI Specification](../CLI_SPEC.md) - Full command reference
- [CLI Configuration](CLI_CONFIGURATION.md) - Configuration management details
- [Module Structure Guide](MODULE_STRUCTURE_GUIDE.md) - Directory organization
- [CLI Workflows](CLI_WORKFLOWS.md) - Common usage patterns

---

**Document Version:** 1.0.0-draft
**Date:** 2025-11-03
