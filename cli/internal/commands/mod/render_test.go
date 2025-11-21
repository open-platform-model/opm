package mod

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"cuelang.org/go/cue"
	"github.com/open-platform-model/opm/cli/internal/appcontext"
	"github.com/open-platform-model/opm/cli/pkg/config"
	"github.com/open-platform-model/opm/cli/pkg/loader"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// === TEST HELPERS ===

// isKubectlAvailable checks if kubectl is available in PATH
func isKubectlAvailable() bool {
	_, err := exec.LookPath("kubectl")
	return err == nil
}

// validateKubernetesYAML validates YAML using kubectl --dry-run=client
func validateKubernetesYAML(t *testing.T, yamlContent string) {
	if !isKubectlAvailable() {
		t.Skip("kubectl not available, skipping Kubernetes validation")
	}

	cmd := exec.Command("kubectl", "apply", "--dry-run=client", "-f", "-")
	cmd.Stdin = strings.NewReader(yamlContent)
	output, err := cmd.CombinedOutput()

	if err != nil {
		t.Logf("kubectl output: %s", string(output))
		t.Fatalf("kubectl validation failed: %v", err)
	}
}

// setupTestConfig creates a minimal test configuration
func setupTestConfig(t *testing.T) *config.Config {
	tmpDir := t.TempDir()

	cfg := &config.Config{
		Registry: config.RegistryConfig{
			URL: "localhost:5000",
		},
		Providers: config.ProvidersConfig{
			Path: tmpDir,
		},
	}

	// Set up app context
	appcontext.SetConfig(cfg)

	return cfg
}

// getKubernetesProviderPath returns the absolute path to the Kubernetes provider
func getKubernetesProviderPath(t *testing.T) string {
	// Get current working directory (cli/internal/commands/mod during tests)
	cwd, err := os.Getwd()
	require.NoError(t, err)

	// Provider is at ../../../../v1/providers/kubernetes/provider.cue
	// cli/internal/commands/mod -> cli -> opm -> v1/providers/kubernetes/provider.cue
	providerPath := filepath.Join(cwd, "..", "..", "..", "..", "v1", "providers", "kubernetes", "provider.cue")
	absPath, err := filepath.Abs(providerPath)
	require.NoError(t, err)

	// Verify provider exists
	_, err = os.Stat(absPath)
	if err != nil {
		t.Fatalf("provider file not found at %s: %v", absPath, err)
	}

	return absPath
}

// === UNIT TESTS: validateOutputPath ===

func TestValidateOutputPath_ValidRelativePaths(t *testing.T) {
	tests := []struct {
		name string
		path string
	}{
		{"current directory", "."},
		{"subdirectory", "./output"},
		{"nested subdirectory", "./output/manifests"},
		{"simple name", "output"},
		{"with extension", "output.yaml"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateOutputPath(tt.path)
			assert.NoError(t, err, "path should be valid: %s", tt.path)
		})
	}
}

func TestValidateOutputPath_ValidAbsolutePaths(t *testing.T) {
	tmpDir := t.TempDir()

	tests := []struct {
		name string
		path string
	}{
		{"temp directory", tmpDir},
		{"temp subdirectory", filepath.Join(tmpDir, "output")},
		{"tmp prefix", "/tmp/opm-test"},
		{"home directory", filepath.Join(os.Getenv("HOME"), "opm-output")},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateOutputPath(tt.path)
			assert.NoError(t, err, "path should be valid: %s", tt.path)
		})
	}
}

func TestValidateOutputPath_DirectoryTraversal(t *testing.T) {
	// Note: After the security fix, these paths are allowed if they don't resolve to system directories
	// The key is that filepath.Clean() properly resolves them
	tests := []struct {
		name      string
		path      string
		shouldErr bool
	}{
		{"double dot", "./output/../other", false},      // Resolves to ./other
		{"multiple traversal", "../../test", false},     // Allowed if not system dir
		{"absolute with traversal", "/tmp/../tmp/test", false}, // Resolves to /tmp/test
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateOutputPath(tt.path)
			if tt.shouldErr {
				assert.Error(t, err, "path should be invalid: %s", tt.path)
			} else {
				assert.NoError(t, err, "path should be valid after cleaning: %s", tt.path)
			}
		})
	}
}

