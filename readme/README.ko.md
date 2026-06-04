![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect는 사설 네트워크와 암호화된 통신을 위한 최신 크로스 플랫폼 보안 연결 클라이언트로, 성능, 개인정보 보호, 정밀한 트래픽 관리에 중점을 두고 개발되었습니다.

보안 네트워킹 및 터널링 엔진을 위한 강력한 오케스트레이션 계층을 제공하며, 특정 프로토콜, 기술 또는 구현에 종속되지 않으면서 신뢰성, 관측 가능성, 운영 투명성, 사용자 경험을 강조합니다.

GenyConnect는 두 방향으로 개발되고 있습니다. 개인 사용자와 일상적인 연결 요구를 위한 Community Edition, 그리고 중앙 관리, 네트워크 정책, 접근 제어, 대규모 보안 통신이 필요한 조직을 위한 Commercial & Enterprise Edition입니다.

<p align="left">
  <a href="https://en.cppreference.com/w/cpp/23">
    <img
      alt="C++23"
      src="https://img.shields.io/badge/C%2B%2B-23-00599C?style=for-the-badge&logo=cplusplus"
    />
  </a>

  <a href="https://cmake.org/">
    <img
    alt="CMake 4.2+"
    src="https://img.shields.io/badge/CMake-4.2%2B-00599C?style=for-the-badge&logo=cmake"
    />
  </a>

  <a href="https://www.qt.io/">
    <img
      alt="Qt 6"
      src="https://img.shields.io/badge/Qt-6-41CD52?style=for-the-badge&logo=qt"
    />
  </a>

  <a href="../LICENSE">
    <img
      alt="License GPL-3.0-or-later"
      src="https://img.shields.io/badge/License-GPL--3.0--or--later-8E44AD?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/actions">
    <img
      alt="Build Passing"
      src="https://img.shields.io/badge/Build-Passing-27AE60?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/pulls">
    <img
      alt="PRs Welcome"
      src="https://img.shields.io/badge/PRs-Welcome-F39C12?style=for-the-badge"
    />
  </a>
</p>


---

## 개요

GenyConnect는 구조화된 서버 프로필과 공유 가능한 구성 링크를 통해 사용자가 보안 연결을 만들고 관리할 수 있게 합니다.

런타임 구성은 동적으로 생성되고, 연결 수명 주기는 명시적으로 감독되며, 시스템 상태는 항상 완전히 관측 가능합니다.

이 플랫폼은 의도적으로 engine-agnostic 구조를 유지하여 사용자 흐름이나 예상 동작을 바꾸지 않고 다양한 터널링 백엔드를 통합할 수 있습니다.

GenyConnect는 일반적인 터널링 사용 사례에만 제한되지 않습니다. 장기적인 방향은 서비스, 사설 인프라, 클라우드 리소스, 안정적이고 신뢰할 수 있는 통신이 필요한 분산 팀의 접근을 관리하는 지능형 연결 계층입니다.

1.4 및 1.5 릴리스 범위에서 GenyConnect는 더 넓은 일반 사용을 위해 성숙해지고, 신뢰할 수 있는 연결을 필요로 하는 사용자의 상당한 요구를 충족할 것으로 예상됩니다. 향후 릴리스에서는 Persian 및 추가 앱 내 언어 지원도 계획되어 있습니다.

GenyConnect의 2세대는 접근 관리, 통신 인프라 맞춤화, 네트워크 복원력, 외부 서비스 의존도 감소, 다양한 네트워크 조건에서의 안정적인 연결 유지 등 상업 및 조직 요구에 더 깊이 초점을 맞출 예정입니다. 향후 버전에서는 사설 네트워크와 조직 접근을 정의하고 관리하기 위한 전용 `gen.` 형식과 GenyConnect 자체 통신 아키텍처도 지원할 계획입니다.

---

## 주요 기능

- 명확한 운영 가시성
  - 실시간 로그
  - 실시간 트래픽 통계
  - 명시적인 연결 상태 보고

- 고성능 실행
  - 가벼운 런타임
  - 최소한의 오버헤드
  - 지속적인 부하에서도 빠른 응답

- 결정적인 수명 주기 관리
  - 예측 가능한 시작
  - 깔끔한 종료
  - 안전한 재연결 로직

- 고급 트래픽 라우팅
  - whitelist 기반 라우팅
  - 도메인 수준 tunnel/direct/block 규칙
  - 지원되는 경우 애플리케이션 기반 라우팅
  - 지원되는 경우 프로세스 기반 라우팅

- 유연한 터널링 모드
  - 애플리케이션 수준 프록시
  - 전체 시스템 터널링
  - 일관된 제어 인터페이스

- LAN Sharing
  - GenyConnect가 관리하는 트래픽을 로컬 네트워크의 다른 장치와 공유
  - 게임 콘솔, 스마트 TV, 휴대폰, 태블릿, 노트북, 데스크톱 컴퓨터 지원
  - 관리형 네트워크 환경을 위한 고급 공유 제어

- 크로스 플랫폼 아키텍처
  - 공유 runtime core
  - desktop 및 mobile 어댑터
  - 플랫폼별 통합

---

## Power Mode

GenyConnect에는 지속적인 작업 부하에서 연결 안정성과 런타임 일관성을 높이기 위해 설계된 플랫폼 인식 Power Mode 시스템이 포함되어 있습니다.

Power Mode는 공격적인 절전 동작, 백그라운드 제한, 유휴 상태 일시 중단, 절전 상태 전환으로 인한 운영체제 간섭을 줄이는 데 도움을 줍니다.

운영체제와 runtime backend에 따라 Power Mode는 다음을 수행할 수 있습니다.

- 중요한 네트워크 경로의 응답성 유지
- 예상치 못한 연결 끊김 감소
- 처리량 일관성 개선
- 장시간 트래픽 세션 최적화
- 높은 활동 중 지연 시간 급증 최소화
- 터널링 중 런타임 안정성 향상

Power Mode 동작은 적응형이며 플랫폼 기능과 운영체제 제한에 따라 달라질 수 있습니다.

---

## 스크린샷

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## 플랫폼 지원

GenyConnect는 현재 다음을 지원합니다.

- macOS
- Windows
- Linux
- Android

iOS 지원은 활발히 개발 중입니다.

---

## 기술 스택

- C++23
- Qt 6 / QML
- 크로스 플랫폼 네이티브 런타임 아키텍처
- 멀티 플랫폼 배포 파이프라인
- Engine-agnostic 터널링 백엔드 통합

---

## 라이선스

GenyConnect Community Edition은 GNU General Public License 버전 3 이상(GPL-3.0-or-later)에 따라 라이선스됩니다.

상업용 라이선스는 Genyleap Labs를 통해 별도로 제공되며 다음 용도에 적용됩니다.

- 독점 배포
- closed-source 재배포
- 엔터프라이즈 통합
- white-label 제품
- App Store 배포
- 상업용 에디션
- Pro 또는 Enterprise 기능

명시적으로 달리 stated되지 않는 한, 다음 항목은 GPL 라이선스의 적용 대상이 아니며 All Rights Reserved로 유지됩니다.

- GenyConnect 이름
- 로고
- 아이콘
- 스크린샷
- 시각 디자인
- 브랜딩 자산
- 홍보 그래픽
- UI artwork
- 시각 정체성 자료
- 마케팅 자산

명시적인 서면 허가 없이 포크와 재배포는 Genyleap Labs의 보증 또는 제휴를 암시할 수 없습니다.

전체 라이선스 세부 사항은 LICENSE 및 NOTICE 파일을 참조하십시오.

### 라이선스 요약

Community Edition 소스 코드:
- GPL-3.0-or-later

상업용 라이선스:
- 별도의 독점 상업용 라이선스

브랜딩 및 비코드 자산:
- All Rights Reserved

---

## ❤️ GenyConnect 지원

GenyConnect는 Genyleap Labs가 독립적으로 개발하는 프로젝트입니다.

GenyConnect가 도움이 된다면 Base Network에서 $GENY 또는 USDC로 기부하여 지속적인 개발을 지원할 수 있습니다.

여러분의 지원은 다음에 사용됩니다.

- 지속적인 개발
- 보안 개선
- desktop 및 mobile 플랫폼 지원
- 인프라와 테스트
- 향후 open-source 릴리스
- 장기적인 생태계 성장

---

## 🌐 $GENY로 지원

$GENY로 기부하면 GenyConnect 개발과 더 넓은 Geny 생태계를 함께 지원하게 됩니다.

### Base Mainnet

GENY 토큰 계약:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

개발자 기부 지갑:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Genyleap 생태계를 위해 $GENY 구매 또는 스왑

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 USDC로 지원

USDC는 개발을 직접 지원하는 안정적이고 간단한 방법입니다.

### Base Mainnet

개발자 기부 지갑:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## 기부 안내

기부는 GenyConnect 개발을 지원하기 위한 자발적 기여입니다.

기부는 다음을 의미하지 않습니다.

- 투자
- 지분
- 소유권
- 수익 공유
- 증권
- 금융 상품
- 재정적 수익 약속

📢 개발 업데이트, 공지, 향후 릴리스는 Telegram 및 Farcaster에서 확인할 수 있습니다.

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

여러분의 피드백과 지원은 GenyConnect와 더 넓은 Genyleap 생태계의 미래를 만드는 데 도움이 됩니다. 🚀
