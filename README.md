# AnotherEngine Script

Pokemon Another Red용 `Scripts.rxdata`를 RGSS 스크립트 단위의 `.rb` 파일로 추출해 관리하는 저장소입니다.

## 현재 버전

- 버전: `v1.0`
- 기준 파일: `Data/Scripts.rxdata`
- 추출 섹션 수: 443개
- 최신 추출본: `Scripts/`
- 릴리즈 업로드용 파일: `release-assets/Scripts.rxdata`

## 폴더 구조

- `Scripts/`: `Scripts.rxdata`에서 추출한 Ruby 스크립트 섹션입니다.
- `Scripts/manifest.tsv`: 섹션 번호, 섹션 ID, 섹션명, 파일명, SHA-256 해시 목록입니다.
- `tools/`: 추출/패킹 보조 스크립트입니다.
- `release-assets/Scripts.rxdata`: 게임에 넣어 테스트할 수 있는 패킹된 스크립트 파일입니다.

## 확인된 주요 이슈

### 1. 특수 폼 포켓몬의 랜덤 진화 후 폼 누수

알로라 꼬렛처럼 `form = 1`인 포켓몬이 랜덤 진화로 토대부기 같은 기본 폼 포켓몬이 될 때, 종족은 바뀌었는데 기존 폼 값이 남는 것으로 보입니다.

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

또는 같은 의미로, 종족이 바뀔 때마다 새 species 데이터 기준으로 폼을 항상 재설정해야 합니다.

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

최소 적용 지점:

- `pbGainExpOne` 시작부
- `pbChangeExp` 시작부

이렇게 하면 전투, 포획, 경험치 사탕 경로를 모두 방어할 수 있습니다.

### 3. HTML 종족값 검색/정렬 개선

현재 이름/폼/특성 검색만으로도 기본 사용은 가능합니다. 추가 기능 후보는 다음과 같습니다.

- 종족값 컬럼 오름차순/내림차순 정렬 복구
- HP/공격/방어/특공/특방/스피드/총합 숫자를 일반 검색 대상에 포함
- `HP>=80`, `총합>=600`, `스피드<=50` 같은 범위 검색
- `체력 + 방어 + 특수방어` 값을 보여주는 `3대` 컬럼 추가

우선순위는 랜덤 메커니즘 버그 수정 이후입니다.

### 4. 트레이너 히스토리 간헐 미기록

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

## 개발자/AI Agent 작업 규칙

- `Scripts.rxdata`를 직접 수정한 뒤에는 반드시 다시 추출해서 `Scripts/`와 `manifest.tsv`를 갱신합니다.
- 기존 개발자 랜덤 메커니즘과 HTML 정보 추출 기능은 가능한 한 분리합니다.
- 버그 수정은 이슈 번호나 증상 이름을 커밋 메시지에 포함합니다.
- 릴리즈에는 테스트 가능한 `Scripts.rxdata`를 첨부합니다.
- 대형 게임 에셋, 오디오, 그래픽 리소스는 이 저장소에 올리지 않습니다.

## 협업 권한 추가 방법

저장소 관리자만 설정할 수 있습니다.

1. GitHub 저장소 페이지에서 `Settings`를 누릅니다.
2. 왼쪽 메뉴에서 `Collaborators and teams`를 누릅니다.
3. `Add people` 버튼을 누릅니다.
4. 추가할 사람의 GitHub ID 또는 이메일을 입력합니다.
5. 권한을 선택합니다.
   - 코드 push/branch/tag/release까지 맡길 개발자: `Write` 또는 `Maintain`
   - 저장소 설정까지 거의 전부 맡길 사람: `Admin`
6. 초대받은 사람이 이메일 또는 GitHub 알림에서 초대를 수락해야 적용됩니다.

AI Agent가 push하려면 해당 Agent를 실행하는 사람의 GitHub 계정에 push 권한이 있어야 합니다. 보통은 각 개발자 계정을 collaborator로 추가하고, 그 개발자 PC의 git 인증으로 Agent가 push하게 하는 방식이 가장 단순합니다.

## 릴리즈 절차

1. `Scripts/`와 `release-assets/Scripts.rxdata`가 같은 내용인지 확인합니다.
2. 커밋합니다.
3. 태그를 만듭니다.
   ```bash
   git tag v1.0
   git push origin main
   git push origin v1.0
   ```
4. GitHub 저장소의 `Releases`에서 `Draft a new release`를 누릅니다.
5. 태그 `v1.0`을 선택합니다.
6. `release-assets/Scripts.rxdata`를 첨부합니다.
7. `Publish release`를 누릅니다.