func TestValidateOutputPath_SystemDirectories(t *testing.T) {
	tests := []struct {
		name string
		path string
	}{
		{"/etc", "/etc"},
		{"/etc with file", "/etc/passwd"},
		{"/bin", "/bin"},
		{"/bin with file", "/bin/bash"},
		{"/usr", "/usr"},
		{"/usr subdirectory", "/usr/local/bin"},
		{"/sys", "/sys"},
		{"/proc", "/proc"},
		{"/boot", "/boot"},
		{"/dev", "/dev"},
		{"/dev with file", "/dev/null"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateOutputPath(tt.path)
			assert.Error(t, err, "system directory should be rejected: %s", tt.path)
			assert.Contains(t, err.Error(), "system directory")
		})
	}
}

func TestValidateOutputPath_EdgeCases(t *testing.T) {
	tests := []struct {
		name      string
		path      string
		shouldErr bool
	}{
		{"empty string", "", true},
		{"just slash", "/", false},                    // Not a system directory
		{"multiple slashes", "///tmp///test", false},  // Cleans to /tmp/test
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateOutputPath(tt.path)
			if tt.shouldErr {
				assert.Error(t, err, "path should be invalid: %s", tt.path)
			} else {
				assert.NoError(t, err, "path should be valid: %s", tt.path)
			}
		})
	}
}

// === UNIT TESTS: getReleaseFilePath ===

func TestGetReleaseFilePath_DefaultPath(t *testing.T) {
	tmpDir := t.TempDir()
	modulePath := filepath.Join(tmpDir, "test-module")
	releasesDir := filepath.Join(modulePath, "releases")

	// Create releases directory and file
	err := os.MkdirAll(releasesDir, 0755)
	require.NoError(t, err)

	releaseFile := filepath.Join(releasesDir, "module_release.cue")
	err = os.WriteFile(releaseFile, []byte("// release file"), 0644)
	require.NoError(t, err)

	// Test default path
	result, err := getReleaseFilePath(modulePath, "")

	require.NoError(t, err)
	assert.Equal(t, releaseFile, result)
}

func TestGetReleaseFilePath_CustomRelativePath(t *testing.T) {
	tmpDir := t.TempDir()
	modulePath := filepath.Join(tmpDir, "test-module")

	// Create module directory
	err := os.MkdirAll(modulePath, 0755)
	require.NoError(t, err)

	// Create custom release file
	customFile := filepath.Join(modulePath, "custom.release.cue")
	err = os.WriteFile(customFile, []byte("// custom release"), 0644)
	require.NoError(t, err)

	// Test custom relative path
	result, err := getReleaseFilePath(modulePath, "custom.release.cue")

	require.NoError(t, err)
	assert.Equal(t, customFile, result)
}

func TestGetReleaseFilePath_CustomAbsolutePath(t *testing.T) {
	tmpDir := t.TempDir()
	modulePath := filepath.Join(tmpDir, "test-module")
	customFile := filepath.Join(tmpDir, "elsewhere", "release.cue")

	// Create custom release file
	err := os.MkdirAll(filepath.Dir(customFile), 0755)
	require.NoError(t, err)
	err = os.WriteFile(customFile, []byte("// custom release"), 0644)
	require.NoError(t, err)

	// Test custom absolute path
	result, err := getReleaseFilePath(modulePath, customFile)

	require.NoError(t, err)
	assert.Equal(t, customFile, result)
}

func TestGetReleaseFilePath_FileNotFound(t *testing.T) {
	tmpDir := t.TempDir()
	modulePath := filepath.Join(tmpDir, "test-module")

	// Don't create the file
	result, err := getReleaseFilePath(modulePath, "")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "no release file found")
	assert.Empty(t, result)
}

func TestGetReleaseFilePath_CustomFileNotFound(t *testing.T) {
	tmpDir := t.TempDir()
	modulePath := filepath.Join(tmpDir, "test-module")

	// Test with non-existent custom file
	result, err := getReleaseFilePath(modulePath, "nonexistent.cue")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "not found")
	assert.Empty(t, result)
}

// === UNIT TESTS: extractModuleRelease ===

func TestExtractModuleRelease_RootPattern(t *testing.T) {
	l, err := loader.NewLoader()
	require.NoError(t, err)

	cueContent := `
kind: "ModuleRelease"
metadata: {
	name: "test-release"
}
module: {
	kind: "ModuleDefinition"
	metadata: name: "test-module"
}
`
	val := l.Context().CompileString(cueContent)
	require.NoError(t, val.Err())

	result, err := extractModuleRelease(val)

	require.NoError(t, err)
	assert.True(t, result.Exists())

	kind, err := l.ExtractString(result, "kind")
	require.NoError(t, err)
	assert.Equal(t, "ModuleRelease", kind)
}

