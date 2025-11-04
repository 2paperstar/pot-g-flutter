# API 채널 키 검증 시스템 설정 가이드

## 개요

API 채널을 변경할 수 있는 검증된 키 시스템입니다. 운영진만 키를 생성할 수 있고, 앱에서 검증할 수 있습니다.

## 아키텍처

- **키 형식**: `channel:timestamp:signature`
- **서명 알고리즘**: HMAC-SHA256
- **만료 시간**: 7일
- **키 생성**: 운영진이 도구를 사용하여 생성
- **키 검증**: 앱에서 자동으로 검증

## 설정 방법

### 1. 환경 변수 설정

`.env` 파일을 생성하거나 환경 변수에 시크릿 키를 설정합니다:

```bash
# 강력한 랜덤 키 생성
openssl rand -hex 32

# .env 파일에 추가 또는 환경 변수로 설정
export API_CHANNEL_KEY_SECRET=생성된_시크릿_키
```

### 2. envied 설정

`.env` 파일을 생성하고 `API_CHANNEL_KEY_SECRET` 변수를 추가합니다.

그런 다음 빌드를 실행하여 `config.g.dart` 파일을 생성합니다:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 키 생성

```bash
# 환경 변수로 시크릿 키 설정
export API_CHANNEL_KEY_SECRET=your-secret-key

# 키 생성
dart run tools/generate_api_channel_key.dart qa
```

출력 예시:
```
Generated API Channel Key:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
qa:1734567890:abc123def456...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL:
https://pot-g.gistory.me/test#key=qa:1734567890:abc123def456...

Channel: qa
Timestamp: 1734567890 (2024-12-18 10:30:00)
Expires: 2024-12-25 10:30:00 (7 days)
```

## 사용 방법

### 테스터에게 링크 제공

생성된 키를 사용하여 다음 형식의 URL을 만들 수 있습니다:

```
https://pot-g.gistory.me/test#key=qa:1734567890:abc123def456...
```

또는 query parameter 형식:

```
https://pot-g.gistory.me/test?key=qa:1734567890:abc123def456...
```

### 앱 동작

1. 사용자가 링크를 클릭하면 앱이 열립니다
2. 앱이 `/test` 경로를 감지합니다
3. `key` 파라미터를 추출합니다
4. 키를 검증합니다:
   - 형식 검증
   - 채널 이름 검증
   - 만료 시간 검증 (7일)
   - HMAC-SHA256 서명 검증
5. 검증 성공 시:
   - 히든메뉴 활성화
   - API 채널 변경
   - 성공 메시지 표시

## 보안 고려사항

1. **시크릿 키 관리**
   - 시크릿 키는 절대 코드에 하드코딩하지 마세요
   - 환경 변수 또는 안전한 설정 관리 시스템 사용
   - 운영 환경과 개발 환경의 시크릿 키는 분리

2. **키 만료**
   - 기본 만료 시간은 7일입니다
   - 필요시 `ApiChannelKeyValidator._expirationSeconds` 수정

3. **키 공유**
   - 생성된 키는 안전한 채널을 통해 전달
   - 가능하면 암호화된 메시지로 전달

## 구현 파일

- `lib/app/modules/core/domain/repositories/api_channel_key_validator.dart`: 검증 로직
- `lib/app/values/config.dart`: envied 설정
- `lib/app/pot_app.dart`: 딥링크 처리 및 검증 통합
- `tools/generate_api_channel_key.dart`: 키 생성 도구

## 문제 해결

### 키 검증 실패

1. 시크릿 키가 올바르게 설정되었는지 확인
2. 키 형식이 올바른지 확인 (`channel:timestamp:signature`)
3. 키가 만료되지 않았는지 확인 (7일)
4. 타임스탬프 동기화 확인 (서버와 앱의 시간 차이)

### envied 빌드 오류

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 시크릿 키 찾을 수 없음

환경 변수가 설정되었는지 확인:
```bash
echo $API_CHANNEL_KEY_SECRET
```

또는 `.env` 파일이 올바른 위치에 있는지 확인하세요.
