---
description: 문서 저장 설정 구성
---

# 문서 저장 설정 도우미

사용자가 문서 저장 방식을 설정하도록 도와주세요.

## 저장 방식

```
기본: 항상 로컬 파일로 저장 (docs/outputs/)
      ↓
추가 옵션 선택:
  - none: 파일만 저장 (기본)
  - obsidian: Obsidian Vault에도 저장
  - notion: Notion에도 저장 (API 키 필요)
```

## 설정 항목

### 1. 기본 저장 경로
- 파일 저장 디렉토리 (기본: `./docs/outputs`)

### 2. 추가 저장 옵션 (선택)

**Obsidian 선택 시:**
- Obsidian Vault 경로 (기본: `~/Documents/Obsidian Vault`)
- `Claude` 폴더가 자동으로 생성됩니다

**Notion 선택 시:**
- Notion API 키 (https://www.notion.so/my-integrations 에서 생성)
- 대상 데이터베이스 ID

## 설정 파일 형식

`.claude/doc-export.json`:

```json
{
  "localPath": "./docs/outputs",
  "extraExport": "none | obsidian | notion",
  "obsidianVaultPath": "~/Documents/Obsidian Vault",
  "notionApiKey": "secret_xxx",
  "notionDatabaseId": "xxx-xxx-xxx"
}
```

## 진행 방법

1. 사용자에게 기본 파일 저장 경로를 확인 (기본값 사용 가능)
2. 추가 저장 옵션 선택 요청:
   - `none`: 파일만 저장
   - `obsidian`: Vault 경로 입력 (기본: ~/Documents/Obsidian Vault, Claude 폴더 자동 생성)
   - `notion`: API 키와 데이터베이스 ID 입력 받기
3. `.claude/doc-export.json` 파일 생성
4. Notion 선택 시 `.gitignore`에 설정 파일 추가 확인

## 예시 대화

```
Q: 추가 저장 옵션을 선택해주세요.
   1. 없음 (파일만 저장)
   2. Obsidian
   3. Notion

A: 2

Q: Obsidian Vault 경로를 입력해주세요. (기본: ~/Documents/Obsidian Vault)
   Claude 폴더는 자동으로 생성됩니다.

A: (Enter 입력 - 기본값 사용)
```

**중요**: Notion API 키는 민감 정보이므로 `.gitignore`에 `.claude/doc-export.json` 추가를 권장하세요.
