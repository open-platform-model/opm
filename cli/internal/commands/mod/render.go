package mod

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"cuelang.org/go/cue"
	"github.com/open-platform-model/opm/cli/internal/appcontext"
	"github.com/open-platform-model/opm/cli/pkg/config"
	"github.com/open-platform-model/opm/cli/pkg/loader"
	"github.com/open-platform-model/opm/cli/pkg/logger"
	"github.com/open-platform-model/opm/cli/pkg/provider"
	"github.com/open-platform-model/opm/cli/pkg/renderer"
	"github.com/open-platform-model/opm/cli/pkg/transformer"
	"github.com/spf13/cobra"
)

type renderOptions struct {
	providerName string
	providerPath string
	values       string
	output       string
	rendererType string
	namespace    string
	format       string
	dryRun       bool
}

// NewRenderCommand creates the mod render command
func NewRenderCommand() *cobra.Command {
	opts := &renderOptions{}

	cmd := &cobra.Command{
		Use:   "render [module-path]",
		Short: "Render module to platform manifests",
		Long: `Transform OPM module components into platform-specific manifests.

This command loads a ModuleRelease file which embeds a ModuleDefinition with concrete
values. CUE automatically unifies the values with the module schema, making components
concrete and ready for transformation.

Directory structure:
  my-module/
  ├── module_definition.cue      # Module schema
  └── releases/
      ├── module_release.cue     # Default release (local dev)
      ├── dev.release.cue        # Dev environment
      └── prod.release.cue       # Production environment

The command:
1. Loads a ModuleRelease file (releases/module_release.cue or --values)
2. Extracts the embedded module (with concrete values from CUE unification)
3. Loads the specified provider
4. Matches transformers to each component
5. Executes transformations
6. Renders output manifests

Examples:
  # Use default release file (releases/module_release.cue)
  opm mod render .

  # Use specific release file
  opm mod render . --values releases/prod.release.cue

  # Render with specific provider and namespace
  opm mod render . --provider kubernetes --namespace production

  # Dry run (preview without writing)
  opm mod render . --dry-run

  # Split output into separate files per resource
  opm mod render . --renderer split --output ./manifests

  # Render as Kubernetes List format
  opm mod render . --renderer list

  # Render to JSON format
  opm mod render . --format json --output ./output.json`,
		Args: cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runRender(opts, args)
		},
	}

	cmd.Flags().StringVar(&opts.values, "values", "", "path to ModuleRelease file (default: releases/module_release.cue)")
	cmd.Flags().StringVar(&opts.providerName, "provider", "kubernetes", "provider name (e.g., kubernetes, docker-compose)")
	cmd.Flags().StringVar(&opts.providerPath, "provider-path", "", "path to provider file (overrides --provider)")
	cmd.Flags().StringVarP(&opts.output, "output", "o", "./output/", "output directory or file")
	cmd.Flags().StringVar(&opts.rendererType, "renderer", "stream", "renderer type (list|stream|split)")
	cmd.Flags().StringVarP(&opts.namespace, "namespace", "n", "default", "target namespace")
	cmd.Flags().StringVarP(&opts.format, "format", "f", "yaml", "output format (yaml|json)")
	cmd.Flags().BoolVar(&opts.dryRun, "dry-run", false, "show what would be rendered without writing files")

	return cmd
}

