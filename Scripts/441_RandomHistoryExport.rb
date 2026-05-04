# ==============================================================================
# [YeonShirley] Random trainer history columns
#
# This block only observes finalized trainer Pokemon data and export rows.
# It does not change the randomizer's species/stat/ability/move/item algorithms.
# ==============================================================================

class PokemonGlobalMetadata
  def random_trainer_move_history
    @random_trainer_move_history ||= {}
    return @random_trainer_move_history
  end

  def random_trainer_item_history
    @random_trainer_item_history ||= {}
    return @random_trainer_item_history
  end
end

module RandomDataHistory
  MAX_ENTRIES = 20

  def self.dex_cache
    @dex_cache ||= begin
      cache = {}
      no = 0
      GameData::Species.each_species do |sp|
        no += 1
        cache[sp.species] = no
      end
      cache
    end
    return @dex_cache
  end

  def self.key_for(species, form)
    no = dex_cache[species] || 0
    return sprintf("%04d_%d", no, form.to_i)
  end

  def self.key_from_row(row)
    return sprintf("%04d_%d", row[:no].to_i, row[:f_id].to_i)
  end

  def self.ensure_global
    return false if !defined?($PokemonGlobal) || !$PokemonGlobal
    $PokemonGlobal.random_trainer_move_history
    $PokemonGlobal.random_trainer_item_history
    return true
  end

  def self.trainer_label(opponents)
    names = []
    opponents.each do |trainer|
      begin
        names << trainer.full_name
      rescue
        begin
          names << trainer.name.to_s
        rescue
          names << "Trainer"
        end
      end
    end
    return names.empty? ? "Trainer" : names.join(" / ")
  end

  def self.move_ids_for(pkmn)
    ids = []
    pkmn.moves.each do |move|
      next if !move
      begin
        ids << move.id if move.id
      rescue
      end
    end
    return ids
  end

  def self.record_unique(history, key, entry, value_key)
    list = history[key] || []
    list.delete_if { |old| old[:label] == entry[:label] && old[value_key] == entry[value_key] }
    list.unshift(entry)
    history[key] = list[0, MAX_ENTRIES]
  end

  def self.record_trainer_pokemon(pkmn, label)
    return if !ensure_global
    return if !pkmn
    key = key_for(pkmn.species, pkmn.form)

    moves = move_ids_for(pkmn)
    if !moves.empty?
      record_unique(
        $PokemonGlobal.random_trainer_move_history,
        key,
        { :label => label.to_s, :moves => moves },
        :moves
      )
    end

    item = nil
    begin
      item = pkmn.item
    rescue
      item = nil
    end
    if item && item != :NONE
      record_unique(
        $PokemonGlobal.random_trainer_item_history,
        key,
        { :label => label.to_s, :item => item },
        :item
      )
    end
  end

  def self.record_trainer_battle(battle)
    return if !ensure_global
    return if battle.instance_variable_get(:@ys_random_history_recorded)
    opponents = battle.instance_variable_get(:@opponent) || []
    label = trainer_label(opponents)
    party = battle.pbParty(1) rescue []
    party.each { |pkmn| record_trainer_pokemon(pkmn, label) if pkmn }
    battle.instance_variable_set(:@ys_random_history_recorded, true)
  end

  def self.move_name(id)
    begin
      return GameData::Move.get(id).name
    rescue
      return id.to_s
    end
  end

  def self.item_name(id)
    begin
      return GameData::Item.get(id).name
    rescue
      return id.to_s
    end
  end

  def self.move_history_lines(row)
    return [] if !ensure_global
    list = $PokemonGlobal.random_trainer_move_history[key_from_row(row)] || []
    return list.map { |e| "[#{e[:label]}] : #{e[:moves].map { |m| move_name(m) }.join(' | ')}" }
  end

  def self.item_history_lines(row)
    return [] if !ensure_global
    list = $PokemonGlobal.random_trainer_item_history[key_from_row(row)] || []
    return list.map { |e| "[#{e[:label]}] : #{item_name(e[:item])}" }
  end

  def self.html_escape(value)
    text = value.to_s
    text = text.gsub("&", "&amp;")
    text = text.gsub("<", "&lt;")
    text = text.gsub(">", "&gt;")
    text = text.gsub('"', "&quot;")
    return text
  end

  def self.history_cell(lines)
    return "-" if lines.empty?
    label = html_escape(lines[0])
    body = html_escape(lines.join("\n")).gsub("\n", "&#10;")
    return "<button class='hist-btn' data-body=\"#{body}\">#{label}</button>"
  end
end

class Battle
  unless method_defined?(:ys_random_history_pbStartBattleSendOut)
    alias ys_random_history_pbStartBattleSendOut pbStartBattleSendOut

    def pbStartBattleSendOut(sendOuts)
      begin
        RandomDataHistory.record_trainer_battle(self) if trainerBattle?
      rescue
      end
      ys_random_history_pbStartBattleSendOut(sendOuts)
    end
  end
end

