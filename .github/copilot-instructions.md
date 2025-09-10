# Copilot Instructions - VScript MakoReactor Plugin

## Project Overview

This repository contains a SourcePawn plugin for SourceMod that extends functionality for the Counter-Strike: Source Zombie Escape map "ze_FFVII_Mako_Reactor_v5_3". The plugin provides a comprehensive voting system for different game stages/modes, race functionality, custom asset loading, and integration with ZombieReloaded.

**Primary Purpose**: Map-specific enhancements including stage voting, race mode, custom music/models, and entity manipulation.

## Technical Environment

### Core Dependencies
- **SourceMod**: 1.11.0+ (scripting platform)
- **SourcePawn**: Language for plugin development
- **ZombieReloaded**: Required plugin dependency for zombie functionality
- **MultiColors**: Library for colored chat messages
- **Game**: Counter-Strike: Source with specific map support

### Build System
- **SourceKnight**: Primary build tool (configured in `sourceknight.yaml`)
- **Dependencies**: Automatically managed via SourceKnight configuration
- **Output**: Compiled `.smx` files in `/addons/sourcemod/plugins/`
- **Assets**: Game files (models, materials, sounds) in `/common/` directory

### CI/CD Pipeline
- **GitHub Actions**: Automated building, packaging, and releases
- **Artifacts**: Complete packages including plugin and game assets
- **Releases**: Automatic tagging and release creation on main branch

## Repository Structure

```
/addons/sourcemod/scripting/     # SourcePawn source files (.sp)
/common/                         # Game assets
  /materials/                    # Material files (.vmt, .vtf)
  /models/                       # Model files (.mdl, .phy, .vvd, .vtx)
  /sound/                        # Audio files (.mp3)
/sourceknight.yaml              # Build configuration
/.github/workflows/ci.yml       # CI/CD pipeline
```

## Code Structure & Conventions

### SourcePawn Standards
- **Pragmas**: Always use `#pragma semicolon 1` and `#pragma newdecls required`
- **Variables**: 
  - Global variables: `g_` prefix, PascalCase (`g_bValidMap`)
  - Local variables: camelCase (`iCurrentStage`)
  - Function names: PascalCase (`OnPluginStart`)
- **Indentation**: 4 spaces (configured as tabs)
- **Memory Management**: Use `delete` for handles, no null checks needed
- **SQL Operations**: All SQL queries must be asynchronous using methodmaps
- **Collections**: Use `delete` for StringMap/ArrayList instead of `.Clear()` to prevent memory leaks
- **Comments**: Do not create unnecessary headers or descriptions; document only complex logic and native functions

### Key Plugin Components

#### 1. Vote System (`g_VoteMenu`, voting functions)
- Multi-stage voting for different game modes
- Cooldown system to prevent repeated stages
- Support for revotes when no clear majority
- Integration with SourceMod's native voting system

#### 2. Race Mode (`g_bRaceEnabled`, race commands)
- Auto-bhop functionality
- Infection/respawn blocking
- Plugin loading/unloading for anti-cheat compatibility
- Winner detection and special handling

#### 3. Asset Management (`VerifyMap()`, precaching)
- Custom model/material/sound precaching
- File downloads for clients
- Map-specific asset loading

#### 4. Entity Manipulation (`OnEntitySpawned`, various entity functions)
- Dynamic entity modification for map mechanics
- Targetname-based entity finding
- Input/output system integration

## Development Workflow

### Building the Plugin
```bash
# Using SourceKnight (preferred method)
sourceknight build

# Manual compilation (if needed)
spcomp VScript_ze_ffvii_mako_reactor_v5_3.sp
```

### Testing
- **Local Testing**: Test on development server with the specific map
- **Map Requirement**: Plugin only activates on `ze_FFVII_Mako_Reactor_v5_3`
- **Dependencies**: Ensure ZombieReloaded and MultiColors are loaded
- **Asset Verification**: Check all custom files are properly downloaded

### Configuration
- **ConVars**: Plugin creates several configurable variables (delays, percentages, etc.)
- **Commands**: Admin commands for manual voting and race control
- **Server Commands**: For integration with map/server systems

