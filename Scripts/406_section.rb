# ==============================================================================
# [Another Red] 랜더마이저 무결성 검증기 (디버그용 - 원본 데이터 중복 검출)
# ==============================================================================

def pbCheckRandomizerErrors
  p_name = ($player ? $player.name : "Player")
  filename = "랜더마이저_오류검증결과_#{p_name}.txt"
  
  error_logs = []
  error_logs << "======================================================================"
  error_logs << "      [Another Red] 랜더마이저 원본 데이터 중복 검사 리포트"
  error_logs << "======================================================================"
  error_logs << "검사 일시: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
  error_logs << "----------------------------------------------------------------------"
  
  # 스위치 작동 여부 확인
  stats_on = (defined?($player) && $player && $player.respond_to?(:random_stats_new_switch) && $player.random_stats_new_switch)
  abi_on = (defined?($player) && $player && $player.respond_to?(:random_ability_new_switch) && $player.random_ability_new_switch)

  if !stats_on || !abi_on
    pbMessage(_INTL("경고: 종족값 또는 특성 랜덤 스위치가 꺼져 있어 원본과 동일하게 나옵니다.\n먼저 스위치를 켜주세요."))
    error_logs << "[경고] 랜덤 스위치가 꺼진 상태에서 검사가 진행되었습니다."
  end

  pbMessage(_INTL("전 종족의 원본 데이터를 대조하여 오류를 검출합니다..."))
  error_count = 0

  GameData::Species.each do |sp|
    # 다이맥스, 거다이맥스 폼 제외
    next if sp.id.to_s.include?("GMAX") || sp.id.to_s.include?("DMAX")
    
    # 폼 이름 깔끔하게 정리
    species_name = sp.form_name && !sp.form_name.empty? ? "#{sp.name} (#{sp.form_name})" : sp.name
    species_name += " (폼 #{sp.form})" if sp.form > 0 && (!sp.form_name || sp.form_name.empty?)

    # 1. 종족값 검사 (원본 배열 vs 생성된 캐시 배열)
    orig_stats = sp.base_stats.values
    rand_stats = pbGetSpeciesFixedStats(sp.species, sp.form)
    stats_match = (orig_stats == rand_stats)

    # 2. 특성 검사 (원본이 가진 1, 2특성 및 숨특 중 하나라도 겹치는지 확인)
    orig_abilities = sp.abilities.compact
    orig_abilities += sp.hidden_abilities.compact rescue []
    orig_abilities.uniq!
    
    rand_ability = pbGetSpeciesFixedAbility(sp.species, sp.form) rescue :PRESSURE
    ability_match = orig_abilities.include?(rand_ability)

    # 둘 중 하나라도 원본과 동일하면 에러 로그에 추가
    if stats_match || ability_match
      error_count += 1
      error_logs << ""
      error_logs << "▶ #{species_name} [도감번호: #{sp.species} / Form: #{sp.form}]"
      
      if stats_match
        error_logs << "   [종족값 중복 에러] 완전히 똑같이 배정되었습니다!"
        error_logs << "   - 원본: #{orig_stats.inspect}"
        error_logs << "   - 랜덤: #{rand_stats.inspect}"
      end
      
      if ability_match
        orig_abi_names = orig_abilities.map { |a| GameData::Ability.get(a).name rescue a.to_s }.join(", ")
        rand_abi_name = GameData::Ability.get(rand_ability).name rescue rand_ability.to_s
        error_logs << "   [특성 중복 에러] 원본 특성 중 하나가 그대로 나왔습니다!"
        error_logs << "   - 원본 특성군: [#{orig_abi_names}]"
        error_logs << "   - 배정된 특성: [#{rand_abi_name}]"
      end
    end
  end

  error_logs << "\n======================================================================"
  if error_count == 0
    error_logs << "★ 완벽합니다! 원본과 동일한 데이터를 가진 포켓몬이 단 한 마리도 없습니다. ★"
  else
    error_logs << "총 #{error_count}건의 원본 중복 데이터가 발견되었습니다."
    error_logs << "※ 참고: 특성의 경우 수백 마리의 포켓몬이 수십 개의 특성을 나눠 가지므로"
    error_logs << "확률적으로 1~2마리 정도는 우연히 원본 특성을 뽑을 수도 있습니다."
  end
  error_logs << "======================================================================"

  # 파일 저장
  begin
    File.open(filename, "w:UTF-8") do |f|
      error_logs.each { |line| f.puts(line) }
    end
    pbMessage(_INTL("검사 완료! 게임 폴더 내 '{1}' 파일을 열어보세요.", filename))
  rescue => e
    pbMessage(_INTL("파일 저장 중 오류가 발생했습니다: {1}", e.message))
  end
end