func runRender(opts *renderOptions, args []string) error {
	cfg := appcontext.GetConfig()

	// Determine module base path (directory containing the module)
	modulePath := "."
	if len(args) > 0 {
		modulePath = args[0]
	}

	absModulePath, err := filepath.Abs(modulePath)
	if err != nil {
		return fmt.Errorf("failed to resolve module path: %w", err)
	}

	// Validate output path for security
	if err := validateOutputPath(opts.output); err != nil {
		return fmt.Errorf("invalid output path: %w", err)
	}

	// Step 1: Determine release file path
	releaseFile, err := getReleaseFilePath(absModulePath, opts.values)
	if err != nil {
		return fmt.Errorf("failed to find release file: %w", err)
	}

	logger.Infow("rendering module",
		"release-file", releaseFile,
		"provider", opts.providerName,
		"output", opts.output,
		"namespace", opts.namespace,
		"renderer", opts.rendererType,
		"format", opts.format,
		"dry-run", opts.dryRun,
	)

	// Step 2: Load Provider
	prov, err := loadProvider(cfg, opts)
	if err != nil {
		return fmt.Errorf("failed to load provider: %w", err)
	}

	logger.Infow("provider loaded",
		"name", prov.Metadata.Name,
		"version", prov.Metadata.Version,
		"transformers", len(prov.Transformers),
	)

	// Step 3: Load ModuleRelease file
	l, err := loader.NewLoaderWithRegistry(cfg.Registry.URL)
	if err != nil {
		return fmt.Errorf("failed to create loader: %w", err)
	}

	releaseVal, err := l.LoadFile(releaseFile)
	if err != nil {
		return fmt.Errorf("failed to load release file: %w", err)
	}

	// Step 4: Extract ModuleRelease
	moduleReleaseVal, err := extractModuleRelease(releaseVal)
	if err != nil {
		return fmt.Errorf("failed to extract ModuleRelease: %w", err)
	}

	// Validate it's actually a ModuleRelease
	kind, err := l.ExtractString(moduleReleaseVal, "kind")
	if err != nil {
		return fmt.Errorf("ModuleRelease missing 'kind' field: %w", err)
	}
	if kind != "ModuleRelease" {
		return fmt.Errorf("expected kind 'ModuleRelease', got '%s'", kind)
	}

	// Step 5: Extract module definition for metadata
	moduleDefVal := moduleReleaseVal.LookupPath(cue.ParsePath("#module"))
	if !moduleDefVal.Exists() {
		return fmt.Errorf("ModuleRelease has no '#module' field")
	}

	// Extract module metadata from definition
	moduleName, err := l.ExtractString(moduleDefVal, "metadata.name")
	if err != nil {
		return fmt.Errorf("failed to extract module name: %w", err)
	}

	moduleVersion, _ := l.ExtractString(moduleDefVal, "metadata.apiVersion")

	logger.Infow("module loaded from release",
		"name", moduleName,
		"version", moduleVersion,
	)

	// Step 6: Extract concrete components (values already unified by CUE)
	// ModuleRelease schema creates: components: (_module: #module & {#values: values}).#components
	// This gives us fully resolved components with concrete values, not #values references
	componentsVal := moduleReleaseVal.LookupPath(cue.ParsePath("components"))
	if !componentsVal.Exists() {
		return fmt.Errorf("ModuleRelease has no 'components' field")
	}

	// Step 4: Create transformer matcher and executor
	matcher := transformer.NewMatcher(prov, transformer.MatchOptions{
		Strategy: transformer.StrategyBest,
		Strict:   false,
	})

	executor := transformer.NewExecutor(transformer.ExecutionOptions{
		Parallel:       true,
		FailFast:       true,
		ValidateInput:  true,
		ValidateOutput: true,
	})

	// Step 5: Build execution context
	execCtx := transformer.NewContextBuilder().
		WithModuleName(moduleName).
		WithModuleVersion(moduleVersion).
		WithNamespace(opts.namespace).
		WithCueContext(l.Context()).
		Build()

	// Step 6: Process each component
	var allResources []cue.Value
	iter, err := componentsVal.Fields()
	if err != nil {
		return fmt.Errorf("failed to iterate components: %w", err)
	}

	componentCount := 0
	for iter.Next() {
		componentName := iter.Label()
		componentVal := iter.Value()
		componentCount++

		logger.Infow("processing component",
			"component", componentName,
		)

		// Match transformers
		matchResult, err := matcher.MatchComponent(componentVal)
		if err != nil {
			return fmt.Errorf("failed to match transformers for component %s: %w", componentName, err)
		}

		if len(matchResult.Selected) == 0 {
			logger.Warnw("no transformers matched for component",
				"component", componentName,
			)
			continue
		}

		logger.Infow("matched transformers",
			"component", componentName,
			"count", len(matchResult.Selected),
		)

		// Execute ALL matched transformers
		results, err := executor.ExecuteAll(componentVal, matchResult.Selected, execCtx, prov.Metadata.Name)
		if err != nil {
			return fmt.Errorf("failed to execute transformers for component %s: %w", componentName, err)
		}

		// Collect resources from all execution results
		for _, result := range results {
			allResources = append(allResources, result.Resources...)

			logger.Debugw("transformer execution complete",
				"component", componentName,
				"transformer", result.Metadata.TransformerFQN,
				"resources", result.Metadata.ResourceCount,
			)
		}
	}

	if componentCount == 0 {
		return fmt.Errorf("module has no components")
	}

	if len(allResources) == 0 {
		return fmt.Errorf("no resources generated from module (processed %d components)", componentCount)
	}

	logger.Infow("transformation complete",
		"components", componentCount,
		"total_resources", len(allResources),
	)

	// Step 7: Parse format
	format, err := renderer.ParseFormat(opts.format)
	if err != nil {
		return fmt.Errorf("invalid format: %w", err)
	}

	// Step 8: Render and write based on renderer type
	writer := renderer.NewWriter(renderer.WriteOptions{
		DryRun:            opts.dryRun,
		Overwrite:         true,
		CreateDirectories: true,
		FileMode:          0600, // Secure permissions
	})

	var writeResult *renderer.WriteResult

	switch opts.rendererType {
	case "list":
		// Kubernetes List format - single file
		manifest, err := renderer.RenderKubernetesList(allResources, format)
		if err != nil {
			return fmt.Errorf("failed to render Kubernetes List: %w", err)
		}

		outputFile := opts.output
		if filepath.Ext(outputFile) == "" {
			// If output is a directory, create a file inside it
			outputFile = filepath.Join(outputFile, "resources."+string(format))
		}

		writeResult, err = writer.WriteSingle(manifest, outputFile)
		if err != nil {
			return fmt.Errorf("failed to write manifest: %w", err)
		}

	case "stream":
		// YAML document stream or JSON array - single file
		manifest, err := renderer.RenderSimple(allResources, format)
		if err != nil {
			return fmt.Errorf("failed to render manifests: %w", err)
		}

		outputFile := opts.output
		if filepath.Ext(outputFile) == "" {
			// If output is a directory, create a file inside it
			outputFile = filepath.Join(outputFile, "resources."+string(format))
		}

		writeResult, err = writer.WriteSingle(manifest, outputFile)
		if err != nil {
			return fmt.Errorf("failed to write manifest: %w", err)
		}

	case "split":
		// Separate file per resource
		manifests, err := writer.SplitResources(allResources, "{{.Kind}}-{{.Name}}"+renderer.GetFileExtension(format), format)
		if err != nil {
			return fmt.Errorf("failed to split resources: %w", err)
		}

		writeResult, err = writer.WriteMultiple(manifests, opts.output)
		if err != nil {
			return fmt.Errorf("failed to write manifests: %w", err)
		}

	default:
		return fmt.Errorf("unsupported renderer type: %s (supported: list, stream, split)", opts.rendererType)
	}

	// Step 9: Display summary
	logger.Infow("render complete",
		"files_written", writeResult.FilesWritten,
		"bytes_written", writeResult.BytesWritten,
	)

	if !opts.dryRun {
		fmt.Printf("\n✓ Rendered %d resources from %d components\n", len(allResources), componentCount)
		if writeResult.FilesWritten > 1 {
			fmt.Printf("✓ Wrote %d files to %s (%d bytes)\n", writeResult.FilesWritten, opts.output, writeResult.BytesWritten)
		} else {
			fmt.Printf("✓ Wrote to %s (%d bytes)\n", writeResult.FilePaths[0], writeResult.BytesWritten)
		}
	} else {
		fmt.Printf("\n[DRY RUN] Would render %d resources from %d components\n", len(allResources), componentCount)
		fmt.Printf("[DRY RUN] Would write %d files to %s\n", writeResult.FilesWritten, opts.output)
	}

	return nil
}

