package mod

import (
	"github.com/spf13/cobra"
)

// NewModCommand creates the mod parent command
func NewModCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "mod",
		Short: "Module operations",
		Long: `Operations on OPM modules.

An OPM module is a directory containing a module_definition.cue file (required).
The CLI accepts directory paths and automatically loads all .cue files in the package.

Examples:
  opm mod vet .                    # Validate current directory
  opm mod vet ./my-app             # Validate my-app directory
  opm mod show ./my-app            # Show module information`,
	}

	// Add subcommands
	cmd.AddCommand(NewInitCommand())
	cmd.AddCommand(NewRenderCommand())
	cmd.AddCommand(NewTidyCommand())
	cmd.AddCommand(NewVetCommand())
	cmd.AddCommand(NewShowCommand())
	cmd.AddCommand(NewTemplateCommand())

	return cmd
}
