# ==============================================================================
# Auto Multi Save 플러그인 에러 수정용 패치 (v21.1 character_ID 기반)
# ==============================================================================
class Player
  # male? 명령어가 없으면 만들어줍니다. (보통 캐릭터 번호 0번이 남자)
  if !method_defined?(:male?)
    def male?
      return self.character_ID == 0 if respond_to?(:character_ID)
      return true # 만약 에러가 나면 기본값으로 남자를 반환
    end
  end
  
  # female? 명령어가 없으면 만들어줍니다. (보통 캐릭터 번호 1번이 여자)
  if !method_defined?(:female?)
    def female?
      return self.character_ID == 1 if respond_to?(:character_ID)
      return false
    end
  end
end