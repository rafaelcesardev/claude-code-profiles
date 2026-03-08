# claude-profile.fish — Fish shell port of claude-profile.sh
#
# Install (via conf.d — loads all functions on shell startup):
#   mkdir -p ~/.config/fish/conf.d
#   cp claude-profile.fish ~/.config/fish/conf.d/
#
# Do NOT place in ~/.config/fish/functions/ — that directory uses
# lazy autoloading (one function per file), so the claude() wrapper
# would not be available until claude-profile is called first.

if set -q XDG_DATA_HOME
    set -g _CP_DATA "$XDG_DATA_HOME/claude-profiles"
else
    set -g _CP_DATA "$HOME/.local/share/claude-profiles"
end

# --- Internal helpers ---

function _cp_die
    echo "claude-profile: $argv" >&2
end

function _cp_validate_name
    set -l name $argv[1]
    if test -z "$name"
        _cp_die "profile name must not be empty"
        return 1
    end
    if string match -qr '^\.' -- $name
        _cp_die "invalid profile name '$name': must not start with '.'"
        return 1
    end
    if string match -qr '\.\.' -- $name
        _cp_die "invalid profile name '$name': must not contain '..'"
        return 1
    end
    if string match -qr '/' -- $name; or string match -q '*\\*' -- $name
        _cp_die "invalid profile name '$name': must not contain '/' or '\\'"
        return 1
    end
    if not string match -qr '^[A-Za-z0-9_-]+$' -- $name
        _cp_die "invalid profile name '$name': use only letters, digits, hyphens, underscores"
        return 1
    end
end

# --- claude wrapper ---
# Uses default profile if CLAUDE_CONFIG_DIR is not already set.

function claude
    if not set -q CLAUDE_CONFIG_DIR
        set -l def_file "$_CP_DATA/.default"
        if test -f "$def_file"
            set -l def_name (cat "$def_file")
            if test -n "$def_name" -a -d "$_CP_DATA/$def_name"
                set -x CLAUDE_CONFIG_DIR "$_CP_DATA/$def_name"
            end
        end
    end
    command claude $argv
end

# --- claude-profile management ---

