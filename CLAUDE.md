# AI Kit - Developer & AI Context

## Project Context
This repository (`ai-kit`) is a marketplace for Claude Code plugins, including Agents, Skills, and Hooks. It is designed to automate team workflows and enhance the Claude Code experience.

## Architecture
- **Root**: Contains project-level configuration and documentation.
- **cli/**: Contains the `ai-kit.sh` CLI tool for managing plugins.
- **plugins/**: Source code for individual plugins (e.g., `doc-export`).
- **registry/**: `index.json` acts as the central registry for all available items.
- **commands/**: Markdown files defining slash commands (e.g., `/ai-kit`).

## Development Guidelines

### Coding Standards
- **Bash**: Use strictly for CLI tools. Ensure portability (macOS/Linux).
- **JSON**: Used for configuration and registry. Must be valid JSON.
- **Markdown**: Use for documentation and slash command definitions.

### Naming Conventions
- **Plugins**: Kebab-case (e.g., `doc-export`, `git-commit`).
- **Commands**: Kebab-case matching the plugin name where possible.

### Commit Messages
- **Language**: Korean (한글).
- **Format**: Clear and descriptive.
- **Example**: `feat: 문서 자동 저장 플러그인 추가`, `fix: CLI 설치 경로 버그 수정`

## Workflow: Adding a New Item
1.  **Implementation**: Create the plugin directory in `plugins/<name>`.
2.  **Registration**: Add the item entry to `registry/index.json`.
3.  **Documentation**:
    - Add a README or command file in `commands/`.
    - Update the main `README.md` list.
4.  **Verification**: Test locally using the CLI.

## Safety & Security Rules
The following actions are **STRICTLY PROHIBITED**:
- `rm -rf` commands.
- `sudo` usage.
- Modifying `.env` files directly.
- Modifying credential files (`*.pem`, `*.key`).
- Hardcoding secrets in code or commits.

## Tech Stack
- **Shell**: Bash/Zsh
- **Configuration**: JSON
- **Documentation**: Markdown
