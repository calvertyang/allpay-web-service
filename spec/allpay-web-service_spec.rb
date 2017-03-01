require "spec_helper"

otp_client = AllpayWebService::Client.new(merchant_id: "2000132", hash_key: "ejCk326UnaZWKisg", hash_iv: "q9jcZX8Ib9LM8wYk")
non_otp_client = AllpayWebService::Client.new(merchant_id: "2000214", hash_key: "ejCk326UnaZWKisg", hash_iv: "q9jcZX8Ib9LM8wYk")

otp_trade = nil
non_otp_trade = nil

describe AllpayWebService::Client do
  describe ".create_trade" do
    it "should check type of argument" do
      expect {non_otp_client.create_trade(nil)}.to raise_error(ArgumentError, /\AParameter should be \w+\z/)
    end

    it "should check required parameter" do
      expect {non_otp_client.create_trade({
        MerchantTradeNo: SecureRandom.hex(10)
      })}.to raise_error(ArgumentError, /\AMissing required parameter: \w+\z/)
    end

    it "should create OTP transaction" do
      current_year = Time.now.strftime("%y").to_i
      otp_trade = otp_client.create_trade({
        ServiceURL: "https://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=CreateTrade",
        MerchantTradeNo: SecureRandom.hex(10),
        MerchantTradeDate: Time.now.strftime("%Y/%m/%d %T"),
        TotalAmount: rand(100..500),
        TradeDesc: "OTP 交易測試",
        CardNo: 4311_9522_2222_2222,
        CardValidMM: rand(1..12).to_s,
        CardValidYY: rand((current_year + 1)..(current_year + 10)).to_s,
        CardCVV2: 222,
        PhoneNumber: "0987654321"
      })

      expect(otp_trade).to be_a(Hash)
      expect(otp_trade).to have_key("Xml")
      expect(otp_trade["Xml"]).to be_a(String)
      expect(otp_trade).to have_key("Hash")
      expect(otp_trade["Hash"]).to be_a(Hash)

      response_hash = otp_trade["Hash"]

      expect(response_hash).to have_key("MerchantID")
      expect(response_hash).to have_key("MerchantTradeNo")
      expect(response_hash).to have_key("TradeNo")
      expect(response_hash).to have_key("RtnCode")
      expect(response_hash).to have_key("RtnMsg")
      expect(response_hash).to have_key("TradeDate")
      expect(response_hash).to have_key("OtpExpiredTime")
    end

    it "should create non-OTP transaction" do
      skip
      current_year = Time.now.strftime("%y").to_i
      non_otp_trade = non_otp_client.create_trade({
        ServiceURL: "https://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=CreateTrade",
        MerchantTradeNo: SecureRandom.hex(10),
        MerchantTradeDate: Time.now.strftime("%Y/%m/%d %T"),
        TotalAmount: rand(100..500),
        TradeDesc: "非 OTP 交易測試",
        CardNo: 4311952222222222,
        CardValidMM: rand(1..12).to_s,
        CardValidYY: rand((current_year + 1)..(current_year + 10)).to_s,
        CardCVV2: 222
      })

      expect(non_otp_trade).to be_a(Hash)
      expect(non_otp_trade).to have_key("Xml")
      expect(non_otp_trade["Xml"]).to be_a(String)
      expect(non_otp_trade).to have_key("Hash")
      expect(non_otp_trade["Hash"]).to be_a(Hash)

      response_hash = non_otp_trade["Hash"]

      expect(response_hash).to have_key("MerchantID")
      expect(response_hash).to have_key("MerchantTradeNo")
      expect(response_hash).to have_key("TradeNo")
      expect(response_hash).to have_key("OtpResult")
      expect(response_hash).to have_key("RtnCode")
      expect(response_hash).to have_key("RtnMsg")
      expect(response_hash).to have_key("gwsr")
      expect(response_hash).to have_key("process_date")
      expect(response_hash).to have_key("auth_code")
      expect(response_hash).to have_key("amount")
      expect(response_hash).to have_key("stage")
      expect(response_hash).to have_key("stast")
      expect(response_hash).to have_key("staed")
      expect(response_hash).to have_key("eci")
      expect(response_hash).to have_key("card4no")
      expect(response_hash).to have_key("card6no")
      expect(response_hash).to have_key("red_dan")
      expect(response_hash).to have_key("red_de_amt")
      expect(response_hash).to have_key("red_ok_amt")
      expect(response_hash).to have_key("red_yet")
    end
  end

  describe ".verify_order_by_otp" do
    it "should check type of argument" do
      expect {non_otp_client.verify_order_by_otp(nil)}.to raise_error(ArgumentError, /\AParameter should be \w+\z/)
    end

    it "should check required parameter" do
      expect {non_otp_client.verify_order_by_otp({
        MerchantTradeNo: otp_trade["Hash"]["MerchantTradeNo"],
        TradeNo: otp_trade["Hash"]["TradeNo"],
        OtpCode: "1111"
      })}.to raise_error(ArgumentError, /\AMissing required parameter: \w+\z/)
    end

    it "should verify order by OTP" do
      skip
      result = otp_client.verify_order_by_otp({
        ServiceURL: "https://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=QueryTrade",
        MerchantTradeNo: otp_trade["Hash"]["MerchantTradeNo"],
        TradeNo: otp_trade["Hash"]["TradeNo"],
        OtpCode: "1111"
      })

      expect(result).to be_a(Hash)
      expect(result).to have_key("Xml")
      expect(result["Xml"]).to be_a(String)
      expect(result).to have_key("Hash")
      expect(result["Hash"]).to be_a(Hash)

      response_hash = result["Hash"]

      expect(response_hash).to have_key("MerchantID")
      expect(response_hash).to have_key("MerchantTradeNo")
      expect(response_hash).to have_key("TradeNo")
      expect(response_hash).to have_key("OtpResult")
      expect(response_hash).to have_key("RtnCode")
      expect(response_hash).to have_key("RtnMsg")
      expect(response_hash).to have_key("gwsr")
      expect(response_hash).to have_key("process_date")
      expect(response_hash).to have_key("auth_code")
      expect(response_hash).to have_key("amount")
      expect(response_hash).to have_key("stage")
      expect(response_hash).to have_key("stast")
      expect(response_hash).to have_key("staed")
      expect(response_hash).to have_key("eci")
      expect(response_hash).to have_key("card4no")
      expect(response_hash).to have_key("card6no")
      expect(response_hash).to have_key("red_dan")
      expect(response_hash).to have_key("red_de_amt")
      expect(response_hash).to have_key("red_ok_amt")
      expect(response_hash).to have_key("red_yet")
    end
  end

  describe ".resend_otp" do
    it "should check type of argument" do
      expect {non_otp_client.resend_otp(nil)}.to raise_error(ArgumentError, /\AParameter should be \w+\z/)
    end

    it "should check required parameter" do
      expect {non_otp_client.resend_otp({
        MerchantTradeNo: otp_trade["Hash"]["MerchantTradeNo"],
        TradeNo: otp_trade["Hash"]["TradeNo"]
      })}.to raise_error(ArgumentError, /\AMissing required parameter: \w+\z/)
    end

    it "should resend OTP code" do
      skip
      result = otp_client.resend_otp({
        ServiceURL: "https://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=ResendOtp",
        MerchantTradeNo: otp_trade["Hash"]["MerchantTradeNo"],
        TradeNo: otp_trade["Hash"]["TradeNo"]
      })

      expect(result).to be_a(Hash)
      expect(result).to have_key("Xml")
      expect(result["Xml"]).to be_a(String)
      expect(result).to have_key("Hash")
      expect(result["Hash"]).to be_a(Hash)

      response_hash = result["Hash"]

      expect(response_hash).to have_key("MerchantID")
      expect(response_hash).to have_key("MerchantTradeNo")
      expect(response_hash).to have_key("TradeNo")
      expect(response_hash).to have_key("RtnCode")
      expect(response_hash).to have_key("RtnMsg")
    end
  end

  describe ".query_trade" do
    it "should check type of argument" do
      expect {non_otp_client.query_trade(nil)}.to raise_error(ArgumentError, /\AParameter should be \w+\z/)
    end

    it "should check required parameter" do
      skip
      expect {non_otp_client.query_trade({
        MerchantTradeNo: non_otp_trade["Hash"]["MerchantTradeNo"]
      })}.to raise_error(ArgumentError, /\AMissing required parameter: \w+\z/)
    end

    it "should query transaction" do
      skip
      result = non_otp_client.query_trade({
        ServiceURL: "https://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=QueryTrade",
        MerchantTradeNo: non_otp_trade["Hash"]["MerchantTradeNo"]
      })

      expect(result).to be_a(Hash)
      expect(result).to have_key("Xml")
      expect(result["Xml"]).to be_a(String)
      expect(result).to have_key("Hash")
      expect(result["Hash"]).to be_a(Hash)

      response_hash = result["Hash"]

      expect(response_hash).to have_key("MerchantID")
      expect(response_hash).to have_key("MerchantTradeNo")
      expect(response_hash).to have_key("TradeNo")
      expect(response_hash).to have_key("RtnCode")
      expect(response_hash).to have_key("gwsr")
      expect(response_hash).to have_key("process_date")
      expect(response_hash).to have_key("auth_code")
      expect(response_hash).to have_key("amount")
      expect(response_hash).to have_key("stage")
      expect(response_hash).to have_key("stast")
      expect(response_hash).to have_key("staed")
      expect(response_hash).to have_key("eci")
      expect(response_hash).to have_key("card4no")
      expect(response_hash).to have_key("card6no")
      expect(response_hash).to have_key("red_dan")
      expect(response_hash).to have_key("red_de_amt")
      expect(response_hash).to have_key("red_ok_amt")
      expect(response_hash).to have_key("red_yet")
    end
  end

  describe ".do_action" do
    it "should check type of argument" do
      expect {non_otp_client.do_action(nil)}.to raise_error(ArgumentError, /\AParameter should be \w+\z/)
    end

    it "should check required parameter" do
      skip
      expect {non_otp_client.do_action({
        MerchantTradeNo: non_otp_trade["Hash"]["MerchantTradeNo"],
        TradeNo: non_otp_trade["Hash"]["TradeNo"],
        Action: "C",
        TotalAmount: non_otp_trade["Hash"]["amount"].to_i
      })}.to raise_error(ArgumentError, /\AMissing required parameter: \w+\z/)
    end

    it "should do an action" do
      skip
      result = non_otp_client.do_action({
        ServiceURL: "https://payment-stage.allpay.com.tw/CreditDetail/DoAction",
        MerchantTradeNo: non_otp_trade["Hash"]["MerchantTradeNo"],
        TradeNo: non_otp_trade["Hash"]["TradeNo"],
        Action: "C",
        TotalAmount: non_otp_trade["Hash"]["amount"].to_i
      })

      expect(result).to be_a(Hash)
      expect(result).to have_key("Xml")
      expect(result["Xml"]).to be_a(String)
      expect(result).to have_key("Hash")
      expect(result["Hash"]).to be_a(Hash)

      response_hash = result["Hash"]

      expect(response_hash).to have_key("MerchantID")
      expect(response_hash).to have_key("MerchantTradeNo")
      expect(response_hash).to have_key("TradeNo")
      expect(response_hash).to have_key("RtnCode")
      expect(response_hash).to have_key("RtnMsg")
    end
  end
end