// findRepoRoot walks up the directory tree to find the repository root
// It looks for a .git directory as the primary marker
func findRepoRoot() string {
	cwd, err := os.Getwd()
	if err != nil {
		return ""
	}

	dir := cwd
	for {
		// Check for .git directory (git repo marker) - most reliable
		gitPath := filepath.Join(dir, ".git")
		if info, err := os.Stat(gitPath); err == nil && info.IsDir() {
			return dir
		}

		// Move up one directory
		parent := filepath.Dir(dir)
		if parent == dir {
			// Reached filesystem root without finding .git
			return ""
		}
		dir = parent
	}
}

func loadProvider(cfg *config.Config, opts *renderOptions) (*provider.Provider, error) {
	// Note: We disable ValidateOnLoad because provider transforms contain template
	// references (e.g., #component.spec.container) that will be resolved at execution time
	loadOpts := provider.DefaultLoadOptions()
	loadOpts.ValidateOnLoad = false
	loader := provider.NewLoader(loadOpts)

	// If provider path is specified, load from there
	if opts.providerPath != "" {
		absPath, err := filepath.Abs(opts.providerPath)
		if err != nil {
			return nil, fmt.Errorf("failed to resolve provider path: %w", err)
		}

		logger.Debugw("loading provider from path", "path", absPath)
		return loader.LoadFromPath(absPath)
	}

	// Otherwise, search by name (defaults to "kubernetes")
	// For now, we hardcode the kubernetes provider path
	// TODO: Implement proper provider discovery/registry system
	if opts.providerName == "kubernetes" {
		// Try to find repo root and construct path from there
		repoRoot := findRepoRoot()
		logger.Debugw("repo root detection", "repo-root", repoRoot)

		if repoRoot != "" {
			kubernetesPath := filepath.Join(repoRoot, "v1", "providers", "kubernetes")
			logger.Debugw("checking kubernetes path from repo root", "path", kubernetesPath)

			// Check if path exists
			if _, err := os.Stat(kubernetesPath); err == nil {
				logger.Debugw("loading kubernetes provider from repo root",
					"path", kubernetesPath,
					"repo-root", repoRoot,
				)
				return loader.LoadFromPath(kubernetesPath)
			} else {
				logger.Debugw("kubernetes path from repo root does not exist",
					"path", kubernetesPath,
					"error", err,
				)
			}
		}

		// If repo root not found, try relative path from current directory
		kubernetesPath := filepath.Join("v1", "providers", "kubernetes")
		logger.Debugw("checking kubernetes path from current directory", "path", kubernetesPath)

		if _, err := os.Stat(kubernetesPath); err == nil {
			logger.Debugw("loading kubernetes provider from relative path",
				"path", kubernetesPath,
			)
			return loader.LoadFromPath(kubernetesPath)
		} else {
			logger.Debugw("kubernetes path from current directory does not exist",
				"path", kubernetesPath,
				"error", err,
			)
		}

		logger.Debugw("kubernetes provider not found at hardcoded paths, trying configured path")
	}

	providersPath := cfg.Providers.Path
	if providersPath == "" {
		providersPath = "."
	}

	logger.Debugw("searching for provider",
		"name", opts.providerName,
		"path", providersPath,
	)

	// Walk directory to find provider
	var foundProvider *provider.Provider
	err := filepath.Walk(providersPath, func(p string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() || filepath.Ext(p) != ".cue" {
			return nil
		}

		prov, err := loader.LoadFromPath(p)
		if err != nil {
			return nil // Not a provider, skip
		}

		if prov.Metadata.Name == opts.providerName {
			foundProvider = prov
			return filepath.SkipAll // Found it, stop walking
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	if foundProvider == nil {
		return nil, fmt.Errorf("provider not found: %s (searched in: %s)", opts.providerName, providersPath)
	}

	return foundProvider, nil
}

// validateOutputPath performs security validation on the output path
func validateOutputPath(path string) error {
	if path == "" {
		return fmt.Errorf("output path cannot be empty")
	}

	// Clean the path to resolve . and .. components
	cleanPath := filepath.Clean(path)

	// If the path is relative, resolve it against current directory
	// to check for directory traversal attempts
	if !filepath.IsAbs(cleanPath) {
		cwd, err := os.Getwd()
		if err != nil {
			return fmt.Errorf("failed to get working directory: %w", err)
		}
		cleanPath = filepath.Join(cwd, cleanPath)
		cleanPath = filepath.Clean(cleanPath)
	}

	// Reject absolute paths to system directories
	dangerousPrefixes := []string{"/etc", "/bin", "/usr", "/sys", "/proc", "/boot", "/dev"}
	for _, prefix := range dangerousPrefixes {
		if strings.HasPrefix(cleanPath, prefix+string(filepath.Separator)) || cleanPath == prefix {
			return fmt.Errorf("output path targets system directory: %s", path)
		}
	}

	return nil
}

// getReleaseFilePath determines the release file path to use
func getReleaseFilePath(modulePath, valuesFlag string) (string, error) {
	// If --values flag is provided, use that (can be relative to modulePath or absolute)
	if valuesFlag != "" {
		// If absolute path, use as-is
		if filepath.IsAbs(valuesFlag) {
			if _, err := os.Stat(valuesFlag); err != nil {
				return "", fmt.Errorf("release file not found: %s", valuesFlag)
			}
			return valuesFlag, nil
		}

		// If relative, resolve relative to modulePath
		releasePath := filepath.Join(modulePath, valuesFlag)
		if _, err := os.Stat(releasePath); err != nil {
			return "", fmt.Errorf("release file not found: %s", releasePath)
		}
		return releasePath, nil
	}

	// Default: look for releases/module_release.cue
	defaultPath := filepath.Join(modulePath, "releases", "module_release.cue")
	if _, err := os.Stat(defaultPath); err == nil {
		return defaultPath, nil
	}

	// Not found - provide helpful error message
	return "", fmt.Errorf(`no release file found

Expected: releases/module_release.cue
Or use: --values <path-to-release-file>

To create a release file structure:
  mkdir -p releases
  # Create releases/module_release.cue with ModuleRelease definition

See documentation for ModuleRelease structure.`)
}

// extractModuleRelease finds and extracts the ModuleRelease value from a loaded CUE file
func extractModuleRelease(val cue.Value) (cue.Value, error) {
	// Pattern 1: Check if root value is a ModuleRelease
	kindVal := val.LookupPath(cue.ParsePath("kind"))
	if kindVal.Exists() {
		kind, err := kindVal.String()
		if err == nil && kind == "ModuleRelease" {
			return val, nil
		}
	}

	// Pattern 2: Search fields for a ModuleRelease
	iter, err := val.Fields()
	if err != nil {
		return cue.Value{}, fmt.Errorf("failed to iterate fields: %w", err)
	}

	for iter.Next() {
		fieldVal := iter.Value()
		kindField := fieldVal.LookupPath(cue.ParsePath("kind"))
		if kindField.Exists() {
			kind, err := kindField.String()
			if err == nil && kind == "ModuleRelease" {
				return fieldVal, nil
			}
		}
	}

	return cue.Value{}, fmt.Errorf("no ModuleRelease found in file (check that file contains a value with kind: \"ModuleRelease\")")
}
