# AnotherEngine Script

Pokemon Another Red의 `Scripts.rxdata`를 `.rb` 스크립트로 추출해 관리하고, 개발 이슈를 추적하기 위한 저장소입니다.

## 현재 버전

- 버전: `v1.1`
- 기준 파일: `release-assets/Scripts.rxdata`
- 추출 섹션 수: 443개
- 추출본: `Scripts/`
- 섹션 목록: `Scripts/manifest.tsv`

## 폴더 구조

- `Scripts/`: `Scripts.rxdata`에서 추출한 Ruby 스크립트입니다.
- `Scripts/manifest.tsv`: 섹션 번호, 섹션 ID, 섹션명, 파일명, SHA-256 해시 목록입니다.
- `tools/`: 추출/패킹 보조 스크립트입니다.
- `release-assets/Scripts.rxdata`: 최신 릴리즈에 첨부한 테스트용 파일입니다.

## v1.1 변경사항

- 정보 추출 HTML의 HP/공격/방어/특수공격/특수방어/스피드/합계 컬럼에 오름차순, 내림차순, 기본순 정렬을 추가했습니다.
- 지닌 물건 히스토리와 기술 히스토리 컬럼을 표의 맨 뒤로 이동했습니다.
- 가로로 긴 표를 볼 때 `No`와 포켓몬 이름 컬럼이 왼쪽에 고정되도록 했습니다.
- 페이지 하단에 고정 가로 스크롤바를 추가해 어느 위치에서든 좌우 이동이 가능하도록 했습니다.

## 확인 중인 주요 이슈

### 1. 특수 폼 포켓몬의 랜덤 진화 후 폼 누수

알로라 꼬렛처럼 `form = 1`인 포켓몬이 랜덤 진화로 토대부기 같은 기본 폼 포켓몬이 될 때, 종족은 바뀌었는데 기존 폼 값이 남는 것으로 의심됩니다.

의심 지점:

```ruby
def species=(species_id)
  new_species_data = GameData::Species.get(species_id)
  return if @species == new_species_data.species

  @species = new_species_data.species
  default_form = new_species_data.default_form

  if default_form >= 0
    @form = default_form
  elsif new_species_data.form > 0
    @form = new_species_data.form
  end
end
```

`new_species_data.form == 0`이고 `default_form < 0`인 일반 포켓몬으로 변경될 때 `@form`이 0으로 초기화되지 않을 수 있습니다.

제안:

```ruby
@form = (default_form >= 0) ? default_form : new_species_data.form
```

핵심은 종족이 바뀔 때마다 새 species 데이터 기준으로 폼을 항상 다시 세팅하는 것입니다.

### 2. 경험치통 통일 시스템과 경험치 사탕 오류

Slow 경험치통 통일 자체는 의도된 동작입니다. 문제는 포켓몬의 현재 레벨과 경험치가 Slow 기준으로 동기화되지 않은 상태에서 경험치를 얻을 때 발생합니다.

전투/포획 경험치는 `pbGainExpOne`을 타지만, 경험치 사탕은 다음 경로를 탑니다.

```text
pbGainExpFromExpCandy
-> pbChangeExp
```

따라서 안전장치를 `pbGainExpOne`에만 넣으면 사탕류는 빠질 수 있습니다.

제안:

```ruby
def pbSyncUnifiedExpFloor(pkmn)
  return if !$exp_unify_switch
  return if !pkmn
  lv = pkmn.level
  min_exp = pkmn.growth_rate.minimum_exp_for_level(lv)
  pkmn.exp = min_exp if pkmn.exp < min_exp
end
```

최소 적용 후보:

- `pbGainExpOne` 시작부
- `pbChangeExp` 시작부

### 3. 트레이너 히스토리 간헐 미기록

트레이너 기술/지닌물건 히스토리는 트레이너 배틀 시작 시점에 상대 파티의 확정된 `moves`/`item`을 기록하는 방식입니다.

간헐적으로 비는 경우의 후보:

- 최신 `Scripts.rxdata`가 적용되지 않은 상태에서 테스트
- 일반 트레이너 배틀 경로가 아닌 이벤트성 배틀 경로
- 배틀 후 저장하지 않고 게임을 종료
- 오래된 세이브의 `$PokemonGlobal` 구조와 신규 히스토리 저장소 초기화 문제

현재는 우선순위가 낮습니다.

## GitHub를 처음 쓰는 테스터를 위한 이슈 올리는 법

1. 이 저장소 페이지 상단의 `Issues` 탭을 누릅니다.
2. 오른쪽 위의 `New issue` 버튼을 누릅니다.
3. 제목에 증상을 짧게 적습니다.
   - 예: `알로라 꼬렛이 랜덤 진화 후 토대부기 폼이 이상함`
4. 본문에는 아래 내용을 최대한 적습니다.
   - 사용한 `Scripts.rxdata` 버전
   - 새 게임인지 기존 세이브인지
   - 랜덤 설정에서 켠 옵션
   - 문제가 생긴 포켓몬 이름/폼/레벨
   - 어떤 행동을 했는지 순서대로
   - 스크린샷
   - 에러창이 있다면 전체 문구
5. `Submit new issue`를 누릅니다.

완벽하게 쓰지 않아도 됩니다. 재현 순서와 스크린샷이 가장 중요합니다.