func TestExtractModuleRelease_FieldPattern(t *testing.T) {
	l, err := loader.NewLoader()
	require.NoError(t, err)

	cueContent := `
myRelease: {
	kind: "ModuleRelease"
	metadata: {
		name: "test-release"
	}
	module: {
		kind: "ModuleDefinition"
	}
}
`
	val := l.Context().CompileString(cueContent)
	require.NoError(t, val.Err())

	result, err := extractModuleRelease(val)

	require.NoError(t, err)
	assert.True(t, result.Exists())

	kind, err := l.ExtractString(result, "kind")
	require.NoError(t, err)
	assert.Equal(t, "ModuleRelease", kind)
}

func TestExtractModuleRelease_NotFound(t *testing.T) {
	l, err := loader.NewLoader()
	require.NoError(t, err)

	cueContent := `
kind: "ModuleDefinition"
metadata: name: "not-a-release"
`
	val := l.Context().CompileString(cueContent)
	require.NoError(t, val.Err())

	result, err := extractModuleRelease(val)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "no ModuleRelease found")
	assert.Equal(t, cue.Value{}, result)
}

// === UNIT TESTS: loadProvider ===

func TestLoadProvider_NotImplementedYet(t *testing.T) {
	// TODO: Implement after creating provider fixtures
	t.Skip("Provider loading tests require proper test fixtures")
}

// === INTEGRATION TESTS ===

func TestRenderCommand_StreamYAML(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "output.yaml"),
		rendererType: "stream",
		namespace:    "default",
		format:       "yaml",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})

	require.NoError(t, err)

	// Verify output file exists
	outputFile := filepath.Join(outputDir, "output.yaml")
	assert.FileExists(t, outputFile)

	// Read and verify content
	content, err := os.ReadFile(outputFile)
	require.NoError(t, err)

	yamlContent := string(content)
	assert.Contains(t, yamlContent, "---")  // YAML document separator
	assert.Contains(t, yamlContent, "kind: Deployment")
	assert.Contains(t, yamlContent, "apiVersion: apps/v1")
	assert.Contains(t, yamlContent, "name: web-server")
	assert.Contains(t, yamlContent, "name: api-server")
}

func TestRenderCommand_KubernetesList(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "list.yaml"),
		rendererType: "list",
		namespace:    "default",
		format:       "yaml",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})

	require.NoError(t, err)

	// Verify output file exists
	outputFile := filepath.Join(outputDir, "list.yaml")
	assert.FileExists(t, outputFile)

	// Read and verify content
	content, err := os.ReadFile(outputFile)
	require.NoError(t, err)

	yamlContent := string(content)
	assert.Contains(t, yamlContent, "apiVersion: v1")
	assert.Contains(t, yamlContent, "kind: List")
	assert.Contains(t, yamlContent, "items:")
	assert.Contains(t, yamlContent, "kind: Deployment")
}

func TestRenderCommand_SplitFiles(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       outputDir,
		rendererType: "split",
		namespace:    "default",
		format:       "yaml",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})

	require.NoError(t, err)

	// Verify multiple files were created
	files, err := os.ReadDir(outputDir)
	require.NoError(t, err)
	assert.Greater(t, len(files), 1, "split renderer should create multiple files")

	// Verify at least one file contains Deployment
	foundDeployment := false
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		content, err := os.ReadFile(filepath.Join(outputDir, file.Name()))
		require.NoError(t, err)
		if strings.Contains(string(content), "kind: Deployment") {
			foundDeployment = true
			break
		}
	}
	assert.True(t, foundDeployment, "should find at least one Deployment file")
}

func TestRenderCommand_JSONFormat(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "output.json"),
		rendererType: "stream",
		namespace:    "default",
		format:       "json",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})

	require.NoError(t, err)

	// Verify output file exists
	outputFile := filepath.Join(outputDir, "output.json")
	assert.FileExists(t, outputFile)

	// Read and verify it's valid JSON
	content, err := os.ReadFile(outputFile)
	require.NoError(t, err)

	jsonContent := string(content)
	assert.True(t, strings.HasPrefix(jsonContent, "["), "JSON should be an array")
	// Check for Deployment kind in JSON (with or without spaces)
	hasDeployment := strings.Contains(jsonContent, `"kind":"Deployment"`) || strings.Contains(jsonContent, `"kind": "Deployment"`)
	assert.True(t, hasDeployment, "JSON should contain Deployment kind")
}

