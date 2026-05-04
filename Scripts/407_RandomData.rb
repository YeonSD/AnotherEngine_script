# ==============================================================================
# [Another Red] 통합 랜덤 엔진 (V19.7 - Search Fix)
#  - Idea by: YeonShirley, class
#  - Completed by: 키도군
# ==============================================================================

# 1. 시드 생성기
def pbGetDeterministicSeed(prefix, species, form)
  s_id = species.is_a?(GameData::Species) ? species.id : species.to_sym
  player_id = ($player ? $player.id : 0)
  seed_str = "#{prefix}_#{s_id}_#{form.to_i}_#{player_id}"
  val = 0
  seed_str.each_byte.with_index { |b, i| val = (val * 37 + b * (i + 1)) % 1000000007 }
  return val
end

# 2. 특성 확정
def pbGetSpeciesFixedAbility(species_id, form_id = 0)
  s_id = species_id.to_sym
  f_id = form_id.to_i
  return :PRESSURE if !$player || !$player.random_ability_new_switch
  $PokemonGlobal.random_ability_cache ||= {}
  key = [s_id, f_id]
  if !$PokemonGlobal.random_ability_cache[key]
    ex = [:POWERCONSTRUCT,:SCHOOLING,:DISGUISE,:BATTLEBOND,:WONDERGUARD,:STANCECHANGE,:ZENMODE,:HUNGERSWITCH,:GULPMISSILE,:ICEFACE]
    pool = GameData::Ability.keys.select { |a| !ex.include?(a) }
    seed = pbGetDeterministicSeed("ABILITY", s_id, f_id)
    rng = Random.new(seed)
    $PokemonGlobal.random_ability_cache[key] = pool.shuffle(random: rng).first || :PRESSURE
  end
  return $PokemonGlobal.random_ability_cache[key]
end

# 3. 폼 분류 로직
def pbGetFormCategoryTag(sp_data, f_id, s_id)
  internal_id = sp_data ? sp_data.id.to_s.upcase : s_id.to_s.upcase
  f_name = sp_data && sp_data.form_name ? sp_data.form_name.upcase : ""

  if internal_id.include?("MEGA") || f_name.include?("MEGA") || f_name.include?("메가")
    return "메가진화"
  elsif internal_id.include?("GMAX") || internal_id.include?("GIGANTAMAX") || f_name.include?("거다이")
    return "거다이맥스"
  elsif f_id == 1
    specials = [:SIRFETCHD, :MRRIME, :OBSTAGOON, :PERRSERKER, :CURSOLA, :RUNERIGUS, :WYDEER, :KLEAVOR, :URSALUNA, :BASCULEGION, :SNEASLER, :OVERQWIL]
    return "특수 폼 진화 체인지" if specials.include?(s_id)
  end
  return "기본"
end

