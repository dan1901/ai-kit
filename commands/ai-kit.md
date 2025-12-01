---
description: AI Kit 마켓플레이스 관리 (에이전트/스킬/훅)
---

# AI Kit Marketplace 관리자

사용자가 에이전트, 스킬, 훅을 검색하고 설치/제거할 수 있도록 도와주세요.

## 사용 가능한 작업

### 1. 목록 보기
레지스트리에 등록된 항목을 보여줍니다.

```bash
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh list
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh list agents
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh list skills
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh list hooks
```

### 2. 설치
```bash
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh install <type> <name>
# 예: ai-kit.sh install hooks doc-export
```

### 3. 제거
```bash
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh remove <type> <name>
```

### 4. 설치된 항목 확인
```bash
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh installed
```

### 5. 상세 정보
```bash
${CLAUDE_PLUGIN_ROOT}/cli/ai-kit.sh info <type> <name>
```

## 진행 방법

1. 먼저 `list` 명령으로 사용 가능한 항목을 보여주세요
2. 사용자에게 무엇을 하고 싶은지 물어보세요:
   - 설치할 항목 선택
   - 제거할 항목 선택
   - 상세 정보 확인
3. 선택에 따라 적절한 명령을 실행하세요
4. 결과를 알려주세요

## 항목 유형 설명

| 유형 | 설명 | 용도 |
|------|------|------|
| **agents** | 서브에이전트 | 특정 작업에 특화된 AI 에이전트 |
| **skills** | 스킬 | Claude가 자동으로 사용하는 기능 |
| **hooks** | 훅 | 이벤트 발생 시 자동 실행되는 스크립트 |

## 대화 예시

```
사용자: /ai-kit
Claude: 사용 가능한 항목을 확인해볼게요.
        [list 명령 실행]

        설치하고 싶은 항목이 있나요?
        1. 에이전트 설치
        2. 스킬 설치
        3. 훅 설치
        4. 설치된 항목 확인

사용자: 3
Claude: 사용 가능한 훅 목록입니다:
        - doc-export: 세션 종료 시 문서 자동 저장
        - pre-commit-check: 커밋 전 코드 검증

        어떤 훅을 설치할까요?

사용자: doc-export
Claude: [install 명령 실행]
        ✓ doc-export 훅이 설치되었습니다!
```
