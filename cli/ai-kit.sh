#!/bin/bash
# AI Kit - Claude Code Marketplace CLI
# 에이전트, 스킬, 훅을 관리하는 CLI 도구

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_ROOT="$(dirname "$SCRIPT_DIR")"
REGISTRY_FILE="${MARKETPLACE_ROOT}/registry/index.json"
TARGET_PROJECT="${CLAUDE_PROJECT_DIR:-.}"

# 사용법 출력
usage() {
    echo -e "${CYAN}AI Kit - Claude Code Marketplace CLI${NC}"
    echo ""
    echo "Usage: ai-kit <command> [type] [name]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  list [type]           사용 가능한 항목 목록 (agents|skills|hooks|tools|all)"
    echo "  install <type> <name> 항목 설치"
    echo "  remove <type> <name>  항목 제거"
    echo "  installed             설치된 항목 목록"
    echo "  info <type> <name>    항목 상세 정보"
    echo ""
    echo -e "${YELLOW}Types:${NC}"
    echo "  agents    서브에이전트"
    echo "  skills    스킬"
    echo "  hooks     훅"
    echo "  tools     도구"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ai-kit list                  # 전체 목록"
    echo "  ai-kit list hooks            # 훅 목록만"
    echo "  ai-kit install hooks doc-export"
    echo "  ai-kit remove skills git-commit"
}

# 레지스트리 로드 확인
check_registry() {
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        echo -e "${RED}Error: 레지스트리를 찾을 수 없습니다: $REGISTRY_FILE${NC}"
        exit 1
    fi
}

# author 표시 포맷
format_author() {
    local author="$1"
    if [[ "$author" == "Anthropic" ]]; then
        echo "(built-in)"
    else
        echo "($author)"
    fi
}