def pbGetRandomExportFormDisplay(sp_data, f_id)
  return (f_id == 0 ? "기본" : "폼 #{f_id}") if !sp_data
  real_form = sp_data.real_form_name.to_s
  if real_form.start_with?("Mega ")
    suffix = real_form.sub(/^Mega\s+#{Regexp.escape(sp_data.real_name.to_s)}/, "")
    suffix = suffix.gsub(/\s+/, "")
    return "메가 #{sp_data.name}#{suffix}"
  end
  form_name = sp_data.form_name
  return form_name if form_name && !form_name.empty?
  return f_id == 0 ? "기본" : "폼 #{f_id}"
end

# 4. 도감 데이터 추출기
def pbExportFullRandomDataHtml
  p_name = ($player ? $player.name : "Player")
  filename = "#{p_name}.html"
  
  pbMessage(_INTL("YeonShirley, class님의 아이디어와 키도군의 완성으로 탄생한 최종 도감 데이터를 생성 중입니다..."))

  stats_on = ($player && $player.respond_to?(:random_stats_new_switch) && $player.random_stats_new_switch)
  ability_on = ($player && $player.respond_to?(:random_ability_new_switch) && $player.random_ability_new_switch)

  evolved_specials = [:SIRFETCHD, :MRRIME, :OBSTAGOON, :PERRSERKER, :CURSOLA, :RUNERIGUS, :WYDEER, :KLEAVOR, :URSALUNA, :BASCULEGION, :SNEASLER, :OVERQWIL]

  dex_map = {}
  c_no = 0
  GameData::Species.each_species { |sp| c_no += 1; dex_map[sp.species] = c_no }

  rows = []
  GameData::Species.each_species do |base_sp|
    s_id = base_sp.species
    all_f_ids = []
    GameData::Species.each { |sp| all_f_ids << sp.form if sp.species == s_id }
    all_f_ids |= [1] if evolved_specials.include?(s_id)
    all_f_ids.sort!

    temp_species_rows = []
    all_f_ids.each do |f_id|
      sp_data = GameData::Species.get_species_form(s_id, f_id) rescue nil
      cat_tag = pbGetFormCategoryTag(sp_data, f_id, s_id)

      if stats_on
        stats = pbGetSpeciesFixedStats(s_id, f_id) rescue (sp_data ? sp_data.base_stats.values : GameData::Species.get(s_id).base_stats.values)
      else
        stats = sp_data ? sp_data.base_stats.values : GameData::Species.get(s_id).base_stats.values
      end
      abi_id = ability_on ? pbGetSpeciesFixedAbility(s_id, f_id) : (sp_data ? sp_data.abilities[0] : GameData::Species.get(s_id).abilities[0])
      abi_name = (GameData::Ability.get(abi_id).name rescue "---")
      
      temp_species_rows << {
        :no => (dex_map[s_id] || 0),
        :name => (sp_data ? sp_data.name : GameData::Species.get(s_id).name),
        :form_display => pbGetRandomExportFormDisplay(sp_data, f_id),
        :cat => cat_tag,
        :ability => abi_name,
        :stats => stats,
        :total => stats.sum,
        :f_id => f_id
      }
    end

    if evolved_specials.include?(s_id)
      temp_species_rows.reject! { |r| r[:f_id] == 0 }
    end
    
    rows.concat(temp_species_rows)
  end

  rows.sort_by! { |r| [r[:no], r[:f_id]] }

  begin
    File.open(filename, "w:UTF-8") { |f| f.write(pbGeneratePokeHtmlV19(rows, p_name)) }
    pbMessage(_INTL("동기화 완료! {1} 파일이 생성되었습니다.", filename))
  rescue => e
    pbMessage(_INTL("저장 오류: {1}", e.message))
  end
end

# 5. HTML 생성기 (검색 기능 강화)
def pbGeneratePokeHtmlV19(rows, p_name)
  gen_at = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  html = "<!doctype html><html lang='ko'><head><meta charset='utf-8'><title>Another Red - #{p_name}</title>"
  html += "<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f4f7f6; padding: 20px; }
    .container { max-width: 1300px; margin: 0 auto; background: #fff; padding: 25px; border-radius: 15px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
    h1 { text-align: center; color: #2d3436; margin-bottom: 5px; }
    .meta { text-align: center; color: #636e72; margin-bottom: 20px; font-size: 13px; border-bottom: 1px solid #eee; padding-bottom: 15px; }
    #search { width: 100%; padding: 15px; border: 2px solid #6c5ce7; border-radius: 10px; margin-bottom: 20px; box-sizing: border-box; outline: none; font-size: 16px; box-shadow: 0 2px 5px rgba(108, 92, 231, 0.2); }
    table { width: 100%; border-collapse: collapse; }
    th { background: #6c5ce7; color: white; padding: 12px; position: sticky; top: 0; font-size: 14px; z-index: 10; }
    td { border-bottom: 1px solid #eee; padding: 10px; text-align: center; font-size: 13px; }
    tr:hover { background: #f8f7ff; }
    .tag { font-size: 11px; padding: 3px 8px; border-radius: 5px; color: white; font-weight: bold; display: inline-block; }
    .tag-mega { background: #e84393; }
    .tag-gmax { background: #d63031; }
    .tag-spec { background: #00b894; }
    .tag-default { background: #b2bec3; }
    .ability { color: #0984e3; font-weight: bold; }
    .total { font-weight: bold; background: #f1f2f6; }
    .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #b2bec3; border-top: 1px solid #eee; padding-top: 15px; }
    .hidden { display: none !important; }
  </style></head><body>"
  html += "<div class='container'><h1>Another Red 도감</h1>"
  html += "<div class='meta'>플레이어: #{p_name} | 아이디어 제공: YeonShirley, class | 완성: 키도군</div>"
  html += "<input type='text' id='search' placeholder='이름, 분류, 상세 폼명(가라르 등), 특성 검색...'>"
  html += "<table><thead><tr><th style='width:60px'>No</th><th>이름</th><th>분류</th><th>상세 폼명</th><th>특성</th><th>HP</th><th>ATK</th><th>DEF</th><th>SPA</th><th>SPD</th><th>SPE</th><th style='width:80px'>합계</th></tr></thead><tbody id='list'>"
  
  rows.each do |r|
    # 검색 데이터에 상세 폼명(r[:form_display])을 추가하여 검색 정확도 향상
    search_str = "#{r[:name]} #{r[:cat]} #{r[:form_display]} #{r[:ability]}".downcase
    tag_class = case r[:cat]
                when "메가진화" then "tag tag-mega"
                when "거다이맥스" then "tag tag-gmax"
                when "특수 폼 진화 체인지" then "tag tag-spec"
                else "tag tag-default"
                end
    html += "<tr data-s='#{search_str}'><td>#{sprintf('%04d', r[:no])}</td>"
    html += "<td style='text-align:left; font-weight:bold;'>#{r[:name]}</td>"
    html += "<td><span class='#{tag_class}'>#{r[:cat]}</span></td>"
    html += "<td><span style='color:#636e72;'>#{r[:form_display]}</span></td>"
    html += "<td class='ability'>#{r[:ability]}</td>"
    r[:stats].each { |s| html += "<td>#{s}</td>" }
    html += "<td class='total'>#{r[:total]}</td></tr>"
  end
  
  html += "</tbody></table>"
  html += "<div class='footer'><b>아이디어 제공:</b> YeonShirley, class | <b>완성:</b> 키도군 | 추출 시각: #{gen_at}</div>"
  html += "</div>"
  html += "<script>
    document.addEventListener('DOMContentLoaded', () => {
      const input = document.getElementById('search');
      const list = document.querySelectorAll('#list tr');
      
      input.addEventListener('input', () => {
        const q = input.value.toLowerCase().trim();
        list.forEach(row => {
          const text = row.getAttribute('data-s');
          if (text.includes(q)) {
            row.classList.remove('hidden');
          } else {
            row.classList.add('hidden');
          }
        });
      });
    });
  </script></body></html>"
  return html
end
