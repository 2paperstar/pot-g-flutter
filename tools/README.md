# API 채널 키 생성 도구

API 채널을 변경할 수 있는 검증된 키를 생성하는 도구입니다.

## 사용법

### 기본 사용

```bash
dart run tools/generate_api_channel_key.dart <channel> [secret]
```

### 예시

```bash
# 환경 변수로 시크릿 키 설정
export API_CHANNEL_KEY_SECRET=your-secret-key-here

# QA 채널 키 생성
dart run tools/generate_api_channel_key.dart qa

# 개발 채널 키 생성 (시크릿 키를 인자로 전달)
dart run tools/generate_api_channel_key.dart dev my-secret-key
```

## 키 형식

생성된 키는 다음 형식을 따릅니다:

```
channel:timestamp:signature
```

- `channel`: 채널 이름 (dev, qa, prod)
- `timestamp`: Unix timestamp (초 단위)
- `signature`: HMAC-SHA256 서명 (hex 인코딩)

## 보안

1. **시크릿 키 관리**: 시크릿 키는 환경 변수로 관리하거나 안전한 곳에 저장하세요.
2. **키 만료**: 생성된 키는 7일 후 만료됩니다.
3. **키 공유**: 생성된 키는 안전하게 전달하세요 (예: 암호화된 메시지, 안전한 채널).

## URL 형식

생성된 키를 사용하여 다음 형식의 URL을 만들 수 있습니다:

```
https://pot-g.gistory.me/test#key=channel:timestamp:signature
```

## 키 검증

앱에서 키를 받으면 다음을 검증합니다:

1. 키 형식 검증
2. 채널 이름 검증
3. 타임스탬프 만료 검증 (7일)
4. HMAC-SHA256 서명 검증

## 운영진 사용 가이드

1. 안전한 시크릿 키 생성:
   ```bash
   # 강력한 랜덤 시크릿 키 생성 (예시)
   openssl rand -hex 32
   ```

2. 환경 변수 설정:
   ```bash
   export API_CHANNEL_KEY_SECRET=생성된_시크릿_키
   ```

3. 키 생성:
   ```bash
   dart run tools/generate_api_channel_key.dart qa
   ```

4. 생성된 URL을 테스터에게 안전하게 전달
