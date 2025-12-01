import argparse
import json
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path


# Colors for terminal output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
CYAN = '\033[0;36m'
GRAY = '\033[0;90m'
NC = '\033[0m'

def get_package_root():
    """Returns the root directory of the package resources."""
    # When installed, we need to find where the data files are.
    # For simplicity in this script, we'll assume we can find them relative to this file
    # or use pkg_resources if needed.
    # However, since we want to support editable installs and regular installs,
    # let's try to find the 'registry' directory relative to the package root.
    
    # Check if running from source (development)
    current_file = Path(__file__).resolve()
    # src/ai_kit/cli.py -> src/ai_kit -> src -> root
    source_root = current_file.parent.parent.parent
    if (source_root / "registry").exists():
        return source_root
        
    # If installed, we might need to look elsewhere. 
    # But for now, let's assume the data files are packaged inside the package directory
    # if we used package_data correctly.
    # Actually, with the current pyproject.toml structure:
    # ai_kit = ["registry/**/*", "plugins/**/*"]
    # The files will be inside the site-packages/ai_kit directory?
    # No, usually package_data puts them inside the package dir.
    # Let's check relative to __file__.
    package_dir = current_file.parent
    if (package_dir / "registry").exists(): # If data is inside package
        return package_dir
        
    # Fallback: try to find it in sys.prefix (unlikely for this setup but good for some envs)
    return source_root

def get_registry_path(root_dir):
    # Try source location first
    reg_path = root_dir / "registry" / "index.json"
    if reg_path.exists():
        return reg_path
        
    # Try package location (if data files are inside ai_kit package)
    # This handles the case where setuptools installs data inside the package
    package_dir = Path(__file__).parent
    reg_path = package_dir / "registry" / "index.json"
    if reg_path.exists():
        return reg_path
        
    # If we can't find it directly, maybe we are in a weird install.
    # Let's fail gracefully later if we can't load it.
    return None

