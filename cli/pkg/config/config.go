package config

import (
	"fmt"
	"os"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
)

// Config represents the OPM CLI configuration
type Config struct {
	Registry    RegistryConfig    `json:"registry"`
	Definitions DefinitionsConfig `json:"definitions"`
	Providers   ProvidersConfig   `json:"providers"`
	Cache       CacheConfig       `json:"cache"`
	Log         LogConfig         `json:"log"`
}

// RegistryConfig contains registry-related configuration
type RegistryConfig struct {
	URL string `json:"url"` // OCI registry URL for module operations
}

// DefinitionsConfig contains definitions loading configuration
type DefinitionsConfig struct {
	Module string  `json:"module"` // CUE module import for definitions
	Path   *string `json:"path"`   // Optional local path override
}

// ProvidersConfig contains provider-related configuration
type ProvidersConfig struct {
	Path string `json:"path"` // Path to search for providers
}

// CacheConfig contains cache-related configuration
type CacheConfig struct {
	Enabled bool   `json:"enabled"` // Enable caching
	Dir     string `json:"dir"`     // Cache directory
	TTL     string `json:"ttl"`     // Time to live
}

// LogConfig contains logging configuration
type LogConfig struct {
	Level  string `json:"level"`  // debug|info|warn|error
	Format string `json:"format"` // text|json
}

// NewDefaultConfig returns a new Config with default values
func NewDefaultConfig() *Config {
	cacheDir, _ := GetCacheDir()

	return &Config{
		Registry: RegistryConfig{
			URL: "localhost:5000",
		},
		Definitions: DefinitionsConfig{
			Module: "opm.dev@v1",
			Path:   nil,
		},
		Providers: ProvidersConfig{
			Path: "", // Empty defaults to current directory in render command
		},
		Cache: CacheConfig{
			Enabled: true,
			Dir:     cacheDir,
			TTL:     "24h",
		},
		Log: LogConfig{
			Level:  "info",
			Format: "text",
		},
	}
}

// Load loads configuration from a specific path
func Load(path string) (*Config, error) {
	// Check if file exists
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return nil, fmt.Errorf("config file not found: %s", path)
	}

	// Load CUE file
	ctx := cuecontext.New()
	instances := load.Instances([]string{path}, nil)

	if len(instances) == 0 {
		return nil, fmt.Errorf("no CUE instances found in config file")
	}

	if instances[0].Err != nil {
		return nil, fmt.Errorf("failed to load config: %w", instances[0].Err)
	}

	val := ctx.BuildInstance(instances[0])
	if err := val.Err(); err != nil {
		return nil, fmt.Errorf("failed to build config: %w", err)
	}

	// Extract config struct from CUE
	cfg := &Config{}
	configVal := val.LookupPath(cue.ParsePath("config"))
	if !configVal.Exists() {
		return nil, fmt.Errorf("'config' field not found in config file")
	}

	if err := configVal.Decode(cfg); err != nil {
		return nil, fmt.Errorf("failed to decode config: %w", err)
	}

	return cfg, nil
}

// LoadDefault loads configuration from the default location (~/.opm/config.cue)
func LoadDefault() (*Config, error) {
	configPath, err := GetConfigPath()
	if err != nil {
		return nil, fmt.Errorf("failed to get config path: %w", err)
	}

	return Load(configPath)
}

// Save saves configuration to a file
func Save(path string, cfg *Config) error {
	// For now, we generate the config from template
	// In the future, this could preserve comments and structure
	return fmt.Errorf("Save not yet implemented - please edit config.cue manually")
}

// Validate validates the configuration
func Validate(cfg *Config) error {
	// Validate log level
	validLevels := map[string]bool{
		"debug": true,
		"info":  true,
		"warn":  true,
		"error": true,
	}
	if !validLevels[cfg.Log.Level] {
		return fmt.Errorf("invalid log level: %s (must be debug, info, warn, or error)", cfg.Log.Level)
	}

	// Validate log format
	validFormats := map[string]bool{
		"text": true,
		"json": true,
	}
	if !validFormats[cfg.Log.Format] {
		return fmt.Errorf("invalid log format: %s (must be text or json)", cfg.Log.Format)
	}

	// Validate cache TTL format (basic check)
	if cfg.Cache.TTL != "" {
		// Just check it's not empty - proper duration parsing happens at runtime
		if len(cfg.Cache.TTL) < 2 {
			return fmt.Errorf("invalid cache TTL: %s", cfg.Cache.TTL)
		}
	}

	// Validate definitions module is not empty
	if cfg.Definitions.Module == "" {
		return fmt.Errorf("definitions.module cannot be empty")
	}

	return nil
}

// ApplyEnvironmentOverrides applies environment variable overrides to config
func ApplyEnvironmentOverrides(cfg *Config) *Config {
	// Create a copy to avoid modifying the original
	result := *cfg

	// OPM_REGISTRY_URL overrides registry.url
	if registryURL := os.Getenv("OPM_REGISTRY_URL"); registryURL != "" {
		result.Registry.URL = registryURL
	}

	// OPM_DEFINITIONS_MODULE overrides definitions.module
	if defsModule := os.Getenv("OPM_DEFINITIONS_MODULE"); defsModule != "" {
		result.Definitions.Module = defsModule
	}

	// OPM_DEFINITIONS_PATH overrides definitions.path
	if defsPath := os.Getenv("OPM_DEFINITIONS_PATH"); defsPath != "" {
		result.Definitions.Path = &defsPath
	}

	// OPM_CACHE_DIR overrides cache.dir
	if cacheDir := os.Getenv("OPM_CACHE_DIR"); cacheDir != "" {
		result.Cache.Dir = cacheDir
	}

	// OPM_LOG_LEVEL overrides log.level
	if logLevel := os.Getenv("OPM_LOG_LEVEL"); logLevel != "" {
		result.Log.Level = logLevel
	}

	// OPM_LOG_FORMAT overrides log.format
	if logFormat := os.Getenv("OPM_LOG_FORMAT"); logFormat != "" {
		result.Log.Format = logFormat
	}

	return &result
}
