# 🎈 Kids Toy Box (키즈 미니 게임 천국)

## 1. 프로젝트 개요
- **목표**: 4~7세 유아를 위한 안전하고 재밌는 모듈형 미니 게임 컬렉션 앱
- **비즈니스 모델**: 단일 평생 소장권 (광고 ZERO, 추가 유도 결제 ZERO)
- **개발 엔진**: Flutter (Dart) + Gemini 3.5 Flash (AI 주도 개발)

## 2. 핵심 아키텍처 (모듈형 구조)
- 메인 로비(`lib/lobby/`)에서 여러 개의 미니 게임 모듈(`lib/games/`)로 연결되는 구조입니다.
- 각 게임 모듈은 서로의 상태나 로직에 영향을 주지 않는 **완전한 독립 위젯**으로 개발합니다.

```text
lib/
├── core/                  # 공통 위젯, 테마, 오디오 매니저
├── lobby/                 # 게임 선택 메인 로비 화면 (Grid View)
└── games/                 # 독립된 미니 게임 모듈들
    ├── balloon_pop/       # 1. 풍선 터뜨리기
    ├── shape_coloring/    # 2. 모양 자르고 색칠하기
    ├── hidden_object/     # 3. 숨은 그림 찾기
    ├── spot_difference/   # 4. 틀린 그림 찾기
    ├── memory_match/      # 5. 카드 짝맞추기
    ├── fruit_slicer/      # 6. 과일 쓱싹 (과일 자르기)
    ├── feed_animals/      # 7. 동물 맘마 (동물 먹이주기)
    ├── whack_a_mole/      # 8. 두더지 잡기 (피버 타임, 황금 두더지 등 고급 기능 포함)
    ├── dino_jump/         # 9. 공룡 점프 (장애물 회피, 디테일한 충돌 판정 적용)
    ├── brick_breaker/     # 10. 벽돌 깨기 (막대로 공을 튕겨서 사탕 벽돌 부수기)
    ├── xylophone/         # 11. 실로폰 연주 (사운드 매핑 및 건반 애니메이션)
    ├── bubble_pop/        # 12. 비눗방울 톡톡 (파티클 기반 힐링 감각 놀이)
    ├── burger_maker/      # 13. 햄버거 타이쿤 (재료 쌓기 게임)
    ├── tower_builder/     # 14. 탑 쌓기 (타이밍 블록 낙하)
    ├── mini_racing/       # 15. 요리조리 자동차 (장애물 회피 레이싱)
    ├── fishing_game/      # 16. 낚시 놀이 (타이밍 낚시)
    ├── connect_dots/      # 17. 점 잇기 (순서대로 점 연결하기)
    ├── tracing/           # 18. 따라 쓰기 (드래그 궤적 그리기)
    ├── jigsaw_puzzle/     # 19. 직소 퍼즐 (간단한 드래그 앤 드롭 퍼즐)
    └── maze_escape/       # 20. 미로 찾기 (간단한 2D 미로 탈출)

## 3. 핵심 공통 기능 (Core Features)
- **AudioManager (`core/audio/`)**: 효과음(팝, 클릭, 성공, 데미지, 게임오버) 및 BGM 통합 관리
- **KidsTheme (`core/theme/`)**: 아이들에게 안정감을 주는 파스텔 톤 색상 및 둥근 장난감 모양의 UI 제공
- **ParentalGateModal (`core/widgets/`)**: 설정 등 부모님 공간 진입 시 구구단 퀴즈를 풀어야만 통과할 수 있는 안전장치



설정이나 외부 링크 접근 시 반드시 구구단을 맞혀야 통과하는 ParentalGateModal 위젯을 거치도록 코딩하라. 또한 일체의 데이터 수집이나 분석 SDK를 포함하지 마라