def load_registry(registry_file):
    if not registry_file or not registry_file.exists():
        print(f"{RED}Error: Registry not found.{NC}")
        sys.exit(1)
    with open(registry_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def format_author(author):
    if author == "Anthropic":
        return "(built-in)"
    return f"({author})"

def cmd_list(args, registry):
    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{CYAN}  AI Kit Registry{NC}")
    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print("")

    types_to_show = [args.type] if args.type != "all" else ["agents", "skills", "hooks", "tools"]

    if "agents" in types_to_show and "agents" in registry:
        print(f"{YELLOW}📦 Agents (서브에이전트){NC}")
        print(f"{YELLOW}────────────────────────────────────────────────────────────────{NC}")
        for agent in registry["agents"]:
            print(f"  {agent['name']:<20} {format_author(agent['author']):<14} {agent['description']}")
        print("")

    if "skills" in types_to_show and "skills" in registry:
        print(f"{GREEN}⚡ Skills (스킬){NC}")
        print(f"{GREEN}────────────────────────────────────────────────────────────────{NC}")
        for skill in registry["skills"]:
            print(f"  {skill['name']:<20} {format_author(skill['author']):<14} {skill['description']}")
        print("")

    if "hooks" in types_to_show and "hooks" in registry:
        print(f"{BLUE}🔗 Hooks (훅){NC}")
        print(f"{BLUE}────────────────────────────────────────────────────────────────{NC}")
        for hook in registry["hooks"]:
            htype = hook.get("type", "custom")
            type_str = f"{GRAY}[event]{NC}" if htype == "event" else "       "
            print(f"  {hook['name']:<20} {format_author(hook['author']):<14} {type_str} {hook['description']}")
        print("")
        
    if "tools" in types_to_show and "tools" in registry:
        print(f"{GREEN}🔧 Tools (도구){NC}")
        print(f"{GREEN}────────────────────────────────────────────────────────────────{NC}")
        for tool in registry["tools"]:
            print(f"  {tool['name']:<20} {format_author(tool['author']):<14} {tool['description']}")
        print("")

def cmd_install(args, registry, root_dir):
    item_type = args.type
    name = args.name
    
    # Find item
    items = registry.get(item_type, [])
    item = next((i for i in items if i["name"] == name), None)
    
    if not item:
        print(f"{RED}Error: '{name}' not found in {item_type}{NC}")
        print(f"{YELLOW}Hint: Check available items with 'ai-kit list {item_type}'{NC}")
        sys.exit(1)
        
    version = item.get("version")
    author = item.get("author")
    description = item.get("description")
    
    if version == "built-in":
        print(f"{YELLOW}'{name}' is a built-in feature of Claude Code.{NC}")
        print(f"{GRAY}No installation required.{NC}")
        sys.exit(0)
        
    source_path = item.get("path")
    
    print(f"{CYAN}Installing {item_type}/{name} v{version}...{NC}")
    print(f"  {description}")
    print(f"  {GRAY}by {author}{NC}")
    
    # Target directory
    claude_project_dir = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    target_dir = Path(claude_project_dir) / ".claude"
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # Locate source file
    # We need to find where the source files are.
    # In dev: root/registry/path/name.md
    # In package: package_dir/registry/path/name.md (if included)
    
    # Try to find the file relative to registry file location
    # If registry file is at X/registry/index.json, then source is at X/registry/source_path/...
    # But wait, source_path in json is like "hooks/doc-export" or "agents/code-reviewer"
    # And the file structure is root/registry/hooks/doc-export/doc-export.md ??
    # Let's check the bash script logic:
    # agent_file="${MARKETPLACE_ROOT}/registry/${source_path}/${name}.md"
    
    # So we need the root of the registry data.
    registry_root = get_registry_path(root_dir).parent.parent # registry/index.json -> registry -> root
    # Actually get_registry_path returns the full path to index.json
    # So .parent is 'registry' folder.
    registry_base = get_registry_path(root_dir).parent
    
    # Also need to handle plugins folder for scripts if they are there.
    # MARKETPLACE_ROOT/plugins/...
    plugins_root = registry_base.parent / "plugins"
    
    if item_type == "agents":
        (target_dir / "agents").mkdir(exist_ok=True)
        src_file = registry_base / source_path / f"{name}.md"
        if src_file.exists():
            shutil.copy2(src_file, target_dir / "agents")
        else:
            print(f"{YELLOW}Warning: Agent file not found. Registry entry only.{NC}")
            
    elif item_type == "skills":
        skills_dir = target_dir / "skills"
        skills_dir.mkdir(exist_ok=True)
        
        src_path = registry_base / source_path
        skill_md = src_path / f"{name}.md"
        
        if src_path.is_dir() and skill_md.exists():
            # Multi-file skill (directory)
            dest_dir = skills_dir / name
            if dest_dir.exists():
                shutil.rmtree(dest_dir)
            shutil.copytree(src_path, dest_dir)
            print(f"  Installed to {dest_dir}")
        else:
            # Single file skill (legacy or simple)
            # Try to find the file directly if source_path points to a file
            # or if it's inside a directory but we only want the file?
            # Existing logic assumed: registry/path/name.md
            src_file = src_path / f"{name}.md"
            if src_file.exists():
                shutil.copy2(src_file, skills_dir)
            else:
                print(f"{YELLOW}Warning: Skill file not found. Registry entry only.{NC}")
            
    elif item_type == "hooks":
        hooks_file = target_dir / "hooks.json"
        event = item.get("event", "Stop")
        matcher = item.get("matcher", "")
        
        # Update hooks.json
        hooks_data = {"hooks": {}}
        if hooks_file.exists():
            with open(hooks_file, 'r') as f:
                try:
                    hooks_data = json.load(f)
                except json.JSONDecodeError:
                    pass
        
        if event not in hooks_data["hooks"]:
            hooks_data["hooks"][event] = []
            
        # Check if already exists to avoid duplicates? Bash script appends.
        # But bash script logic was: if null then [], then += [...]
        # We should probably check if we are updating or adding.
        # For simplicity, let's append like the bash script.
        
        new_hook = {
            "type": "command",
            "matcher": matcher,
            "command": f"${{CLAUDE_PROJECT_DIR}}/.claude/scripts/{name}.sh",
            "_installed_by": "ai-kit",
            "_name": name
        }
        
        # Remove existing hook with same name if any (update)
        hooks_data["hooks"][event] = [h for h in hooks_data["hooks"][event] if h.get("_name") != name]
        hooks_data["hooks"][event].append(new_hook)
        
        with open(hooks_file, 'w') as f:
            json.dump(hooks_data, f, indent=2)
            
        # Copy script
        (target_dir / "scripts").mkdir(exist_ok=True)
        
        # Script location logic from bash:
        # 1. registry/path/name.sh
        # 2. plugins/doc-export/scripts/export-doc.sh (special case for doc-export)
        
        script_src = registry_base / source_path / f"{name}.sh"
        
        # Special case handling matching bash script
        if name == "doc-export":
             # plugins/doc-export/scripts/export-doc.sh
             # We need to find where 'plugins' dir is.
             # If we are in a package, it should be included.
             special_src = plugins_root / "doc-export" / "scripts" / "export-doc.sh"
             if special_src.exists():
                 script_src = special_src
        
        if script_src.exists():
            dest_script = target_dir / "scripts" / f"{name}.sh"
            shutil.copy2(script_src, dest_script)
            os.chmod(dest_script, 0o755)
        else:
            print(f"{YELLOW}Warning: Script file not found. Please create: .claude/scripts/{name}.sh{NC}")

    # Update installed.json
    installed_file = target_dir / ".installed.json"
    installed_data = {}
    if installed_file.exists():
        with open(installed_file, 'r') as f:
            try:
                installed_data = json.load(f)
            except:
                pass
    
    if item_type not in installed_data:
        installed_data[item_type] = {}
        
    installed_data[item_type][name] = {
        "version": version,
        "author": author,
        "installedAt": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }
    
    with open(installed_file, 'w') as f:
        json.dump(installed_data, f, indent=2)
        
    print(f"{GREEN}✓ {name} installed successfully{NC}")

def cmd_remove(args, root_dir):
    item_type = args.type
    name = args.name
    
    claude_project_dir = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    target_dir = Path(claude_project_dir) / ".claude"
    
    print(f"{YELLOW}Removing {item_type}/{name}...{NC}")
    
    if item_type == "agents":
        (target_dir / "agents" / f"{name}.md").unlink(missing_ok=True)
    elif item_type == "skills":
        skill_path = target_dir / "skills" / name
        skill_md = target_dir / "skills" / f"{name}.md"
        
        if skill_path.is_dir():
            shutil.rmtree(skill_path)
        else:
            skill_md.unlink(missing_ok=True)
    elif item_type == "hooks":
        hooks_file = target_dir / "hooks.json"
        if hooks_file.exists():
            with open(hooks_file, 'r') as f:
                data = json.load(f)
            
            # Remove hooks with matching _name
            for event in data.get("hooks", {}):
                data["hooks"][event] = [h for h in data["hooks"][event] if h.get("_name") != name]
                
            with open(hooks_file, 'w') as f:
                json.dump(data, f, indent=2)
                
        (target_dir / "scripts" / f"{name}.sh").unlink(missing_ok=True)
        
    # Update installed.json
    installed_file = target_dir / ".installed.json"
    if installed_file.exists():
        with open(installed_file, 'r') as f:
            data = json.load(f)
        
        if item_type in data and name in data[item_type]:
            del data[item_type][name]
            
        with open(installed_file, 'w') as f:
            json.dump(data, f, indent=2)
            
    print(f"{GREEN}✓ {name} removed{NC}")

def cmd_installed(args):
    claude_project_dir = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    installed_file = Path(claude_project_dir) / ".claude" / ".installed.json"
    
    if not installed_file.exists():
        print(f"{YELLOW}No items installed.{NC}")
        return

    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{CYAN}  Installed Items ({claude_project_dir}){NC}")
    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print("")
    
    with open(installed_file, 'r') as f:
        data = json.load(f)
        
    for item_type in ["agents", "skills", "hooks"]:
        items = data.get(item_type, {})
        if items:
            if item_type == "agents": print(f"{YELLOW}📦 Agents{NC}")
            elif item_type == "skills": print(f"{GREEN}⚡ Skills{NC}")
            elif item_type == "hooks": print(f"{BLUE}🔗 Hooks{NC}")
            
            for name, info in items.items():
                print(f"  {name:<20} v{info.get('version', '?'):<8} ({info.get('author', 'unknown')}) {info.get('installedAt', '')}")
            print("")

def cmd_info(args, registry):
    item_type = args.type
    name = args.name
    
    items = registry.get(item_type, [])
    item = next((i for i in items if i["name"] == name), None)
    
    if not item:
        print(f"{RED}Error: '{name}' not found{NC}")
        sys.exit(1)
        
    version = item.get("version")
    author = item.get("author")
    
    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    if version == "built-in":
        print(f"  {GRAY}(built-in){NC} Claude Code Feature")
    else:
        print(f"  {GREEN}({author}){NC}")
    print("")
    
    for k, v in item.items():
        if k != "author":
            val_str = ", ".join(v) if isinstance(v, list) else v
            print(f"  {k}: {val_str}")
    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")

def main():
    parser = argparse.ArgumentParser(description="AI Kit - Claude Code Marketplace CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # List
    list_parser = subparsers.add_parser("list", help="List available items")
    list_parser.add_argument("type", nargs="?", default="all", choices=["all", "agents", "skills", "hooks", "tools"], help="Type of items to list")
    
    # Install
    install_parser = subparsers.add_parser("install", help="Install an item")
    install_parser.add_argument("type", choices=["agents", "skills", "hooks"], help="Type of item")
    install_parser.add_argument("name", help="Name of item")
    
    # Remove
    remove_parser = subparsers.add_parser("remove", help="Remove an item")
    remove_parser.add_argument("type", choices=["agents", "skills", "hooks"], help="Type of item")
    remove_parser.add_argument("name", help="Name of item")
    
    # Installed
    subparsers.add_parser("installed", help="List installed items")
    
    # Info
    info_parser = subparsers.add_parser("info", help="Show item details")
    info_parser.add_argument("type", choices=["agents", "skills", "hooks", "tools"], help="Type of item")
    info_parser.add_argument("name", help="Name of item")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return

    root_dir = get_package_root()
    registry_file = get_registry_path(root_dir)
    
    if args.command in ["list", "install", "info"]:
        registry = load_registry(registry_file)
        
    if args.command == "list":
        cmd_list(args, registry)
    elif args.command == "install":
        cmd_install(args, registry, root_dir)
    elif args.command == "remove":
        cmd_remove(args, root_dir)
    elif args.command == "installed":
        cmd_installed(args)
    elif args.command == "info":
        cmd_info(args, registry)

if __name__ == "__main__":
    main()