def pbGeneratePokeHtmlV19(rows, p_name)
  gen_at = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  h = RandomDataHistory
  html = "<!doctype html><html lang='ko'><head><meta charset='utf-8'><title>Another Red - #{h.html_escape(p_name)}</title>"
  html += "<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f4f7f6; padding: 20px; }
    .container { max-width: 1500px; margin: 0 auto; background: #fff; padding: 25px; border-radius: 15px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
    h1 { text-align: center; color: #2d3436; margin-bottom: 5px; }
    .meta { text-align: center; color: #636e72; margin-bottom: 20px; font-size: 13px; border-bottom: 1px solid #eee; padding-bottom: 15px; }
    #search { width: 100%; padding: 15px; border: 2px solid #6c5ce7; border-radius: 10px; margin-bottom: 20px; box-sizing: border-box; outline: none; font-size: 16px; box-shadow: 0 2px 5px rgba(108, 92, 231, 0.2); }
    .table-wrap { overflow-x: auto; }
    table { width: 100%; min-width: 1420px; border-collapse: collapse; }
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
    .hist-col { max-width: 260px; }
    .hist-btn { display: block; width: 100%; border: 0; background: transparent; color: #0984e3; text-decoration: underline; cursor: pointer; font: inherit; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; text-align: center; }
    .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #b2bec3; border-top: 1px solid #eee; padding-top: 15px; }
    .hidden { display: none !important; }
    .modal-bg { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.45); z-index: 1000; }
    .modal { background: white; max-width: 760px; margin: 8vh auto; border-radius: 10px; box-shadow: 0 12px 35px rgba(0,0,0,0.25); }
    .modal-head { display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-bottom: 1px solid #eee; font-weight: bold; }
    .modal-body { padding: 20px; white-space: pre-line; line-height: 1.8; text-align: left; max-height: 65vh; overflow: auto; }
    .modal-close { border: 0; background: #2d3436; color: white; border-radius: 6px; padding: 8px 14px; cursor: pointer; }
  </style></head><body>"
  html += "<div class='container'><h1>Another Red 랜덤 데이터</h1>"
  html += "<div class='meta'>플레이어: #{h.html_escape(p_name)} | 추출 시각: #{gen_at}</div>"
  html += "<input type='text' id='search' placeholder='이름, 분류, 폼, 특성, 히스토리 검색'>"
  html += "<div class='table-wrap'><table><thead><tr>"
  html += "<th style='width:60px'>No</th><th>이름</th><th>분류</th><th>상세 폼</th><th>특성</th><th>지닌 물건 히스토리</th>"
  html += "<th>HP</th><th>ATK</th><th>DEF</th><th>SPA</th><th>SPD</th><th>SPE</th><th style='width:80px'>합계</th><th>기술 히스토리</th>"
  html += "</tr></thead><tbody id='list'>"

  rows.each do |r|
    move_lines = h.move_history_lines(r)
    item_lines = h.item_history_lines(r)
    search_str = "#{r[:name]} #{r[:cat]} #{r[:form_display]} #{r[:ability]} #{move_lines.join(' ')} #{item_lines.join(' ')}".downcase
    tag_class = case r[:cat]
                when "메가진화" then "tag tag-mega"
                when "거다이맥스" then "tag tag-gmax"
                when "특수 폼 진화 체인지" then "tag tag-spec"
                else "tag tag-default"
                end
    html += "<tr data-s='#{h.html_escape(search_str)}'><td>#{sprintf('%04d', r[:no])}</td>"
    html += "<td style='text-align:left; font-weight:bold;'>#{h.html_escape(r[:name])}</td>"
    html += "<td><span class='#{tag_class}'>#{h.html_escape(r[:cat])}</span></td>"
    html += "<td><span style='color:#636e72;'>#{h.html_escape(r[:form_display])}</span></td>"
    html += "<td class='ability'>#{h.html_escape(r[:ability])}</td>"
    html += "<td class='hist-col'>#{h.history_cell(item_lines)}</td>"
    r[:stats].each { |s| html += "<td>#{s}</td>" }
    html += "<td class='total'>#{r[:total]}</td>"
    html += "<td class='hist-col'>#{h.history_cell(move_lines)}</td></tr>"
  end

  html += "</tbody></table></div>"
  html += "<div class='footer'>추출 시각: #{gen_at}</div>"
  html += "</div>"
  html += "<div class='modal-bg' id='histModal'><div class='modal'><div class='modal-head'><span>히스토리</span><button class='modal-close' id='histClose'>닫기</button></div><div class='modal-body' id='histBody'></div></div></div>"
  html += "<script>
    document.addEventListener('DOMContentLoaded', () => {
      const input = document.getElementById('search');
      const list = document.querySelectorAll('#list tr');
      const modal = document.getElementById('histModal');
      const body = document.getElementById('histBody');
      const close = document.getElementById('histClose');
      input.addEventListener('input', () => {
        const q = input.value.toLowerCase().trim();
        list.forEach(row => {
          const text = row.getAttribute('data-s');
          if (text.includes(q)) row.classList.remove('hidden');
          else row.classList.add('hidden');
        });
      });
      document.querySelectorAll('.hist-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          body.textContent = btn.getAttribute('data-body') || '';
          modal.style.display = 'block';
        });
      });
      close.addEventListener('click', () => { modal.style.display = 'none'; });
      modal.addEventListener('click', e => { if (e.target === modal) modal.style.display = 'none'; });
    });
  </script></body></html>"
  return html
end
