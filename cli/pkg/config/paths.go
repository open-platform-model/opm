package config

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
)

// GetConfigDir returns the OPM config directory
// Priority:
// 1. OPM_CONFIG_PATH environment variable
// 2. XDG_CONFIG_HOME/opm (Linux/Mac)
// 3. ~/.opm (fallback)
func GetConfigDir() (string, error) {
	// 1. Check OPM_CONFIG_PATH
	if configPath := os.Getenv("OPM_CONFIG_PATH"); configPath != "" {
		return configPath, nil
	}

	// 2. Check XDG_CONFIG_HOME
	if xdgConfig := os.Getenv("XDG_CONFIG_HOME"); xdgConfig != "" && runtime.GOOS != "windows" {
		return filepath.Join(xdgConfig, "opm"), nil
	}

	// 3. Fallback to ~/.opm
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}

	return filepath.Join(homeDir, ".opm"), nil
}

// GetConfigPath returns the full path to config.cue
func GetConfigPath() (string, error) {
	configDir, err := GetConfigDir()
	if err != nil {
		return "", err
	}

	return filepath.Join(configDir, "config.cue"), nil
}

// GetCacheDir returns the cache directory
// Priority:
// 1. OPM_CACHE_DIR environment variable
// 2. XDG_CACHE_HOME/opm (Linux/Mac)
// 3. ~/.cache/opm (fallback)
func GetCacheDir() (string, error) {
	// 1. Check OPM_CACHE_DIR
	if cacheDir := os.Getenv("OPM_CACHE_DIR"); cacheDir != "" {
		return cacheDir, nil
	}

	// 2. Check XDG_CACHE_HOME
	if xdgCache := os.Getenv("XDG_CACHE_HOME"); xdgCache != "" && runtime.GOOS != "windows" {
		return filepath.Join(xdgCache, "opm"), nil
	}

	// 3. Fallback to ~/.cache/opm
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}

	// On Windows, use AppData\Local\opm\cache
	if runtime.GOOS == "windows" {
		localAppData := os.Getenv("LOCALAPPDATA")
		if localAppData != "" {
			return filepath.Join(localAppData, "opm", "cache"), nil
		}
		return filepath.Join(homeDir, "AppData", "Local", "opm", "cache"), nil
	}

	return filepath.Join(homeDir, ".cache", "opm"), nil
}

// EnsureConfigDir creates the config directory if it doesn't exist
// Returns the config directory path
func EnsureConfigDir() (string, error) {
	configDir, err := GetConfigDir()
	if err != nil {
		return "", err
	}

	// Create directory with 0700 permissions (owner-only access for security)
	if err := os.MkdirAll(configDir, 0700); err != nil {
		return "", fmt.Errorf("failed to create config directory: %w", err)
	}

	return configDir, nil
}

// EnsureCueModDir creates the cue.mod directory inside config directory
// Returns the cue.mod directory path
func EnsureCueModDir() (string, error) {
	configDir, err := EnsureConfigDir()
	if err != nil {
		return "", err
	}

	cueModDir := filepath.Join(configDir, "cue.mod")

	// Create cue.mod directory with 0755 permissions
	if err := os.MkdirAll(cueModDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create cue.mod directory: %w", err)
	}

	return cueModDir, nil
}

// ConfigExists checks if the config file already exists
func ConfigExists() (bool, error) {
	configPath, err := GetConfigPath()
	if err != nil {
		return false, err
	}

	_, err = os.Stat(configPath)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}