## Map-Specific Features

### Stage System
- **8 Different Stages**: From normal modes to extreme variants
- **Stage Identification**: Based on entity counter values
- **Cooldown Management**: Prevents repetitive stage selection

### Integration Points
- **Stripper**: Requires Stripper plugin for map modifications
- **AdminRoom**: Integration with AdminRoom plugin for enhanced features
- **Custom Files**: Specific models, materials, and sounds for enhanced gameplay

## Best Practices for Development

### Code Quality
- **Error Handling**: Always check return values from API calls
- **Resource Management**: Properly handle timers, menus, and arrays
- **Performance**: Minimize operations in frequently called functions (OnPlayerRunCmd)
- **Memory**: Use `delete` for StringMap/ArrayList instead of `.Clear()`
- **Methodmaps**: Use methodmaps for native functions and SQL operations
- **Translations**: Use translation files for all user-facing messages
- **Configuration**: Avoid hardcoded values; use ConVars for configurable options
- **Complexity**: Always try to improve complexity from O(n) to O(1) where possible

### Plugin Integration
- **Soft Dependencies**: Use `#undef REQUIRE_PLUGIN` pattern for optional plugins
- **Event Handling**: Properly hook and unhook events
- **Command Registration**: Use appropriate admin flags and descriptions

### Entity Management
- **Validation**: Always validate entities before manipulation
- **Targetname Handling**: Support both targetnames and HammerIDs
- **Input/Output**: Properly format entity I/O for map integration

## Common Development Tasks

### Adding New Stages
1. Update `NUMBEROFSTAGES` constant
2. Add stage name to `g_sStageName` array
3. Update `GetCurrentStage()` function with new counter value
4. Test voting system with new stage

### Modifying Vote System
- **Menu Generation**: Update `InitiateVote()` function
- **Vote Handling**: Modify `Handler_SettingsVoteFinished()` for custom logic
- **Cooldown Logic**: Adjust in `Cmd_StartVote()` function

### Asset Integration
- **Precaching**: Add to `VerifyMap()` function
- **Downloads**: Use `AddFileToDownloadsTable()` for client downloads
- **Validation**: Ensure assets exist before precaching

### Code Maintenance Guidelines
- **Plugin Structure**: Implement OnPluginStart() for initialization, OnPluginEnd() for cleanup if necessary
- **Commands**: Register commands with proper descriptions and admin permissions
- **Modules**: Use includes for shared functionality
- **Version Control**: Use semantic versioning (MAJOR.MINOR.PATCH)
- **Compatibility**: Ensure compatibility with minimum SourceMod version (1.12+)

## Debugging & Troubleshooting

### Common Issues
- **Map Validation**: Plugin only works on specific map
- **Dependencies**: Missing ZombieReloaded causes compilation warnings
- **Assets**: Incorrect file paths cause precache failures
- **Voting**: Timer conflicts can cause vote issues

### Debug Tools
- **SourceMod Logs**: Check error logs for plugin issues
- **Entity Dumps**: Use `sm_dump_entities` for entity debugging
- **Console Commands**: Plugin provides several test commands

## Performance Considerations

### Critical Paths
- **OnPlayerRunCmd**: Minimize operations, used for bhop functionality
- **OnEntitySpawned**: Called frequently, keep processing minimal
- **Vote System**: Consider server load during vote periods

### Optimization
- **Caching**: Cache expensive entity lookups
- **Lazy Loading**: Only load assets when map is valid
- **Timer Management**: Properly cleanup timers to prevent leaks

## File Modification Guidelines

### Core Plugin File
- **Header**: Maintain plugin info structure
- **Dependencies**: Keep include order for compatibility
- **Functions**: Follow existing naming and structure patterns

### Asset Files
- **Paths**: Maintain consistent directory structure
- **Naming**: Follow existing naming conventions
- **Formats**: Use appropriate file formats for game compatibility

This plugin is highly specialized for a specific map and gameplay mode. When making changes, always consider the impact on the voting system, race functionality, and map integration. Test thoroughly on the target map before deployment.