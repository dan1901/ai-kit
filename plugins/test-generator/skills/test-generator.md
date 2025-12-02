---
description: 테스트 코드 자동 생성
---

# 테스트 코드 생성기

프로젝트에 맞는 테스트 코드를 자동으로 생성합니다.

## 프로젝트 분석

먼저 다음 파일들을 확인하여 프로젝트 환경을 파악하세요:

1. **JavaScript/TypeScript**: `package.json`, `tsconfig.json`
2. **Python**: `pyproject.toml`, `setup.py`, `requirements.txt`
3. **Go**: `go.mod`
4. **Rust**: `Cargo.toml`
5. **Java**: `pom.xml`, `build.gradle`

## 테스트 프레임워크 감지

기존 설정 파일 확인:
- `jest.config.*`, `vitest.config.*` (JS/TS)
- `pytest.ini`, `pyproject.toml [tool.pytest]` (Python)
- `*_test.go` 패턴 (Go)

## 사용자 질문 순서

AskUserQuestion을 사용하여 확인:

### 질문 1: 테스트 대상
```
header: "테스트 대상"
question: "어떤 것을 테스트하시겠습니까?"
options:
  - label: "특정 파일"
    description: "파일 경로를 직접 지정"
  - label: "디렉토리 전체"
    description: "src/ 등 디렉토리 내 모든 파일"
  - label: "최근 수정 파일"
    description: "최근 변경된 파일들"
```

### 질문 2: 테스트 유형
```
header: "테스트 유형"
question: "어떤 유형의 테스트를 생성할까요?"
options:
  - label: "Unit Test"
    description: "개별 함수/메서드 단위 테스트"
  - label: "Integration Test"
    description: "모듈 간 통합 테스트"
  - label: "E2E Test"
    description: "전체 플로우 테스트"
```

### 질문 3: 테스트 프레임워크 (언어별)

**JavaScript/TypeScript:**
- Jest / Vitest / Mocha

**Python:**
- pytest / unittest

**Go:**
- testing (built-in)

## 테스트 생성 가이드라인

### 테스트 케이스 구성
1. **Happy Path**: 정상 입력에 대한 기대 결과
2. **Edge Cases**: 경계값, 빈 입력, null/undefined
3. **Error Cases**: 예외 상황, 잘못된 입력

### 파일 명명 규칙
| 언어 | 패턴 |
|------|------|
| TypeScript | `*.test.ts`, `*.spec.ts` |
| Python | `test_*.py` |
| Go | `*_test.go` |

### 코드 스타일
- 기존 프로젝트의 테스트 스타일 따르기
- describe/it 또는 class/method 패턴 일관성 유지
- 의미 있는 테스트 이름 작성

## 예시 출력

### Vitest (TypeScript)
```typescript
import { describe, it, expect } from 'vitest';
import { targetFunction } from './target';

describe('targetFunction', () => {
  it('should return expected result for valid input', () => {
    expect(targetFunction('input')).toBe('expected');
  });

  it('should handle empty input', () => {
    expect(targetFunction('')).toBe('');
  });

  it('should throw on invalid input', () => {
    expect(() => targetFunction(null)).toThrow();
  });
});
```

### pytest (Python)
```python
import pytest
from target import target_function

class TestTargetFunction:
    def test_valid_input(self):
        assert target_function('input') == 'expected'

    def test_empty_input(self):
        assert target_function('') == ''

    def test_invalid_input_raises(self):
        with pytest.raises(ValueError):
            target_function(None)
```

## 실행

1. 프로젝트 분석 실행
2. 사용자 질문으로 옵션 확인
3. 대상 파일 읽기
4. 테스트 코드 생성
5. 테스트 파일 작성
