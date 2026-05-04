#===============================================================================
# 포켓몬에 잠재 능력 해방 효과를 저장하기 위한 변수 추가
#===============================================================================
class Pokemon
  attr_accessor :unleashed_potential_stat

  # 게임을 저장하고 로드할 때를 대비해 변수를 초기화합니다.
  alias _potential_initialize initialize
  def initialize(*args)
    _potential_initialize(*args)
    @unleashed_potential_stat = nil
  end
end