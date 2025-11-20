package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/open-platform-model/opm/cli/pkg/config"
	"github.com/spf13/cobra"
)

// NewInitCommand creates the config init command
func NewInitCommand() *cobra.Command {
	var force bool

	cmd := &cobra.Command{
		Use:   "init",
		Short: "Initialize OPM configuration",
		Long: `Initialize the OPM configuration directory.

Creates ~/.opm/ with:
  - config.cue (main configuration with all defaults)
  - cue.mod/module.cue (CUE module definition)

The configuration file is written as a CUE file with all default values
explicitly set. You can edit this file to customize your OPM CLI experience.

Use --force to overwrite existing configuration.

Examples:
  opm config init              # Initialize with defaults
  opm config init --force      # Reinitialize, overwriting existing config`,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runInit(force)
		},
	}

	cmd.Flags().BoolVar(&force, "force", false, "overwrite existing configuration")

	return cmd
}

func runInit(force bool) error {
	// Check if config already exists
	exists, err := config.ConfigExists()
	if err != nil {
		return fmt.Errorf("failed to check if config exists: %w", err)
	}

	if exists && !force {
		configPath, _ := config.GetConfigPath()
		return fmt.Errorf("configuration already exists at %s\nUse --force to overwrite", configPath)
	}

	// 1. Ensure config directory exists
	configDir, err := config.EnsureConfigDir()
	if err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// 2. Ensure cue.mod directory exists
	cueModDir, err := config.EnsureCueModDir()
	if err != nil {
		return fmt.Errorf("failed to create cue.mod directory: %w", err)
	}

	// 3. Write cue.mod/module.cue
	moduleFile := filepath.Join(cueModDir, "module.cue")
	if err := os.WriteFile(moduleFile, []byte(config.DefaultModuleTemplate), 0644); err != nil {
		return fmt.Errorf("failed to write module.cue: %w", err)
	}

	// 4. Write config.cue (0600 for security - may contain credentials)
	configFile := filepath.Join(configDir, "config.cue")
	if err := os.WriteFile(configFile, []byte(config.DefaultConfigTemplate), 0600); err != nil {
		return fmt.Errorf("failed to write config.cue: %w", err)
	}

	// 5. Report success
	if force && exists {
		fmt.Printf("Configuration reinitialized at: %s\n", configDir)
	} else {
		fmt.Printf("Configuration initialized at: %s\n", configDir)
	}
	fmt.Printf("\nConfiguration file: %s\n", configFile)
	fmt.Printf("CUE module file: %s\n", moduleFile)
	fmt.Printf("\nEdit %s to customize your OPM CLI configuration.\n", configFile)

	return nil
}
