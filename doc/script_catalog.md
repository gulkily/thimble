# Thimble Script Catalog

This document catalogs the various scripts in the Thimble project, organized by their language implementations.

## Multi-Language Implementations

### Core Operations Scripts

#### `commit_files`
- **Purpose**: Handles file commit operations
- **Implementations**:
  - Perl: `template/perl/commit_files.pl`
  - PHP: `template/php/commit_files.php`
  - Python: `template/python3/commit_files.py`
  - Node.js: `template/node/commit_files.js`

#### `start_server`
- **Purpose**: Server initialization and startup
- **Implementations**:
  - Perl: `template/perl/start_server.pl`
  - PHP: `template/php/start_server.php`
  - Python: `template/python3/start_server.py`
  - Node.js: `template/node/start_server.js`

#### `github_update`
- **Purpose**: GitHub repository update operations
- **Implementations**:
  - Perl: `template/perl/github_update.pl`
  - PHP: `template/php/github_update.php`
  - Python: `template/python3/github_update.py`
  - Node.js: `template/node/github_update.js`

### Utility Scripts

#### `fix_line_endings`
- **Purpose**: Normalizes line endings in files
- **Implementations**:
  - Bash: `template/bash/fix_line_endings.sh`
  - Python: `template/python3/fix_line_endings.py`
  - Node.js: `template/node/fix_line_endings.js`

#### `fix_indent`
- **Purpose**: Corrects indentation in files
- **Implementations**:
  - Perl: `template/perl/fix_indent.pl`
  - Python: `template/python3/fix_indent.py`

## Single-Language Implementations

### Python-Specific Scripts
Located in `template/python3/`
- `colorize_text.py`: Text coloring utilities
- `file_size_scanner.py`: File system analysis tool
- `git_clean_repo.py`: Repository cleanup operations
- `git_filter_repo.py`: Repository filtering operations
- `git_repair.py`: Git repository repair utilities
- `stop_server.py`: Server shutdown operations

### Bash-Specific Scripts
Located in `template/bash/` and `bin/`
- `clean_dot_entries.sh`: Cleanup of dot entries
- `git_clean_repo.sh`: Repository cleanup script
- `git_nuke_history.sh`: Repository history reset
- `init_message_repo.sh`: Message repository initialization
- `upgrade_from_repo.sh`: Repository upgrade utilities

### JavaScript-Specific Scripts
Located in `template/js/`
- `chat.js`: Chat functionality implementation
- `reader.js`: Content reader implementation
- `script.js`: General frontend utilities

### Perl-Specific Scripts
Located in `template/perl/`
- `chat.html.pl`: Chat HTML generation

## Notes
- Core operations (commit, server, GitHub updates) are implemented across multiple languages for flexibility
- Python has the most unique scripts, particularly for Git operations
- Frontend functionality is exclusively implemented in JavaScript
- System-level operations are primarily implemented in Bash
- Each language implementation may have slight variations in functionality based on language-specific features and requirements