# 목록 출력
cmd_list() {
    local type="${1:-all}"
    check_registry

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  AI Kit Registry${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Agents
    if [[ "$type" == "all" || "$type" == "agents" ]]; then
        echo -e "${YELLOW}📦 Agents (서브에이전트)${NC}"
        echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
        jq -r '.agents[] | "\(.name)\t\(if .author == "Anthropic" then "(built-in)" else "(" + .author + ")" end)\t\(.description)"' "$REGISTRY_FILE" | \
        while IFS=$'\t' read -r name author desc; do
            printf "  %-20s %-14s %s\n" "$name" "$author" "$desc"
        done
        echo ""
    fi

    # Skills
    if [[ "$type" == "all" || "$type" == "skills" ]]; then
        echo -e "${GREEN}⚡ Skills (스킬)${NC}"
        echo -e "${GREEN}────────────────────────────────────────────────────────────────${NC}"
        jq -r '.skills[] | "\(.name)\t\(if .author == "Anthropic" then "(built-in)" else "(" + .author + ")" end)\t\(.description)"' "$REGISTRY_FILE" | \
        while IFS=$'\t' read -r name author desc; do
            printf "  %-20s %-14s %s\n" "$name" "$author" "$desc"
        done
        echo ""
    fi

    # Hooks
    if [[ "$type" == "all" || "$type" == "hooks" ]]; then
        echo -e "${BLUE}🔗 Hooks (훅)${NC}"
        echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
        jq -r '.hooks[] | "\(.name)\t\(if .author == "Anthropic" then "(built-in)" else "(" + .author + ")" end)\t\(.type // "custom")\t\(.description)"' "$REGISTRY_FILE" | \
        while IFS=$'\t' read -r name author htype desc; do
            if [[ "$htype" == "event" ]]; then
                printf "  %-20s %-14s ${GRAY}[event]${NC} %s\n" "$name" "$author" "$desc"
            else
                printf "  %-20s %-14s         %s\n" "$name" "$author" "$desc"
            fi
        done
        echo ""
    fi

    # Tools
    if [[ "$type" == "all" || "$type" == "tools" ]]; then
        echo -e "${GREEN}🔧 Tools (도구)${NC}"
        echo -e "${GREEN}────────────────────────────────────────────────────────────────${NC}"
        jq -r '.tools[] | "\(.name)\t\(if .author == "Anthropic" then "(built-in)" else "(" + .author + ")" end)\t\(.description)"' "$REGISTRY_FILE" | \
        while IFS=$'\t' read -r name author desc; do
            printf "  %-20s %-14s %s\n" "$name" "$author" "$desc"
        done
        echo ""
    fi
}

# 항목 설치
cmd_install() {
    local type="$1"
    local name="$2"

    if [[ -z "$type" || -z "$name" ]]; then
        echo -e "${RED}Error: type과 name을 지정해주세요${NC}"
        echo "Usage: ai-kit install <agents|skills|hooks> <name>"
        exit 1
    fi

    check_registry

    # 레지스트리에서 항목 찾기
    local item=$(jq -r ".${type}[] | select(.name == \"$name\")" "$REGISTRY_FILE")

    if [[ -z "$item" || "$item" == "null" ]]; then
        echo -e "${RED}Error: '$name'을(를) ${type}에서 찾을 수 없습니다${NC}"
        echo -e "${YELLOW}Hint: 'ai-kit list ${type}'로 사용 가능한 항목을 확인하세요${NC}"
        exit 1
    fi

    local version=$(echo "$item" | jq -r '.version')
    local author=$(echo "$item" | jq -r '.author')
    local description=$(echo "$item" | jq -r '.description')

    # built-in은 설치 불필요
    if [[ "$version" == "built-in" ]]; then
        echo -e "${YELLOW}'$name'은(는) Claude Code에 내장된 기능입니다.${NC}"
        echo -e "${GRAY}별도 설치 없이 바로 사용할 수 있습니다.${NC}"
        exit 0
    fi

    local source_path=$(echo "$item" | jq -r '.path')

    echo -e "${CYAN}Installing ${type}/${name} v${version}...${NC}"
    echo -e "  ${description}"
    echo -e "  ${GRAY}by ${author}${NC}"

    # 대상 디렉토리 설정
    local target_dir="${TARGET_PROJECT}/.claude"
    mkdir -p "$target_dir"

    case "$type" in
        agents)
            mkdir -p "${target_dir}/agents"
            local agent_file="${MARKETPLACE_ROOT}/registry/${source_path}/${name}.md"
            if [[ -f "$agent_file" ]]; then
                cp "$agent_file" "${target_dir}/agents/"
            else
                echo -e "${YELLOW}Warning: 에이전트 파일이 아직 없습니다. 레지스트리만 등록됨${NC}"
            fi
            ;;
        skills)
            mkdir -p "${target_dir}/skills"
            local skill_file="${MARKETPLACE_ROOT}/registry/${source_path}/${name}.md"
            if [[ -f "$skill_file" ]]; then
                cp "$skill_file" "${target_dir}/skills/"
            else
                echo -e "${YELLOW}Warning: 스킬 파일이 아직 없습니다. 레지스트리만 등록됨${NC}"
            fi
            ;;
        hooks)
            local hooks_file="${target_dir}/hooks.json"
            local event=$(echo "$item" | jq -r '.event // "Stop"')
            local matcher=$(echo "$item" | jq -r '.matcher // ""')

            # hooks.json 생성/수정
            if [[ -f "$hooks_file" ]]; then
                local temp_file=$(mktemp)
                jq --arg event "$event" \
                   'if .hooks[$event] == null then .hooks[$event] = [] else . end' \
                   "$hooks_file" > "$temp_file"
                jq --arg event "$event" --arg name "$name" --arg matcher "$matcher" \
                   '.hooks[$event] += [{"type": "command", "matcher": $matcher, "command": "${CLAUDE_PROJECT_DIR}/.claude/scripts/'"$name"'.sh", "_installed_by": "ai-kit", "_name": $name}]' \
                   "$temp_file" > "${temp_file}.2"
                mv "${temp_file}.2" "$hooks_file"
                rm -f "$temp_file"
            else
                cat > "$hooks_file" << EOF
{
  "hooks": {
    "$event": [
      {
        "type": "command",
        "matcher": "$matcher",
        "command": "\${CLAUDE_PROJECT_DIR}/.claude/scripts/${name}.sh",
        "_installed_by": "ai-kit",
        "_name": "$name"
      }
    ]
  }
}
EOF
            fi

            # 스크립트 복사
            mkdir -p "${target_dir}/scripts"
            local script_file="${MARKETPLACE_ROOT}/registry/${source_path}/${name}.sh"
            if [[ -f "$script_file" ]]; then
                cp "$script_file" "${target_dir}/scripts/${name}.sh"
                chmod +x "${target_dir}/scripts/${name}.sh"
            elif [[ "$name" == "doc-export" && -f "${MARKETPLACE_ROOT}/plugins/doc-export/scripts/export-doc.sh" ]]; then
                cp "${MARKETPLACE_ROOT}/plugins/doc-export/scripts/export-doc.sh" "${target_dir}/scripts/${name}.sh"
                chmod +x "${target_dir}/scripts/${name}.sh"
            else
                echo -e "${YELLOW}Warning: 스크립트 파일이 없습니다. 직접 생성해주세요: ${target_dir}/scripts/${name}.sh${NC}"
            fi
            ;;
    esac

    # 설치 기록 저장
    local installed_file="${target_dir}/.installed.json"
    if [[ -f "$installed_file" ]]; then
        local temp_file=$(mktemp)
        jq --arg type "$type" --arg name "$name" --arg version "$version" --arg author "$author" \
           'if .[$type] == null then .[$type] = {} else . end | .[$type][$name] = {"version": $version, "author": $author, "installedAt": "'"$(date '+%Y-%m-%d %H:%M:%S')"'"}' \
           "$installed_file" > "$temp_file"
        mv "$temp_file" "$installed_file"
    else
        cat > "$installed_file" << EOF
{
  "$type": {
    "$name": {
      "version": "$version",
      "author": "$author",
      "installedAt": "$(date '+%Y-%m-%d %H:%M:%S')"
    }
  }
}
EOF
    fi

    echo -e "${GREEN}✓ ${name} 설치 완료${NC}"
}

