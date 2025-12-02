---
description: 테스트 코드 자동 생성
allowed-tools: Glob, Grep, Read, Write, Edit, Bash, AskUserQuestion
---

# 테스트 코드 생성기

사용자의 프로젝트에 맞는 테스트 코드를 생성합니다.

## 입력 파라미터

사용자가 `/test-generator [LANGUAGE]` 형식으로 호출할 수 있습니다.
- LANGUAGE가 지정되지 않으면 프로젝트를 분석하여 자동 감지

## 진행 순서

### 1단계: 프로젝트 언어 감지

다음 파일들을 확인하여 프로젝트 언어를 감지하세요:

| 파일 | 언어 | 테스트 프레임워크 |
|------|------|------------------|
| `package.json` | JavaScript/TypeScript | Jest, Vitest, Mocha |
| `tsconfig.json` | TypeScript | Jest, Vitest |
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python | pytest, unittest |
| `go.mod` | Go | testing (built-in) |
| `Cargo.toml` | Rust | cargo test (built-in) |
| `pom.xml`, `build.gradle` | Java | JUnit |
| `*.csproj` | C# | xUnit, NUnit |

### 2단계: 기존 테스트 설정 확인

프로젝트에 이미 테스트 설정이 있는지 확인:
- `package.json`의 `devDependencies`에서 테스트 라이브러리 확인
- `jest.config.*`, `vitest.config.*`, `pytest.ini`, `pyproject.toml [tool.pytest]` 등

### 3단계: 사용자에게 질문

AskUserQuestion 도구를 사용하여 다음을 확인:

1. **테스트 대상**: 어떤 파일/함수/클래스를 테스트할지
   - 특정 파일 선택
   - 특정 디렉토리 전체
   - 최근 수정된 파일

2. **테스트 유형**:
   - Unit Test (단위 테스트)
   - Integration Test (통합 테스트)
   - E2E Test (End-to-End 테스트)

3. **테스트 프레임워크** (감지된 언어에 맞게):
   - JavaScript/TypeScript: Jest / Vitest / Mocha
   - Python: pytest / unittest
   - Go: testing
   - 기타: 해당 언어의 표준 프레임워크

### 4단계: 테스트 코드 생성

선택된 옵션에 따라:

1. 대상 파일을 읽어 구조 파악 (함수, 클래스, 메서드)
2. 각 함수/메서드에 대한 테스트 케이스 생성:
   - 정상 케이스 (happy path)
   - 엣지 케이스 (edge cases)
   - 에러 케이스 (error handling)
3. 테스트 파일 생성 (기존 컨벤션 따름)

## 테스트 파일 명명 규칙

| 언어 | 컨벤션 |
|------|--------|
| JavaScript/TypeScript | `*.test.ts`, `*.spec.ts`, `__tests__/*.ts` |
| Python | `test_*.py`, `*_test.py` |
| Go | `*_test.go` |
| Rust | 같은 파일 내 `#[cfg(test)]` 모듈 |
| Java | `*Test.java` |

## 예시 대화

```
Q: 테스트할 대상을 선택해주세요.
   1. 특정 파일 선택
   2. src/ 디렉토리 전체
   3. 최근 수정된 파일

A: 1

Q: 테스트할 파일 경로를 입력해주세요.

A: src/utils/calculator.ts

Q: 테스트 유형을 선택해주세요.
   1. Unit Test (단위 테스트)
   2. Integration Test (통합 테스트)

A: 1

Q: 테스트 프레임워크를 선택해주세요.
   1. Jest
   2. Vitest

A: 2
```

## 생성 예시

### TypeScript + Vitest

```typescript
// src/utils/calculator.test.ts
import { describe, it, expect } from 'vitest';
import { add, subtract, multiply, divide } from './calculator';

describe('Calculator', () => {
  describe('add', () => {
    it('should add two positive numbers', () => {
      expect(add(2, 3)).toBe(5);
    });

    it('should handle negative numbers', () => {
      expect(add(-1, 1)).toBe(0);
    });
  });

  describe('divide', () => {
    it('should divide two numbers', () => {
      expect(divide(10, 2)).toBe(5);
    });

    it('should throw error when dividing by zero', () => {
      expect(() => divide(10, 0)).toThrow('Division by zero');
    });
  });
});
```

### Python + pytest

```python
# tests/test_calculator.py
import pytest
from src.utils.calculator import add, subtract, multiply, divide

class TestCalculator:
    def test_add_positive_numbers(self):
        assert add(2, 3) == 5

    def test_add_negative_numbers(self):
        assert add(-1, 1) == 0

    def test_divide_numbers(self):
        assert divide(10, 2) == 5

    def test_divide_by_zero_raises_error(self):
        with pytest.raises(ZeroDivisionError):
            divide(10, 0)
```

## 주의사항

- 기존 테스트 파일이 있으면 덮어쓰지 않고 확인 요청
- 프로젝트의 기존 테스트 스타일/컨벤션을 따름
- Mock이 필요한 경우 적절한 모킹 라이브러리 사용 제안
