# ==============================================================================
# [Another Red] 종족별 랜덤 기술 영구 박제 시스템 (V24.0 최종 보안판)
# ==============================================================================

class PokemonGlobalMetadata
  # 세이브 파일에 저장될 영구 기술 메모장
  def species_random_move_pool
    @species_random_move_pool ||= {}
    return @species_random_move_pool
  end
end

def pbGetRandomMovesForPkmn(pkmn, attack_count = 30, status_count = 10)
  # 1. 세이브 데이터 내의 영구 저장소를 불러옵니다.
  cache = $PokemonGlobal.species_random_move_pool
  
  # 2. 키 설정: 종족과 폼을 기준으로 합니다.
  species_key = [pkmn.species, pkmn.form]
  
  # 3. 이미 박제된 목록이 있다면 즉시 반환
  if cache[species_key]
    return cache[species_key].reject { |m| pkmn.hasMove?(m) }
  end
  
  # --- 4. [보안 로직] 제외 및 허용 리스트 설정 ---
  
  # [A] 무조건 제외 (레츠고 파트너 기술 및 시스템 기술)
  hard_ban = [
    :STRUGGLE, :CHATTER,
    :ZIPPYZAP, :PAPPYPOW, :VEEVEEVOLLEY, :BOUNCYBUBBLE, :BUZZYBUZZ, 
    :SIZZLYSLIDE, :GLITZYGLOW, :BADDYBAD, :FREEZYFROST, :SAPPYSEED, :SPARKLYSWIRL
  ]

  # [B] 전역 전용기 (주인만 가능, 남들은 제외)
  # 기술 ID => 허용될 종족 ID
  signature_map = {
    :IVYCUDGEL       => :OGERPON,    # 덩굴방망이
    :TERASTARSTORM   => :TERAPAGOS,  # 테라클러스터
    :DRAGONASCENT    => :RAYQUAZA,   # 화룡점정
    :REVELATIONDANCE => :ORICORIO,   # 잠깨춤
    :AURAWHEEL       => :MORPEKO     # 오라휠
  }

  # 5. 기술 풀 생성 및 필터링
  attack_moves = []
  status_moves = []
  
  GameData::Move.each do |move|
    m_id = move.id
    
    # 기본 제외 조건
    next if m_id == :NONE
    next if hard_ban.include?(m_id)
    next if pkmn.hasMove?(m_id)
    
    # 특수 판정 기술 제외 (Z기술, 다이맥스 등)
    next if move.respond_to?(:powerMove?) && move.powerMove?
    next if move.respond_to?(:is_zmove?) && move.is_zmove?
    next if move.respond_to?(:is_max_move?) && move.is_max_move?

    # [C] 전용기 로직 적용
    if signature_map.has_key?(m_id)
      # 지금 배우려는 포켓몬이 기술의 주인이 아니면 제외
      next if pkmn.species != signature_map[m_id]
    end

    # [D] 유저 요청: 심판의뭉치, 멀티어택, 테크노버스터 등은 위 필터를 통과하여 자동 허용됨
    
    if move.status?
      status_moves.push(m_id)
    else
      attack_moves.push(m_id)
    end
  end
  
  # 6. 기술 랜덤 추출
  chosen_attack = attack_moves.sample(attack_count)
  chosen_status = status_moves.sample(status_count)
  final_moves = (chosen_attack + chosen_status).shuffle
  
  # 7. 세이브 파일에 영구 기록 (박제)
  cache[species_key] = final_moves
  
  return final_moves.reject { |m| pkmn.hasMove?(m) }
end

# --- [기존 모듈 주입 방식 유지] ---
# 에센셜의 pbGetRelearnableMoves를 확장하여 랜덤 모드일 때 위 함수를 쓰게 합니다.
module RandomMoveOverride
  def pbGetRelearnableMoves(pkmn)
    # $random_move_switch 가 켜져 있을 때만 랜덤 기술 풀 작동
    if $random_move_switch
      return pbGetRandomMovesForPkmn(pkmn)
    else
      return super(pkmn)
    end
  end
end

# 기존 클래스에 주입
Pokemon.send(:prepend, RandomMoveOverride)