func TestRenderCommand_CustomNamespace(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "output.yaml"),
		rendererType: "stream",
		namespace:    "production",
		format:       "yaml",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})

	require.NoError(t, err)

	// Verify output contains custom namespace
	content, err := os.ReadFile(filepath.Join(outputDir, "output.yaml"))
	require.NoError(t, err)

	yamlContent := string(content)
	assert.Contains(t, yamlContent, "namespace: production")
}

func TestRenderCommand_WithTraits(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "complex-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "output.yaml"),
		rendererType: "stream",
		namespace:    "default",
		format:       "yaml",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})

	require.NoError(t, err)

	// Verify output contains traits
	content, err := os.ReadFile(filepath.Join(outputDir, "output.yaml"))
	require.NoError(t, err)

	yamlContent := string(content)
	// Check for sidecars
	hasSidecar := strings.Contains(yamlContent, "log-collector") || strings.Contains(yamlContent, "fluent")
	assert.True(t, hasSidecar, "should contain sidecar containers")
	// Check for init containers
	hasInitContainer := strings.Contains(yamlContent, "initContainers") || strings.Contains(yamlContent, "db-migration")
	assert.True(t, hasInitContainer, "should contain init containers")
}

func TestRenderCommand_DryRun(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "output.yaml"),
		rendererType: "stream",
		namespace:    "default",
		format:       "yaml",
		dryRun:       true,
	}

	err := runRender(opts, []string{modulePath})

	require.NoError(t, err)

	// Verify output file was NOT created (dry run)
	outputFile := filepath.Join(outputDir, "output.yaml")
	_, err = os.Stat(outputFile)
	assert.True(t, os.IsNotExist(err), "dry-run should not create output file")
}

func TestRenderCommand_ErrorCases(t *testing.T) {
	tests := []struct {
		name         string
		modulePath   string
		errorMessage string
	}{
		{
			name:         "no release file",
			modulePath:   filepath.Join("..", "..", "..", "testdata", "invalid-modules", "no-release"),
			errorMessage: "no release file found",
		},
		{
			name:         "invalid CUE syntax",
			modulePath:   filepath.Join("..", "..", "..", "testdata", "invalid-modules", "invalid-syntax"),
			errorMessage: "failed to load",
		},
		{
			name:         "no components",
			modulePath:   filepath.Join("..", "..", "..", "testdata", "invalid-modules", "no-components"),
			errorMessage: "no components",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			setupTestConfig(t)
			outputDir := t.TempDir()

			opts := &renderOptions{
				providerName: "kubernetes",
				providerPath: getKubernetesProviderPath(t),
				values:       "",
				output:       filepath.Join(outputDir, "output.yaml"),
				rendererType: "stream",
				namespace:    "default",
				format:       "yaml",
				dryRun:       false,
			}

			err := runRender(opts, []string{tt.modulePath})

			assert.Error(t, err, "should fail for %s", tt.name)
			assert.Contains(t, err.Error(), tt.errorMessage)
		})
	}
}

func TestRenderCommand_ValidKubernetesOutput(t *testing.T) {
	if !isKubectlAvailable() {
		t.Skip("kubectl not available, skipping Kubernetes validation")
	}

	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "output.yaml"),
		rendererType: "stream",
		namespace:    "default",
		format:       "yaml",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})
	require.NoError(t, err)

	// Read output
	content, err := os.ReadFile(filepath.Join(outputDir, "output.yaml"))
	require.NoError(t, err)

	// Validate with kubectl
	validateKubernetesYAML(t, string(content))
}

func TestRenderCommand_FilePermissions(t *testing.T) {
	setupTestConfig(t)
	outputDir := t.TempDir()
	modulePath := filepath.Join("..", "..", "..", "testdata", "webapi-module")

	opts := &renderOptions{
		providerName: "kubernetes",
		providerPath: getKubernetesProviderPath(t),
		values:       "",
		output:       filepath.Join(outputDir, "output.yaml"),
		rendererType: "stream",
		namespace:    "default",
		format:       "yaml",
		dryRun:       false,
	}

	err := runRender(opts, []string{modulePath})
	require.NoError(t, err)

	// Check file permissions
	outputFile := filepath.Join(outputDir, "output.yaml")
	info, err := os.Stat(outputFile)
	require.NoError(t, err)

	// Verify file is readable only by owner (0600)
	mode := info.Mode().Perm()
	assert.Equal(t, os.FileMode(0600), mode, "file should have 0600 permissions")
}
