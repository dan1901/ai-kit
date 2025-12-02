#!/bin/bash
# 작업 산출물 자동 저장 스크립트
# Stop 훅에서 호출됨

set -e

# 설정 파일 경로
CONFIG_FILE="${CLAUDE_PROJECT_DIR}/.claude/doc-export.json"
DEFAULT_OUTPUT_DIR="${CLAUDE_PROJECT_DIR}/docs/outputs"

# 설정 로드
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        echo '{}'
    fi
}

# 기본 파일 저장 (항상 실행)
save_to_file() {
    local output_dir="$1"
    local content="$2"
    local title="$3"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local filename="${timestamp}_${title}.md"

    mkdir -p "$output_dir"
    echo -e "$content" > "${output_dir}/${filename}"
    echo "📄 파일 저장 완료: ${output_dir}/${filename}"
}

# Obsidian 저장 (로컬 Vault 경로에 저장)
save_to_obsidian() {
    local vault_path="$1"
    local content="$2"
    local title="$3"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local filename="${timestamp}_${title}.md"

    # 기본 Obsidian Vault 경로 (설정 없으면 기본값 사용)
    if [[ -z "$vault_path" ]]; then
        vault_path="$HOME/Documents/Obsidian Vault"
    fi

    if [[ ! -d "$vault_path" ]]; then
        echo "⚠️ Obsidian Vault 경로가 존재하지 않습니다: $vault_path"
        return 1
    fi

    # 프로젝트명으로 폴더 생성 (Vault 내 프로젝트 폴더)
    local project_name=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
    local project_folder="${vault_path}/${project_name}"
    mkdir -p "$project_folder"

    # Obsidian용 메타데이터 추가
    local obsidian_content="---
created: $(date +"%Y-%m-%d %H:%M:%S")
tags: [claude, session]
---

${content}"

    echo -e "$obsidian_content" > "${project_folder}/${filename}"
    echo "🗃️ Obsidian 저장 완료: ${project_folder}/${filename}"
}

# Notion 저장
save_to_notion() {
    local api_key="$1"
    local database_id="$2"
    local title="$3"
    local content="$4"

    if [[ -z "$api_key" ]]; then
        echo "⚠️ Notion API 키가 설정되지 않았습니다."
        return 1
    fi

    if [[ -z "$database_id" ]]; then
        echo "⚠️ Notion 데이터베이스 ID가 설정되지 않았습니다."
        return 1
    fi

    # Notion API 호출
    response=$(curl -s -X POST "https://api.notion.com/v1/pages" \
        -H "Authorization: Bearer ${api_key}" \
        -H "Content-Type: application/json" \
        -H "Notion-Version: 2022-06-28" \
        -d "{
            \"parent\": { \"database_id\": \"${database_id}\" },
            \"properties\": {
                \"Name\": {
                    \"title\": [{ \"text\": { \"content\": \"${title}\" } }]
                }
            },
            \"children\": [
                {
                    \"object\": \"block\",
                    \"type\": \"paragraph\",
                    \"paragraph\": {
                        \"rich_text\": [{ \"text\": { \"content\": \"${content:0:2000}\" } }]
                    }
                }
            ]
        }")

    if echo "$response" | grep -q '"id"'; then
        echo "📝 Notion 저장 완료"
    else
        echo "❌ Notion 저장 실패: $response"
        return 1
    fi
}

# 메인 로직
main() {
    # stdin으로 훅 데이터 수신
    local hook_data=$(cat)

    # 설정 로드
    local config=$(load_config)
    local output_dir=$(echo "$config" | jq -r ".localPath // \"$DEFAULT_OUTPUT_DIR\"")
    local extra_export=$(echo "$config" | jq -r '.extraExport // "none"')
    local obsidian_path=$(echo "$config" | jq -r '.obsidianVaultPath // empty')
    local notion_key=$(echo "$config" | jq -r '.notionApiKey // empty')
    local notion_db=$(echo "$config" | jq -r '.notionDatabaseId // empty')

    # 세션 정보 추출
    local session_id=$(echo "$hook_data" | jq -r '.session_id // "unknown"')
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local title="session_${session_id}"
    local content="# 작업 세션 기록

- 시간: ${timestamp}
- 세션 ID: ${session_id}

## 작업 내용

(세션 요약은 별도 구현 필요)"

    # 1. 기본: 항상 파일로 저장
    save_to_file "$output_dir" "$content" "$title"

    # 2. 추가 저장 옵션
    case "$extra_export" in
        "obsidian")
            save_to_obsidian "$obsidian_path" "$content" "$title"
            ;;
        "notion")
            save_to_notion "$notion_key" "$notion_db" "$title" "$content"
            ;;
        "none"|"")
            # 추가 저장 없음
            ;;
        *)
            echo "⚠️ 알 수 없는 추가 저장 옵션: $extra_export"
            ;;
    esac
}

main "$@"
