# claude-profile

Manage multiple [Claude Code](https://code.claude.com) configuration profiles. Switch between work and personal accounts, different MCP server setups, or separate settings without logging in and out.

Each profile is a complete, isolated Claude Code configuration directory (settings, credentials, MCP servers, CLAUDE.md, history -- everything). Once configured, `claude` automatically uses your active profile -- no special launch command needed.

## Install

**Linux / macOS / WSL:**

```sh
curl -fsSL https://raw.githubusercontent.com/rafaelcesardev/claude-code-profiles/main/install.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/rafaelcesardev/claude-code-profiles/main/install.ps1 | iex
```

The installer downloads the appropriate scripts and configures your shell. **Restart your shell** (or open a new terminal) after installing.

## Quick Start

```sh
# Create profiles
clp -c work
clp -c personal

# Set a default
clp -d work

# Just use claude — it automatically uses your default profile
claude
claude --resume
claude -p "explain this code"
```

> `clp` is a shorthand for `claude-profile`. Both work interchangeably.

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `clp` | | Show current profile status |
| `clp use <name>` | `-u` | Switch to a profile for this session |
| `clp create <name>` | `-c` | Create a new profile |
| `clp list` | `ls`, `-l` | List all profiles |
| `clp default [name]` | `-d` | Get or set the default profile |
| `clp which [name]` | `-w` | Show the config directory path |
| `clp delete <name>` | `rm` | Delete a profile (with confirmation) |
| `clp help` | `-h`, `--help` | Show help |

> `clp` and `claude-profile` are interchangeable.

## How It Works

Claude Code supports a `CLAUDE_CONFIG_DIR` environment variable that redirects where it stores configuration and data. `claude-profile` provides a `claude()` shell function that wraps the real `claude` binary:

1. Before each invocation, the wrapper checks if a default profile exists and auto-sets `CLAUDE_CONFIG_DIR`.
2. If `CLAUDE_CONFIG_DIR` is already set (e.g., via `claude-profile use`), it is used as-is.
3. The real `claude` binary is then called with all your arguments.

This means you never need to think about profiles during normal use -- just run `claude` as you always have.

### Session Override

To temporarily use a different profile in the current shell session:

```sh
# Temporarily use a different profile
clp -u personal
claude                          # uses "personal" for this shell session
```

The override lasts until you close the shell or run `clp -u` again.

### Profile Storage

Profiles are stored in platform-appropriate locations:

| Platform | Location |
|----------|----------|
| Linux | `$XDG_DATA_HOME/claude-profiles/` (default: `~/.local/share/claude-profiles/`) |
| macOS | `$XDG_DATA_HOME/claude-profiles/` (default: `~/.local/share/claude-profiles/`) |
| Windows | `%LOCALAPPDATA%\claude-profiles\` |

Each profile directory is a complete Claude Code config directory. After creating a profile and launching Claude with it, Claude will populate it with `settings.json`, `.credentials.json`, and everything else it needs.

### Profile Names

Profile names can contain letters, digits, hyphens, and underscores. Examples: `work`, `personal`, `client-acme`, `side_project`.

## Platform Support

| Script | Platform | Shell |
|--------|----------|-------|
| `claude-profile.sh` | Linux, macOS, WSL | bash, zsh (sourced) |
| `claude-profile.fish` | Linux, macOS, WSL | fish (conf.d) |
| `claude-profile-init.ps1` | Windows, Linux, macOS | PowerShell 5.1+ / pwsh 6+ (dot-sourced) |
| `claude-profile.cmd` | Windows | cmd.exe (use with `call` prefix) |

## Manual Install

If you prefer not to use the install scripts:

**Linux / macOS (bash/zsh):**

```sh
# Download
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/claude-profile"
curl -fsSL https://raw.githubusercontent.com/rafaelcesardev/claude-code-profiles/main/claude-profile.sh \
  -o "${XDG_DATA_HOME:-$HOME/.local/share}/claude-profile/claude-profile.sh"

# Add to shell profile (.bashrc or .zshrc)
echo '. "${XDG_DATA_HOME:-$HOME/.local/share}/claude-profile/claude-profile.sh"' >> ~/.bashrc
```

**Fish:**

```fish
# Download to conf.d (loaded on every shell startup)
mkdir -p ~/.config/fish/conf.d
curl -fsSL https://raw.githubusercontent.com/rafaelcesardev/claude-code-profiles/main/claude-profile.fish \
  -o ~/.config/fish/conf.d/claude-profile.fish
```

**Windows (PowerShell):**

```powershell
$dir = "$env:LOCALAPPDATA\claude-profile"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rafaelcesardev/claude-code-profiles/main/claude-profile-init.ps1" -OutFile "$dir\claude-profile-init.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rafaelcesardev/claude-code-profiles/main/claude-profile.cmd" -OutFile "$dir\claude-profile.cmd"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rafaelcesardev/claude-code-profiles/main/clp.cmd" -OutFile "$dir\clp.cmd"
# Add to PowerShell profile
Add-Content -Path $PROFILE -Value ". '$dir\claude-profile-init.ps1'"
# Add to PATH for cmd.exe
$path = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($path -notlike "*$dir*") { [Environment]::SetEnvironmentVariable('Path', "$path;$dir", 'User') }
```

## License

MIT
