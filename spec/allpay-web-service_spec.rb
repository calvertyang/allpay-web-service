require "allpay-web-service"
require "securerandom"

describe AllpayWebService::Client do
  before :all do
    @otp_client = AllpayWebService::Client.new(merchant_id: "2000132", hash_key: "ejCk326UnaZWKisg", hash_iv: "q9jcZX8Ib9LM8wYk")
    @non_otp_client = AllpayWebService::Client.new(merchant_id: "2000214", hash_key: "ejCk326UnaZWKisg", hash_iv: "q9jcZX8Ib9LM8wYk")
  end

  trade_response = nil

  it "should create OTP transaction" do
    current_year = Time.now.strftime("%y").to_i
    trade_response = @otp_client.create_trade(
      ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=CreateTrade",
      MerchantTradeNo: SecureRandom.hex(10),
      MerchantTradeDate: Time.now.strftime("%Y/%m/%d %T"),
      TotalAmount: rand(100..500),
      TradeDesc: "OTP 交易測試",
      CardNo: 4311952222222222,
      CardValidMM: rand(1..12).to_s,
      CardValidYY: rand((current_year + 1)..(current_year + 10)).to_s,
      CardCVV2: 222,
      PhoneNumber: "0987654321"
    )

    expect(trade_response["Hash"]["RtnCode"]).to eq "1"
  end

  it "should resend OTP code" do
    resend_otp_response = @otp_client.resend_otp(
      ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=ResendOtp",
      MerchantTradeNo: trade_response["Hash"]["MerchantTradeNo"],
      TradeNo: trade_response["Hash"]["TradeNo"]
    )

    expect(resend_otp_response["Hash"]["RtnCode"]).not_to eq "1"
  end

  it "should verify order by OTP" do
    trade_response = @otp_client.verify_order_by_otp(
      ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=QueryTrade",
      MerchantTradeNo: trade_response["Hash"]["MerchantTradeNo"],
      TradeNo: trade_response["Hash"]["TradeNo"],
      OtpCode: "1111"
    )

    expect(trade_response["Hash"]["RtnCode"]).not_to eq "1"
  end

  it "should create non-OTP transaction" do
    current_year = Time.now.strftime("%y").to_i
    trade_response = @non_otp_client.create_trade(
      ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=CreateTrade",
      MerchantTradeNo: SecureRandom.hex(10),
      MerchantTradeDate: Time.now.strftime("%Y/%m/%d %T"),
      TotalAmount: rand(100..500),
      TradeDesc: "非 OTP 交易測試",
      CardNo: 4311952222222222,
      CardValidMM: rand(1..12).to_s,
      CardValidYY: rand((current_year + 1)..(current_year + 10)).to_s,
      CardCVV2: 222
    )

    expect(trade_response["Hash"]["RtnCode"]).to eq "1"
  end

  it "should query transaction" do
    query_trade_response = @non_otp_client.query_trade(
      ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=QueryTrade",
      MerchantTradeNo: trade_response["Hash"]["MerchantTradeNo"]
    )

    expect(query_trade_response["Hash"]["MerchantID"]).to eq trade_response["Hash"]["MerchantID"]
    expect(query_trade_response["Hash"]["MerchantTradeNo"]).to eq trade_response["Hash"]["MerchantTradeNo"]
    expect(query_trade_response["Hash"]["TradeNo"]).to eq trade_response["Hash"]["TradeNo"]
  end

  it "should do action" do
    do_action_response = @non_otp_client.do_action(
      ServiceURL: "http://pay-stage.allpay.com.tw/CreditDetail/DoAction",
      MerchantTradeNo: trade_response["Hash"]["MerchantTradeNo"],
      TradeNo: trade_response["Hash"]["TradeNo"],
      Action: "C",
      TotalAmount: trade_response["Hash"]["amount"].to_i
    )

    expect(do_action_response["Hash"]["RtnCode"]).not_to eq "1"
  end
end
