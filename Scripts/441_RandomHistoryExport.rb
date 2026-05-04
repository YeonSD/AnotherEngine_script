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
    body { font-family: 'Malgun Gothic', sans-serif; background: #f4f7f6; padding: 20px 20px 46px; overflow-x: hidden; }
    .container { width: 100%; max-width: 1500px; box-sizing: border-box; margin: 0 auto; background: #fff; padding: 25px; border-radius: 15px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); overflow: hidden; }
    h1 { text-align: center; color: #2d3436; margin-bottom: 5px; }
    .meta { text-align: center; color: #636e72; margin-bottom: 20px; font-size: 13px; border-bottom: 1px solid #eee; padding-bottom: 15px; }
    .table-wrap { width: 100%; overflow-x: auto; scrollbar-width: none; }
    .table-wrap::-webkit-scrollbar { display: none; }
    table { width: 100%; min-width: 1240px; border-collapse: collapse; }
    th { background: #6c5ce7; color: white; padding: 12px; position: sticky; top: 0; font-size: 14px; z-index: 10; }
    th.sortable { cursor: pointer; user-select: none; }
    th.sortable .arrow { display: inline-block; margin-left: 6px; font-size: 11px; opacity: 0.95; }
    td { border-bottom: 1px solid #eee; padding: 10px; text-align: center; font-size: 13px; }
    .sticky-no { position: sticky; left: 0; z-index: 6; min-width: 60px; width: 60px; }
    .sticky-name { position: sticky; left: 60px; z-index: 6; min-width: 150px; width: 150px; }
    th.sticky-no, th.sticky-name { z-index: 20; }
    td.sticky-no, td.sticky-name { background: #fff; }
    tr:hover td.sticky-no, tr:hover td.sticky-name { background: #f8f7ff; }
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
    .fixed-scroll { position: fixed; left: 0; right: 0; bottom: 0; height: 22px; overflow-x: auto; overflow-y: hidden; background: rgba(244,247,246,0.96); z-index: 900; }
    .fixed-scroll-inner { height: 1px; }
  </style></head><body>"
  html += "<div class='container'><h1>Another Red 랜덤 데이터</h1>"
  html += "<div class='meta'>플레이어: #{h.html_escape(p_name)} | 추출 시각: #{gen_at}</div>"
  html += "<div class='table-wrap'><table><thead><tr>"
  html += "<th class='sticky-no'>No</th><th class='sticky-name'>이름</th><th>분류</th><th>상세 폼</th><th>특성</th>"
  html += "<th class='sortable' data-col='5'>HP<span class='arrow'>↕</span></th>"
  html += "<th class='sortable' data-col='6'>ATK<span class='arrow'>↕</span></th>"
  html += "<th class='sortable' data-col='7'>DEF<span class='arrow'>↕</span></th>"
  html += "<th class='sortable' data-col='8'>SPA<span class='arrow'>↕</span></th>"
  html += "<th class='sortable' data-col='9'>SPD<span class='arrow'>↕</span></th>"
  html += "<th class='sortable' data-col='10'>SPE<span class='arrow'>↕</span></th>"
  html += "<th class='sortable' data-col='11' style='width:80px'>합계<span class='arrow'>↕</span></th>"
  html += "</tr></thead><tbody id='list'>"

  rows.each_with_index do |r, row_index|
    tag_class = case r[:cat]
                when "메가진화" then "tag tag-mega"
                when "거다이맥스" then "tag tag-gmax"
                when "특수 폼 진화 체인지" then "tag tag-spec"
                else "tag tag-default"
                end
    html += "<tr data-original='#{row_index}'><td class='sticky-no'>#{sprintf('%04d', r[:no])}</td>"
    html += "<td class='sticky-name' style='text-align:left; font-weight:bold;'>#{h.html_escape(r[:name])}</td>"
    html += "<td><span class='#{tag_class}'>#{h.html_escape(r[:cat])}</span></td>"
    html += "<td><span style='color:#636e72;'>#{h.html_escape(r[:form_display])}</span></td>"
    html += "<td class='ability'>#{h.html_escape(r[:ability])}</td>"
    r[:stats].each { |s| html += "<td>#{s}</td>" }
    html += "<td class='total'>#{r[:total]}</td></tr>"
  end

  html += "</tbody></table></div>"
  html += "<div class='footer'>추출 시각: #{gen_at}</div>"
  html += "</div>"
  html += "<div class='fixed-scroll' id='fixedScroll'><div class='fixed-scroll-inner' id='fixedScrollInner'></div></div>"
  html += "<script>
    document.addEventListener('DOMContentLoaded', () => {
      const tbody = document.getElementById('list');
      const tableWrap = document.querySelector('.table-wrap');
      const fixedScroll = document.getElementById('fixedScroll');
      const fixedScrollInner = document.getElementById('fixedScrollInner');
      const sortState = { col: null, dir: 0 };
      const resetArrows = () => {
        document.querySelectorAll('th.sortable .arrow').forEach(arrow => { arrow.textContent = '↕'; });
      };
      const numericValue = (row, col) => {
        const cell = row.children[col];
        const value = cell ? parseFloat(cell.textContent.replace(/,/g, '')) : 0;
        return isNaN(value) ? 0 : value;
      };
      document.querySelectorAll('th.sortable').forEach(th => {
        th.addEventListener('click', () => {
          const col = parseInt(th.getAttribute('data-col'), 10);
          if (sortState.col !== col) {
            sortState.col = col;
            sortState.dir = 1;
          } else {
            sortState.dir = (sortState.dir + 1) % 3;
          }
          resetArrows();
          if (sortState.dir === 0) {
            Array.from(tbody.rows)
              .sort((a, b) => parseInt(a.dataset.original, 10) - parseInt(b.dataset.original, 10))
              .forEach(row => tbody.appendChild(row));
            sortState.col = null;
            return;
          }
          th.querySelector('.arrow').textContent = sortState.dir === 1 ? '↑' : '↓';
          Array.from(tbody.rows)
            .sort((a, b) => {
              const diff = numericValue(a, col) - numericValue(b, col);
              if (diff !== 0) return sortState.dir === 1 ? diff : -diff;
              return parseInt(a.dataset.original, 10) - parseInt(b.dataset.original, 10);
            })
            .forEach(row => tbody.appendChild(row));
        });
      });
      const syncWidth = () => {
        const maxTableScroll = Math.max(0, tableWrap.scrollWidth - tableWrap.clientWidth);
        fixedScrollInner.style.width = `${fixedScroll.clientWidth + maxTableScroll}px`;
        fixedScroll.style.display = maxTableScroll > 1 ? 'block' : 'none';
      };
      let syncing = false;
      fixedScroll.addEventListener('scroll', () => {
        if (syncing) return;
        syncing = true;
        tableWrap.scrollLeft = fixedScroll.scrollLeft;
        syncing = false;
      });
      tableWrap.addEventListener('scroll', () => {
        if (syncing) return;
        syncing = true;
        fixedScroll.scrollLeft = tableWrap.scrollLeft;
        syncing = false;
      });
      window.addEventListener('resize', syncWidth);
      syncWidth();
    });
  </script></body></html>"
  return html
end
