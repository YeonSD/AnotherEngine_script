# ==============================================================================
# [Another Red] DBK & 시스템 호환성 패치 (PP 로드 오류 해결)
# ==============================================================================
module Kernel
  # 'require pp' 호출 시 발생하는 LoadError를 방지합니다.
  alias __another_red_require require unless method_defined?(:__another_red_require)
  def require(path)
    return true if ["pp", "pp.rb"].include?(path.to_s)
    __another_red_require(path)
  end

  # pp 함수가 정의되지 않았을 때를 대비한 안전 정의
  unless self.respond_to?(:pp)
    def pp(*args)
      p(*args) # pp 대신 기본 출력(p)으로 연결
    end
    module_function :pp rescue nil
  end
end