# 항목 제거
cmd_remove() {
    local type="$1"
    local name="$2"

    if [[ -z "$type" || -z "$name" ]]; then
        echo -e "${RED}Error: type과 name을 지정해주세요${NC}"
        exit 1
    fi

    local target_dir="${TARGET_PROJECT}/.claude"
    local installed_file="${target_dir}/.installed.json"

    echo -e "${YELLOW}Removing ${type}/${name}...${NC}"

    case "$type" in
        agents)
            rm -f "${target_dir}/agents/${name}.md"
            ;;
        skills)
            rm -f "${target_dir}/skills/${name}.md"
            ;;
        hooks)
            local hooks_file="${target_dir}/hooks.json"
            if [[ -f "$hooks_file" ]]; then
                local temp_file=$(mktemp)
                jq --arg name "$name" \
                   '.hooks |= with_entries(.value |= map(select(._name != $name)))' \
                   "$hooks_file" > "$temp_file"
                mv "$temp_file" "$hooks_file"
            fi
            rm -f "${target_dir}/scripts/${name}.sh"
            ;;
    esac

    # 설치 기록에서 제거
    if [[ -f "$installed_file" ]]; then
        local temp_file=$(mktemp)
        jq --arg type "$type" --arg name "$name" 'del(.[$type][$name])' "$installed_file" > "$temp_file"
        mv "$temp_file" "$installed_file"
    fi

    echo -e "${GREEN}✓ ${name} 제거 완료${NC}"
}

# 설치된 항목 목록
cmd_installed() {
    local installed_file="${TARGET_PROJECT}/.claude/.installed.json"

    if [[ ! -f "$installed_file" ]]; then
        echo -e "${YELLOW}설치된 항목이 없습니다${NC}"
        exit 0
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  설치된 항목 (${TARGET_PROJECT})${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    for type in agents skills hooks; do
        local items=$(jq -r ".${type} // {} | keys[]" "$installed_file" 2>/dev/null)
        if [[ -n "$items" ]]; then
            case "$type" in
                agents) echo -e "${YELLOW}📦 Agents${NC}" ;;
                skills) echo -e "${GREEN}⚡ Skills${NC}" ;;
                hooks)  echo -e "${BLUE}🔗 Hooks${NC}" ;;
            esac
            echo "$items" | while read name; do
                local version=$(jq -r ".${type}.\"$name\".version" "$installed_file")
                local author=$(jq -r ".${type}.\"$name\".author // \"unknown\"" "$installed_file")
                local installed_at=$(jq -r ".${type}.\"$name\".installedAt" "$installed_file")
                printf "  %-20s v%-8s (%s) %s\n" "$name" "$version" "$author" "$installed_at"
            done
            echo ""
        fi
    done
}

# 항목 상세 정보
cmd_info() {
    local type="$1"
    local name="$2"

    if [[ -z "$type" || -z "$name" ]]; then
        echo -e "${RED}Error: type과 name을 지정해주세요${NC}"
        exit 1
    fi

    check_registry

    local item=$(jq ".${type}[] | select(.name == \"$name\")" "$REGISTRY_FILE")

    if [[ -z "$item" || "$item" == "null" ]]; then
        echo -e "${RED}Error: '$name'을(를) 찾을 수 없습니다${NC}"
        exit 1
    fi

    local author=$(echo "$item" | jq -r '.author')
    local version=$(echo "$item" | jq -r '.version')

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [[ "$version" == "built-in" ]]; then
        echo -e "  ${GRAY}(built-in)${NC} Claude Code 내장 기능"
    else
        echo -e "  ${GREEN}($author)${NC}"
    fi
    echo ""
    echo "$item" | jq -r 'to_entries | map(select(.key != "author")) | map("  \(.key): \(.value | if type == "array" then (. | join(", ")) else . end)") | .[]'
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 메인
main() {
    local command="${1:-help}"

    case "$command" in
        list)
            cmd_list "$2"
            ;;
        install)
            cmd_install "$2" "$3"
            ;;
        remove|uninstall)
            cmd_remove "$2" "$3"
            ;;
        installed)
            cmd_installed
            ;;
        info)
            cmd_info "$2" "$3"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            usage
            exit 1
            ;;
    esac
}

main "$@"
