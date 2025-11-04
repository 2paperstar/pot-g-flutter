# API 채널 키 검증 시스템 설정 가이드

## 개요

API 채널을 변경할 수 있는 검증된 키 시스템입니다. **비대칭 암호화(RSA)**를 사용하여:
- **운영진**: 개인키로 서명 생성 (개인키는 앱에 포함되지 않음)
- **앱**: 공개키로 서명 검증 (공개키만 앱에 포함)

## 아키텍처

- **키 형식**: `channel:timestamp:signature`
- **서명 알고리즘**: RSA-PSS-SHA256 (비대칭 암호화)
- **만료 시간**: 7일
- **키 생성**: 운영진이 개인키로 서명 생성
- **키 검증**: 앱에서 공개키로 서명 검증 (필수)

### 서명/검증 프로세스

1. **키 생성 (운영진 - 개인키 사용)**:
   - 메시지 생성: `channel:timestamp`
   - RSA-PSS-SHA256 서명 계산: `RSA-PSS-SHA256(private_key, "channel:timestamp")`
   - 키 조합: `channel:timestamp:signature` (signature는 base64 인코딩)

2. **키 검증 (앱 - 공개키 사용)**:
   - 키 형식 검증 (`channel:timestamp:signature`)
   - 채널 이름 검증
   - 타임스탬프 검증 (만료 시간, 미래 타임스탬프 거부)
   - **RSA 서명 검증 (필수)**: 공개키로 서명 재검증
   - 검증 실패 시 요청 거부

## 설정 방법

### 1. RSA 키 쌍 생성

```bash
# 키 쌍 생성 (한 번만 실행)
./tools/generate_rsa_keypair.sh

# 또는 수동으로 생성
openssl genrsa -out keys/private_key.pem 2048
openssl rsa -in keys/private_key.pem -pubout -out keys/public_key.pem
```

**중요**: 
- 개인키(`private_key.pem`)는 **절대** 버전 관리에 포함하지 마세요
- 개인키는 운영진만 보관하고 서명 생성에 사용합니다
- 공개키(`public_key.pem`)만 앱에 포함됩니다

### 2. 환경 변수 설정

`.env` 파일을 생성하고 공개키를 설정합니다:

```bash
# 공개키 파일 내용을 복사하여 .env에 추가
cat keys/public_key.pem >> .env
# 또는 직접 설정
API_CHANNEL_KEY_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----"
```

### 3. envied 설정

`.env` 파일에 `API_CHANNEL_KEY_PUBLIC_KEY` 변수를 추가합니다.

그런 다음 빌드를 실행하여 `config.g.dart` 파일을 생성합니다:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. 키 생성

```bash
# 개인키로 서명 생성
dart run tools/generate_api_channel_key.dart qa keys/private_key.pem
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
4. **서명 검증 (필수)**:
   - 키 형식 검증 (`channel:timestamp:signature`)
   - 채널 이름 검증
   - 타임스탬프 검증 (만료 시간 7일, 미래 타임스탬프 거부)
   - **RSA-PSS-SHA256 서명 검증 (필수)** - 공개키로 검증
5. **검증 실패 시**: 요청 거부 및 에러 메시지 표시
6. **검증 성공 시**:
   - 히든메뉴 활성화
   - API 채널 변경
   - 성공 메시지 표시

**중요**: 서명 검증은 필수입니다. 서명이 유효하지 않은 키는 무조건 거부됩니다.

## 보안 고려사항

1. **개인키 관리**
   - 개인키는 **절대** 코드나 버전 관리에 포함하지 마세요
   - 개인키는 안전한 곳에 보관 (예: 암호화된 저장소, 비밀 관리 시스템)
   - 운영진만 개인키에 접근 가능해야 합니다
   - 공개키만 앱에 포함됩니다

2. **공개키 관리**
   - 공개키는 앱에 포함되어도 안전합니다 (검증만 가능)
   - 공개키 변경 시 앱 업데이트 필요

3. **키 만료**
   - 기본 만료 시간은 7일입니다
   - 필요시 `ApiChannelKeyValidator._expirationSeconds` 수정

4. **키 공유**
   - 생성된 키는 안전한 채널을 통해 전달
   - 가능하면 암호화된 메시지로 전달

## 구현 파일

- `lib/app/modules/core/domain/repositories/api_channel_key_validator.dart`: RSA 공개키 검증 로직
- `lib/app/values/config.dart`: envied 설정 (공개키)
- `lib/app/pot_app.dart`: 딥링크 처리 및 검증 통합
- `tools/generate_api_channel_key.dart`: 개인키로 서명 생성 도구
- `tools/generate_rsa_keypair.sh`: RSA 키 쌍 생성 스크립트

## 문제 해결

### 키 검증 실패

1. 공개키가 올바르게 설정되었는지 확인
2. 키 형식이 올바른지 확인 (`channel:timestamp:signature`)
3. 키가 만료되지 않았는지 확인 (7일)
4. 타임스탬프 동기화 확인 (서버와 앱의 시간 차이)
5. 개인키와 공개키가 쌍인지 확인

### envied 빌드 오류

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 공개키 찾을 수 없음

환경 변수가 설정되었는지 확인:
```bash
echo $API_CHANNEL_KEY_PUBLIC_KEY
```

또는 `.env` 파일이 올바른 위치에 있는지 확인하세요.

### 개인키 파일 찾을 수 없음

키 쌍을 먼저 생성하세요:
```bash
./tools/generate_rsa_keypair.sh
```

## 비대칭 암호화의 장점

1. **보안성**: 개인키가 앱에 포함되지 않아 노출 위험이 없습니다
2. **검증성**: 공개키만으로 서명 검증이 가능합니다
3. **분리**: 서명 생성(운영진)과 검증(앱)이 완전히 분리됩니다
4. **안전성**: 개인키 유출 시에만 새로운 키 쌍 생성이 필요합니다