function claude-profile
    set -l cmd $argv[1]
    set -l def_file "$_CP_DATA/.default"

    switch "$cmd"

        case use
            if test (count $argv) -lt 2
                _cp_die "usage: claude-profile use <name>"
                return 1
            end
            set -l name $argv[2]
            _cp_validate_name $name; or return 1
            set -l dir "$_CP_DATA/$name"
            if not test -d "$dir"
                _cp_die "profile '$name' does not exist. Create it with: claude-profile create $name"
                return 1
            end
            set -gx CLAUDE_CONFIG_DIR "$dir"
            echo "Switched to profile: $name"

        case create
            if test (count $argv) -lt 2
                _cp_die "usage: claude-profile create <name>"
                return 1
            end
            set -l name $argv[2]
            _cp_validate_name $name; or return 1
            set -l dir "$_CP_DATA/$name"
            if test -d "$dir"
                _cp_die "profile '$name' already exists"
                return 1
            end
            mkdir -p "$dir"
            echo "Created profile: $name"
            echo "Config directory: $dir"

        case list ls
            if not test -d "$_CP_DATA"
                echo "No profiles found. Create one with: claude-profile create <name>"
                return 0
            end
            set -l cur_default ""
            if test -f "$def_file"
                set cur_default (cat "$def_file")
            end
            set -l active ""
            if set -q CLAUDE_CONFIG_DIR
                if string match -q "$_CP_DATA/*" -- "$CLAUDE_CONFIG_DIR"
                    set active (basename "$CLAUDE_CONFIG_DIR")
                end
            end
            set -l found 0
            for entry in "$_CP_DATA"/*/
                test -d "$entry"; or continue
                set -l entry_name (basename "$entry")
                set found 1
                set -l is_default (test "$entry_name" = "$cur_default"; and echo 1; or echo 0)
                set -l is_active  (test "$entry_name" = "$active";      and echo 1; or echo 0)
                if test "$is_default" = 1 -a "$is_active" = 1
                    echo ">* $entry_name (default, active)"
                else if test "$is_default" = 1
                    echo " * $entry_name (default)"
                else if test "$is_active" = 1
                    echo ">  $entry_name (active)"
                else
                    echo "   $entry_name"
                end
            end
            if test "$found" = 0
                echo "No profiles found. Create one with: claude-profile create <name>"
            end

        case default
            if test (count $argv) -lt 2
                if test -f "$def_file"
                    set -l name (cat "$def_file")
                    if test -n "$name"
                        echo "$name"
                    else
                        _cp_die "default profile file is empty. Set one with: claude-profile default <name>"
                        return 1
                    end
                else
                    _cp_die "no default profile set. Set one with: claude-profile default <name>"
                    return 1
                end
                return 0
            end
            set -l name $argv[2]
            _cp_validate_name $name; or return 1
            set -l dir "$_CP_DATA/$name"
            if not test -d "$dir"
                _cp_die "profile '$name' does not exist. Create it with: claude-profile create $name"
                return 1
            end
            mkdir -p "$_CP_DATA"
            echo -n "$name" > "$def_file"
            echo "Default profile set to: $name"

        case which
            if test (count $argv) -ge 2
                set -l name $argv[2]
                _cp_validate_name $name; or return 1
                set -l dir "$_CP_DATA/$name"
                if not test -d "$dir"
                    _cp_die "profile '$name' does not exist."
                    return 1
                end
                echo "$dir"
            else
                if not test -f "$def_file"
                    _cp_die "no default profile set. Use: claude-profile default <name>"
                    return 1
                end
                set -l name (cat "$def_file")
                if test -z "$name"
                    _cp_die "default profile file is empty."
                    return 1
                end
                set -l dir "$_CP_DATA/$name"
                if not test -d "$dir"
                    _cp_die "profile '$name' does not exist."
                    return 1
                end
                echo "$dir"
            end

        case delete
            if test (count $argv) -lt 2
                _cp_die "usage: claude-profile delete <name>"
                return 1
            end
            set -l name $argv[2]
            _cp_validate_name $name; or return 1
            set -l dir "$_CP_DATA/$name"
            if not test -d "$dir"
                _cp_die "profile '$name' does not exist"
                return 1
            end
            read -l -P "Delete profile \"$name\" and all its data? [y/N] " confirm
            switch "$confirm"
                case y Y yes YES
                    rm -rf "$dir"
                    echo "Deleted profile: $name"
                    if test -f "$def_file"
                        set -l cur_default (cat "$def_file")
                        if test "$cur_default" = "$name"
                            rm -f "$def_file"
                            echo "Cleared default profile (was \"$name\")"
                        end
                    end
                    if set -q CLAUDE_CONFIG_DIR; and test "$CLAUDE_CONFIG_DIR" = "$dir"
                        set -e CLAUDE_CONFIG_DIR
                        echo "Cleared active profile (was \"$name\")"
                    end
                case '*'
                    echo "Cancelled."
            end

        case help -h --help
            echo "Usage: claude-profile [command] [args...]"
            echo ""
            echo "Commands:"
            echo "    (no command)            Show current profile status"
            echo "    use <name>              Switch session to the named profile"
            echo "    create <name>           Create a new profile"
            echo "    list, ls                List all profiles"
            echo "    default [name]          Get or set the default profile"
            echo "    which [name]            Show the resolved config directory path"
            echo "    delete <name>           Delete a profile"
            echo "    help, -h, --help        Show this help message"
            echo ""
            echo "The claude command automatically uses the default profile. Use"
            echo "'claude-profile use <name>' to override for the current session."

        case ''
            set -l active ""
            if set -q CLAUDE_CONFIG_DIR
                if string match -q "$_CP_DATA/*" -- "$CLAUDE_CONFIG_DIR"
                    set active (basename "$CLAUDE_CONFIG_DIR")
                end
            end
            if test -n "$active"
                echo "Active profile: $active"
                echo "Config directory: $CLAUDE_CONFIG_DIR"
            else if set -q CLAUDE_CONFIG_DIR
                echo "Active config directory: $CLAUDE_CONFIG_DIR (not a managed profile)"
            else
                echo "No active profile"
            end
            set -l cur_default ""
            if test -f "$def_file"
                set cur_default (cat "$def_file")
            end
            if test -n "$cur_default"
                echo "Default profile: $cur_default"
            else
                echo "No default profile set"
            end

        case '*'
            _cp_die "unknown command '$cmd'. Run 'claude-profile help' for usage."
            return 1
    end
end
