<h1 align="center">Two-Set Stenotype</h1>

TSS는 일반 두벌식 키보드 자판을 활용해 새롭게 구상한 두벌식 속기 키보드입니다.

## 빌드

요구 사항은 Rust stable, Swift 6, macOS 14 이상입니다.

### 앱

```sh
./scripts/build-macos.sh
```

완성된 로컬 앱은 `dist/TSS.app`에 생성됩니다.

### DMG

```sh
./scripts/build-dmg.sh
```

앱을 다시 빌드하고 검증한 뒤 `Applications` 바로가기가 포함된 `dist/TSS-<버전>.dmg`를 만듭니다.

## 빠른 시작

앱은 접근성 권한을 필요로 합니다. 앱 실행 시 macOS 권한요청을 표시합니다.

속기 모드는 기본적으로 꺼져 있습니다. 앱에서 직접 켜고 끄거나, 단축키(기본 `fn+T`)를 사용해 켜고 끌 수 있습니다.

속기를 하기 위해서는 사전이 필요합니다. 사전 메뉴에서 사전을 추가할 수 있습니다.

## 사전 형식

사전은 chord를 키로 하는 JSON 객체입니다. 여러 파일을 활성화할 수 있지만 정규화된 chord가 겹치면 새 스냅샷 전체를 거부하고 마지막 사전 메모리를 유지합니다.

### Chord 표기

- 영문자와 숫자는 물리 키캡 문자로 씁니다.
- Shift는 `^`, Space는 `_`입니다.
- 한 stroke 안에서 같은 토큰을 여러 번 적으면 하나의 물리키로 축약됩니다. 예를 들어 `RRK;`는 `RK;`로 정규화됩니다.
- Chord 표기 순서는 앱에서 사전을 로드할 때 무시되며 QWERTY 행 순서로 정규화됩니다. Shift는 맨 앞, Space는 맨 뒤입니다.

### 에시

```json
{
  "_": " ",
  "RK": "가",
  "ASDF": { "key": "enter" },
  "LQWE": {
    "text": "입니다",
    "deleteBefore": true
  },
  "F": {
    "condition": "previousHangulBatchim",
    "batchim": {
      "text": "을",
      "deleteBefore": true
    },
    "noBatchim": {
      "text": "를",
      "deleteBefore": true
    }
  },
  "QWE": {
    "replaceBatchim": "ㅂ",
    "text": "니다",
    "deleteBefore": true
  }
}
```

`deleteBefore: true`는 커서 또는 선택 시작점 바로 앞의 연속된 일반 스페이스와 탭을 삭제하며, 생략하거나 `false`로 지정하면 삭제하지 않습니다.

`previousHangulBatchim`은 공백을 건너뛴 글자의 받침 유무를 판단하여 결괏값에 차별을 둘 수 있는 조건입니다. 글자는 NFC로 정규화해 판정하며 비한글 혹은 문서 시작일 경우 `noBatchim`으로 처리합니다.

`replaceBatchim`은 바로 앞 완성형 한글 음절의 기존 받침을 제거하고 지정한 받침으로 바꾼 뒤 `text`를 이어 붙입니다.\
예를 들어 `{"replaceBatchim":"ㅂ","text":"니다"}`는 `가` 뒤에서 `갑니다`를, `{"replaceBatchim":"ㄹ","text":" 수 "}`는 `간` 뒤에서도 기존 `ㄴ`을 `ㄹ`로 바꿔 `갈 수 `를 만듭니다. `deleteBefore: true`이면 음절과 커서 사이의 스페이스·탭이 먼저 삭제된 후 그 앞글자에 동일하게 적용됩니다.\
`replaceBatchim`에는 실제 종성으로 쓸 수 있는 호환 자모 한 글자만 지정할 수 있습니다.

[!] 문맥형 약어는 macOS Accessibility API를 우선 사용하고, 신뢰 가능한 동안에는 메모리 추적 버퍼를 사용합니다. 문맥을 확인할 수 없거나 256 grapheme 탐색 한도를 넘으면 기본값만을 출력합니다.

## 구조

- `crates/tss-core`: OS 독립적인 사전·stroke·문맥 엔진
- `crates/tss-ffi`: Swift와 연결하는 C ABI 정적 라이브러리
- `macos/Sources/TSSApp`: SwiftUI 메뉴 막대 앱과 macOS 입력 어댑터
- `examples`: 사전 예제

[!] 일부 보안 입력란과 합성 Unicode 이벤트를 별도로 처리하는 앱에서는 macOS 제약으로 출력되지 않을 수 있습니다.
