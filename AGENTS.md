# AGENTS.md

이 저장소는 Pokemon Another Red의 `Scripts.rxdata`를 추출한 Ruby 스크립트 관리용 저장소입니다.

## 작업 원칙

- 게임 전체 에셋을 커밋하지 않습니다.
- `Scripts.rxdata`를 갱신하면 반드시 `Scripts/` 추출본과 `Scripts/manifest.tsv`도 함께 갱신합니다.
- 랜덤 메커니즘 수정과 HTML 정보 추출 수정은 가능한 한 분리합니다.
- 기존 개발자의 랜덤 알고리즘을 바꿀 때는 이유와 영향 범위를 README 또는 이슈에 남깁니다.
- 단순 표시/추출 기능은 새 섹션으로 분리하는 방식을 우선합니다.

## 주요 관심 파일

- `Scripts/273_KPokemon.rb`: Pokemon 객체, species/form/level/exp 관련 핵심.
- `Scripts/324_KUI_Evolution.rb`: 진화 화면 및 진화 성공 처리.
- `Scripts/263_KItem_Utilities.rb`: 경험치 사탕, `pbChangeExp`, `pbChangeLevel`.
- `Scripts/149_KBattle_ExpAndMoveLearning.rb`: 전투/포획 경험치.
- `Scripts/407_RandomData.rb`: HTML 데이터 추출.
- `Scripts/441_RandomHistoryExport.rb`: 트레이너 기술/지닌물건 히스토리 추가 섹션.

## 현재 우선순위

1. 특수 폼 포켓몬이 랜덤 진화할 때 기존 form 값이 새 종족에 누수되는 문제.
2. Slow 경험치통 통일 상태에서 `exp`와 `level`이 불일치해 경험치 획득/사탕 사용 시 오류가 나는 문제.
3. HTML 종족값 검색/정렬 개선.
4. 트레이너 히스토리 간헐 미기록 조사.

## 커밋 전 확인

- `Scripts/manifest.tsv`의 섹션 수가 현재 `Scripts.rxdata`와 맞는지 확인합니다.
- 패킹된 `Scripts.rxdata`를 게임에 넣어 최소한 부팅 테스트합니다.
- 기존 섹션을 수정했다면 어떤 섹션을 왜 수정했는지 커밋 메시지에 남깁니다.
