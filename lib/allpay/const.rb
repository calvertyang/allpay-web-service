module AllpayWebService
  class Base
    def self.readable_keys
      result = self.constants.map { |constant| "#{self.name}::#{constant}" }.join(", ")
      position = result.rindex(", ")
      result[position..position+1] = " or "
      result
    end

    def self.values
      self.constants.map { |constant| self.const_get(constant) }
    end
  end

  # 3D 驗證
  class ThreeD < Base
    # 使用 3D 驗證
    YES = 1
    # 不使用 3D 驗證
    NO = 0
  end

  # 中文編碼格式
  class CharSet < Base
    # UTF-8 編碼
    UTF8 = "utf-8"
    # BIG5 編碼
    BIG5 = "big5"
  end

  # 英文交易
  class English < Base
    # 使用英文交易
    YES = "e"
    # 不使用英文交易
    NO = ""
  end

  # 紅利折抵
  class UseRedeem < Base
    # 使用紅利折抵
    YES = "Y"
    # 不使用紅利折抵
    NO = ""
  end

  # 加入會員
  class AddMember < Base
    # 同意加入
    YES = "1"
    # 不同意加入
    NO = "0"
  end

  # 信用卡訂單處理動作資訊
  class ActionType < Base
    # 關帳
    C = "C"
    # 退刷
    R = "R"
    # 取消
    E = "E"
    # 放棄
    N = "N"
  end
end
