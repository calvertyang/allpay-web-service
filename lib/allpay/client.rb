require "base64"
require "uri"
require "net/http"
require "net/https"
require "nori"
require "cgi"
require "allpay/core_ext/hash"

module AllpayWebService
  class ErrorMessage
    def self.generate args
      case args[:msg]
      when :missing_parameter
        "Missing required parameter: #{args[:field]}"
      when :parameter_should_be
        "#{args[:field]} should be #{args[:data]}"
      when :reach_max_length
        "The maximum length for #{args[:field]} is #{args[:length]}"
      when :wrong_data_format
        "The format for #{args[:field]} is wrong"
      when :cannot_be_empty
        "#{args[:field]} cannot be empty"
      end
    end
  end

  class Client
    attr_accessor :merchant_id, :hash_key, :hash_iv

    def initialize merchant_id:, hash_key:, hash_iv:
      raise_argument_error(msg: :missing_parameter, field: :merchant_id) if merchant_id.nil?
      raise_argument_error(msg: :parameter_should_be, field: :merchant_id, data: "String") unless merchant_id.is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :merchant_id) if merchant_id.empty?
      raise_argument_error(msg: :reach_max_length, field: :merchant_id, length: 10) if merchant_id.size > 10

      raise_argument_error(msg: :missing_parameter, field: :hash_key) if hash_key.nil?
      raise_argument_error(msg: :parameter_should_be, field: :hash_key, data: "String") unless hash_key.is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :hash_key) if hash_key.empty?

      raise_argument_error(msg: :missing_parameter, field: :hash_iv) if hash_iv.nil?
      raise_argument_error(msg: :parameter_should_be, field: :hash_iv, data: "String") unless hash_iv.is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :hash_iv) if hash_iv.empty?

      @merchant_id = merchant_id
      @hash_key = hash_key
      @hash_iv = hash_iv
    end

    # Create trade
    def create_trade args = {}
      raise_argument_error(msg: :parameter_should_be, field: "Parameter", data: "Hash") unless args.is_a? Hash

      # filter arguments by accept keys
      accept_keys = [
        :ServiceURL, :MerchantTradeNo, :MerchantTradeDate, :TotalAmount, :TradeDesc, :CardNo,
        :CardValidMM, :CardValidYY, :CardCVV2, :UnionPay, :Installment, :ThreeD, :CharSet,
        :Enn, :BankOnly, :Redeem, :PhoneNumber, :AddMember, :CName, :Email, :Remark, :PlatformID
      ]
      args = args.filter(accept_keys)

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if args[:ServiceURL].nil?
      raise_argument_error(msg: :parameter_should_be, field: :ServiceURL, data: "String") unless args[:ServiceURL].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :ServiceURL) if args[:ServiceURL].empty?

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if args[:MerchantTradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :MerchantTradeNo, data: "String") unless args[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :MerchantTradeNo) if args[:MerchantTradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :MerchantTradeNo, length: 20) if args[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeDate) if args[:MerchantTradeDate].nil?
      raise_argument_error(msg: :parameter_should_be, field: :MerchantTradeDate, data: "String") unless args[:MerchantTradeDate].is_a? String
      raise_argument_error(msg: :wrong_data_format, field: :MerchantTradeDate) unless /\A\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\z/.match(args[:MerchantTradeDate])

      raise_argument_error(msg: :missing_parameter, field: :TotalAmount) if args[:TotalAmount].nil?
      raise_argument_error(msg: :parameter_should_be, field: :TotalAmount, data: "Integer") unless args[:TotalAmount].is_a? Integer
      raise_argument_error(msg: :parameter_should_be, field: :TotalAmount, data: "greater than 0") if args[:TotalAmount] <= 0

      raise_argument_error(msg: :missing_parameter, field: :TradeDesc) if args[:TradeDesc].nil?
      raise_argument_error(msg: :parameter_should_be, field: :TradeDesc, data: "String") unless args[:TradeDesc].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :TradeDesc) if args[:TradeDesc].empty?
      raise_argument_error(msg: :reach_max_length, field: :TradeDesc, length: 200) if args[:TradeDesc].size > 200

      raise_argument_error(msg: :missing_parameter, field: :CardNo) if args[:CardNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :CardNo, data: "Integer") unless args[:CardNo].is_a? Integer

      raise_argument_error(msg: :missing_parameter, field: :CardValidMM) if args[:CardValidMM].nil?
      raise_argument_error(msg: :parameter_should_be, field: :CardValidMM, data: "String") unless args[:CardValidMM].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :CardValidMM) if args[:CardValidMM].empty?
      raise_argument_error(msg: :reach_max_length, field: :CardValidMM, length: 2) if args[:CardValidMM].size > 2

      raise_argument_error(msg: :missing_parameter, field: :CardValidYY) if args[:CardValidYY].nil?
      raise_argument_error(msg: :parameter_should_be, field: :CardValidYY, data: "String") unless args[:CardValidYY].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :CardValidYY) if args[:CardValidYY].empty?
      raise_argument_error(msg: :reach_max_length, field: :CardValidYY, length: 2) if args[:CardValidYY].size > 2

      if args.has_key? :CardCVV2
        raise_argument_error(msg: :parameter_should_be, field: :CardCVV2, data: "Integer") unless args[:CardCVV2].is_a? Integer
      end

      # NOTE: Web Service 版本都帶 0。
      args.delete :UnionPay if args.has_key? :UnionPay
      # if args.has_key? :UnionPay
      #   raise_argument_error(msg: :parameter_should_be, field: :UnionPay, data: "Integer") unless args[:UnionPay].is_a? Integer
      # end

      if args.has_key? :Installment
        raise_argument_error(msg: :parameter_should_be, field: :Installment, data: "Integer") unless args[:Installment].is_a? Integer
      end

      if args.has_key? :ThreeD
        raise_argument_error(msg: :parameter_should_be, field: :ThreeD, data: "Integer") unless args[:ThreeD].is_a? Integer
        raise_argument_error(msg: :parameter_should_be, field: :ThreeD, data: ThreeD.readable_keys) unless ThreeD.values.include? args[:ThreeD]
      end

      if args.has_key? :CharSet
        raise_argument_error(msg: :parameter_should_be, field: :CharSet, data: "String") unless args[:CharSet].is_a? String
        raise_argument_error(msg: :parameter_should_be, field: :CharSet, data: CharSet.readable_keys) unless CharSet.values.include? args[:CharSet]
      end

      if args.has_key? :Enn
        raise_argument_error(msg: :parameter_should_be, field: :Enn, data: "String") unless args[:Enn].is_a? String
        raise_argument_error(msg: :parameter_should_be, field: :Enn, data: English.readable_keys) unless English.values.include? args[:Enn]
      end

      if args.has_key? :BankOnly
        raise_argument_error(msg: :parameter_should_be, field: :BankOnly, data: "String") unless args[:BankOnly].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :BankOnly, length: 120) if args[:BankOnly].size > 120
      end

      # NOTE: 目前 Web Service 是背景處理授權，尚未開放紅利折抵。
      args.delete :Redeem if args.has_key? :Redeem
      # if args.has_key? :Redeem
      #   raise_argument_error(msg: :parameter_should_be, field: :Redeem, data: "String") unless args[:Redeem].is_a? String
      #   raise_argument_error(msg: :reach_max_length, field: :Redeem, length: 1) if args[:Redeem].size > 1
      # end

      if args.has_key? :PhoneNumber
        raise_argument_error(msg: :parameter_should_be, field: :PhoneNumber, data: "String") unless args[:PhoneNumber].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :PhoneNumber, length: 10) if args[:PhoneNumber].size > 10
      end

      if args.has_key? :AddMember
        raise_argument_error(msg: :parameter_should_be, field: :AddMember, data: "String") unless args[:AddMember].is_a? String
        raise_argument_error(msg: :parameter_should_be, field: :AddMember, data: AddMember.readable_keys) unless AddMember.values.include? args[:AddMember]
      end

      if args[:AddMember] == AddMember::YES
        raise_argument_error(msg: :missing_parameter, field: :CName) if args[:CName].nil?
        raise_argument_error(msg: :parameter_should_be, field: :CName, data: "String") unless args[:CName].is_a? String
        raise_argument_error(msg: :cannot_be_empty, field: :CName) if args[:CName].empty?
        raise_argument_error(msg: :reach_max_length, field: :CName, length: 60) if args[:CName].size > 60
      end

      if args.has_key? :Email
        raise_argument_error(msg: :parameter_should_be, field: :Email, data: "String") unless args[:Email].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :Email, length: 100) if args[:Email].size > 100
      end

      if args.has_key? :Remark
        raise_argument_error(msg: :parameter_should_be, field: :Remark, data: "String") unless args[:Remark].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :Remark, length: 200) if args[:Remark].size > 200
      end

      if args.has_key? :PlatformID
        raise_argument_error(msg: :parameter_should_be, field: :PlatformID, data: "String") unless args[:PlatformID].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :PlatformID, length: 9) if args[:PlatformID].size > 9
      end

      service_url = args[:ServiceURL]
      args.delete :ServiceURL

      data = {
        MerchantID: @merchant_id,
        TradeDesc: "",
        CardCVV2: "",
        UnionPay: 0,
        Installment: 0,
        ThreeD: 0,
        CharSet: "utf-8",
        Enn: "",
        BankOnly: "",
        Redeem: "",
        PhoneNumber: "",
        AddMember: "0",
        CName: "",
        Email: "",
        Remark: "",
        PlatformID: ""
      }.merge(args)
      data[:TradeDesc] = CGI.escape(data[:TradeDesc])[0...200]
      data[:CardValidMM] = data[:CardValidMM].to_s.rjust(2, "0")
      data[:Remark] = CGI.escape(data[:Remark])[0...200]

      post_data = build_post_data trade_type: :create_trade, args: data

      response = request(service_url: service_url, data: post_data, is_soap_request: true)

      parse trade_type: :create_trade, response: response
    end

    # Verify order by otp code
    def verify_order_by_otp args = {}
      raise_argument_error(msg: :parameter_should_be, field: "Parameter", data: "Hash") unless args.is_a? Hash

      # filter argumentss by accept keys
      accept_keys = [
        :ServiceURL, :MerchantTradeNo, :TradeNo, :OtpCode, :PlatformID
      ]
      args = args.filter(accept_keys)

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if args[:ServiceURL].nil?
      raise_argument_error(msg: :parameter_should_be, field: :ServiceURL, data: "String") unless args[:ServiceURL].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :ServiceURL) if args[:ServiceURL].empty?

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if args[:MerchantTradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :MerchantTradeNo, data: "String") unless args[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :MerchantTradeNo) if args[:MerchantTradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :MerchantTradeNo, length: 20) if args[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :TradeNo) if args[:TradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :TradeNo, data: "String") unless args[:TradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :TradeNo) if args[:TradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :TradeNo, length: 20) if args[:TradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :OtpCode) if args[:OtpCode].nil?
      raise_argument_error(msg: :parameter_should_be, field: :OtpCode, data: "String") unless args[:OtpCode].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :OtpCode) if args[:OtpCode].empty?
      raise_argument_error(msg: :reach_max_length, field: :OtpCode, length: 10) if args[:OtpCode].size > 10

      if args.has_key? :PlatformID
        raise_argument_error(msg: :parameter_should_be, field: :PlatformID, data: "String") unless args[:PlatformID].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :PlatformID, length: 9) if args[:PlatformID].size > 9
      end

      service_url = args[:ServiceURL]
      args.delete :ServiceURL

      data = {
        MerchantID: @merchant_id,
        PlatformID: ""
      }.merge(args)

      post_data = build_post_data trade_type: :verify_order_by_otp, args: data

      response = request(service_url: service_url, data: post_data, is_soap_request: true)

      parse trade_type: :verify_order_by_otp, response: response
    end

    # Resend otp code
    def resend_otp args = {}
      raise_argument_error(msg: :parameter_should_be, field: "Parameter", data: "Hash") unless args.is_a? Hash

      # filter arguments by accept keys
      accept_keys = [
        :ServiceURL, :MerchantTradeNo, :TradeNo, :PlatformID
      ]
      args = args.filter(accept_keys)

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if args[:ServiceURL].nil?
      raise_argument_error(msg: :parameter_should_be, field: :ServiceURL, data: "String") unless args[:ServiceURL].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :ServiceURL) if args[:ServiceURL].empty?

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if args[:MerchantTradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :MerchantTradeNo, data: "String") unless args[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :MerchantTradeNo) if args[:MerchantTradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :MerchantTradeNo, length: 20) if args[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :TradeNo) if args[:TradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :TradeNo, data: "String") unless args[:TradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :TradeNo) if args[:TradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :TradeNo, length: 20) if args[:TradeNo].size > 20

      if args.has_key? :PlatformID
        raise_argument_error(msg: :parameter_should_be, field: :PlatformID, data: "String") unless args[:PlatformID].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :PlatformID, length: 9) if args[:PlatformID].size > 9
      end

      service_url = args[:ServiceURL]
      args.delete :ServiceURL

      data = {
        MerchantID: @merchant_id,
        PlatformID: ""
      }.merge(args)

      post_data = build_post_data trade_type: :resend_otp, args: data

      response = request(service_url: service_url, data: post_data, is_soap_request: true)

      parse trade_type: :resend_otp, response: response
    end

    # Query trade information
    def query_trade args = {}
      raise_argument_error(msg: :parameter_should_be, field: "Parameter", data: "Hash") unless args.is_a? Hash

      # filter arguments by accept keys
      accept_keys = [
        :ServiceURL, :MerchantTradeNo, :PlatformID
      ]
      args = args.filter(accept_keys)

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if args[:ServiceURL].nil?
      raise_argument_error(msg: :parameter_should_be, field: :ServiceURL, data: "String") unless args[:ServiceURL].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :ServiceURL) if args[:ServiceURL].empty?

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if args[:MerchantTradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :MerchantTradeNo, data: "String") unless args[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :MerchantTradeNo) if args[:MerchantTradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :MerchantTradeNo, length: 20) if args[:MerchantTradeNo].size > 20

      if args.has_key? :PlatformID
        raise_argument_error(msg: :parameter_should_be, field: :PlatformID, data: "String") unless args[:PlatformID].is_a? String
        raise_argument_error(msg: :cannot_be_empty, field: :PlatformID) if args[:PlatformID].nil? or args[:PlatformID].empty?
        raise_argument_error(msg: :reach_max_length, field: :PlatformID, length: 9) if args[:PlatformID].size > 9
      end

      trade_type = args[:PlatformID].nil? ? :query_trade : :platform_query_trade

      service_url = args[:ServiceURL]
      args.delete :ServiceURL

      data = {
        PlatformID: ""
      }.merge(args)

      post_data = build_post_data trade_type: trade_type, args: data

      response = request(service_url: service_url, data: post_data, is_soap_request: true)

      parse trade_type: :query_trade, response: response
    end

    # Execute action for trade
    def do_action args = {}
      raise_argument_error(msg: :parameter_should_be, field: "Parameter", data: "Hash") unless args.is_a? Hash

      # filter arguments by accept keys
      accept_keys = [
        :ServiceURL, :MerchantTradeNo, :TradeNo, :Action, :TotalAmount, :PlatformID
      ]
      args = args.filter(accept_keys)

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if args[:ServiceURL].nil?
      raise_argument_error(msg: :parameter_should_be, field: :ServiceURL, data: "String") unless args[:ServiceURL].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :ServiceURL) if args[:ServiceURL].empty?

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if args[:MerchantTradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :MerchantTradeNo, data: "String") unless args[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :MerchantTradeNo) if args[:MerchantTradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :MerchantTradeNo, length: 20) if args[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :TradeNo) if args[:TradeNo].nil?
      raise_argument_error(msg: :parameter_should_be, field: :TradeNo, data: "String") unless args[:TradeNo].is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :TradeNo) if args[:TradeNo].empty?
      raise_argument_error(msg: :reach_max_length, field: :TradeNo, length: 20) if args[:TradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :Action) if args[:Action].nil?
      raise_argument_error(msg: :parameter_should_be, field: :Action, data: "String") unless args[:Action].is_a? String
      raise_argument_error(msg: :parameter_should_be, field: :Action, data: ActionType.readable_keys) unless ActionType.values.include? args[:Action]

      raise_argument_error(msg: :missing_parameter, field: :TotalAmount) if args[:TotalAmount].nil?
      raise_argument_error(msg: :parameter_should_be, field: :TotalAmount, data: "Integer") unless args[:TotalAmount].is_a? Integer
      raise_argument_error(msg: :parameter_should_be, field: :TotalAmount, data: "greater than 0") if args[:TotalAmount] <= 0

      if args.has_key? :PlatformID
        raise_argument_error(msg: :parameter_should_be, field: :PlatformID, data: "String") unless args[:PlatformID].is_a? String
        raise_argument_error(msg: :reach_max_length, field: :PlatformID, length: 9) if args[:PlatformID].size > 9
      end

      service_url = args[:ServiceURL]
      args.delete :ServiceURL

      data = {}.merge(args)

      post_data = build_post_data trade_type: :do_action, args: data

      response = request service_url: service_url, data: post_data, platform_id: args[:PlatformID]

      parse trade_type: :do_action, response: response
    end

    private

      def raise_argument_error args
        raise ArgumentError, ErrorMessage.generate(args)
      end

      # Encode(by base64) and encrypt(by AES-128-CBC) data
      def encrypt plain_data
        cipher = OpenSSL::Cipher::AES128.new(:CBC)
        cipher.encrypt
        cipher.key = @hash_key
        cipher.iv = @hash_iv
        encrypted_data = cipher.update(plain_data) + cipher.final
        Base64.strict_encode64(encrypted_data)
      end

      # Decrypt(by AES-128-CBC) and decode(by base64) data
      def decrypt encrypted_data
        encrypted_data = Base64.strict_decode64(encrypted_data)

        decipher = OpenSSL::Cipher::AES128.new(:CBC)
        decipher.decrypt
        decipher.key = @hash_key
        decipher.iv = @hash_iv
        plain_data = decipher.update(encrypted_data) + decipher.final
        CGI.unescape plain_data
      end

      def build_post_data trade_type:, args:
        case trade_type
        when :create_trade
          xml_data= "<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{@merchant_id}</MerchantID><MerchantTradeNo>#{args[:MerchantTradeNo]}</MerchantTradeNo><MerchantTradeDate>#{args[:MerchantTradeDate]}</MerchantTradeDate><TotalAmount>#{args[:TotalAmount]}</TotalAmount><TradeDesc>#{args[:TradeDesc]}</TradeDesc><CardNo>#{args[:CardNo]}</CardNo><CardValidMM>#{args[:CardValidMM]}</CardValidMM><CardValidYY>#{args[:CardValidYY]}</CardValidYY><CardCVV2>#{args[:CardCVV2]}</CardCVV2><UnionPay>#{args[:UnionPay]}</UnionPay><Installment>#{args[:Installment]}</Installment><ThreeD>#{args[:ThreeD]}</ThreeD><CharSet>#{args[:CharSet]}</CharSet><Enn>#{args[:Enn]}</Enn><BankOnly>#{args[:BankOnly]}</BankOnly><Redeem>#{args[:Redeem]}</Redeem><PhoneNumber>#{args[:PhoneNumber]}</PhoneNumber><AddMember>#{args[:AddMember]}</AddMember><CName>#{args[:CName]}</CName><Email>#{args[:Email]}</Email><Remark>#{args[:Remark]}</Remark><PlatformID>#{args[:PlatformID]}</PlatformID></Data></Root>"
          encrypted_data = encrypt(xml_data)
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><CreateTrade xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><xmlData>#{encrypted_data}</xmlData></CreateTrade></soap12:Body></soap12:Envelope>"
        when :verify_order_by_otp
          xml_data = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{args[:MerchantID]}</MerchantID><MerchantTradeNo>#{args[:MerchantTradeNo]}</MerchantTradeNo><TradeNo>#{args[:TradeNo]}</TradeNo><OtpCode>#{args[:OtpCode]}</OtpCode><PlatformID>#{args[:PlatformID]}</PlatformID></Data></Root>"
          encrypted_data = encrypt(xml_data)
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><VerifyOrderByOtp xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><xmlData>#{encrypted_data}</xmlData></VerifyOrderByOtp></soap12:Body></soap12:Envelope>"
        when :resend_otp
          xml_data = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{args[:MerchantID]}</MerchantID><MerchantTradeNo>#{args[:MerchantTradeNo]}</MerchantTradeNo><TradeNo>#{args[:TradeNo]}</TradeNo><PlatformID></PlatformID></Data></Root>"
          encrypted_data = encrypt(xml_data)
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><ResendOtp xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><xmlData>#{encrypted_data}</xmlData></ResendOtp></soap12:Body></soap12:Envelope>"
        when :query_trade
          merchant_trade_no = encrypt(args[:MerchantTradeNo])
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><QueryTrade xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><merchantTradeNo>#{merchant_trade_no}</merchantTradeNo></QueryTrade></soap12:Body></soap12:Envelope>"
        when :platform_query_trade
          merchant_trade_no = encrypt(args[:MerchantTradeNo])
          platform_id = encrypt(args[:PlatformID])
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><PlatformQueryTrade xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><merchantTradeNo>#{merchant_trade_no}</merchantTradeNo><PlatformID>#{platform_id}</PlatformID></PlatformQueryTrade></soap12:Body></soap12:Envelope>"
        when :do_action
          encrypt("<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{@merchant_id}</MerchantID><MerchantTradeNo>#{args[:MerchantTradeNo]}</MerchantTradeNo><TradeNo>#{args[:TradeNo]}</TradeNo><Action>#{args[:Action]}</Action><TotalAmount>#{args[:TotalAmount]}</TotalAmount></Data></Root>")
        end
      end

      def request method: "POST", service_url:, data:, is_soap_request: false, platform_id: nil
        api_url = URI.parse(service_url)

        http = Net::HTTP.new(api_url.host, api_url.port)
        http.use_ssl = true if api_url.scheme == "https"

        req = Net::HTTP::Post.new(api_url.request_uri, initheader = {
          "Accept-Language" => "zh-tw",
          "Accept-Charset" => "utf-8",
          "Content-Type" => is_soap_request ? "application/soap+xml" : "application/x-www-form-urlencoded",
          "Host" => api_url.host
        })

        if is_soap_request
          req.body = data
        else
          form_data = {
            "MerchantID" => @merchant_id,
            "XMLData" => data
          }
          form_data["PlatformID"] = platform_id unless platform_id.nil?

          req.set_form_data(form_data)
        end

        http_response = http.request(req)

        case http_response
        when Net::HTTPOK
          http_response
        when Net::HTTPClientError, Net::HTTPInternalServerError
          raise Net::HTTPError.new(http_response.message, http_response)
        else
          raise Net::HTTPError.new('Unexpected HTTP response.', http_response)
        end
      end

      def parse trade_type:, response:
        res_xml = nil
        res_hash = nil

        case trade_type
        when :create_trade, :verify_order_by_otp, :resend_otp
          if trade_type == :create_trade
            pattern = /<CreateTradeResult>(.+)<\/CreateTradeResult>/
          elsif trade_type == :verify_order_by_otp
            pattern = /<VerifyOrderByOtpResult>(.+)<\/VerifyOrderByOtpResult>/
          elsif trade_type == :resend_otp
            pattern = /<ResendOtpResult>(.+)<\/ResendOtpResult>/
          end

          match_result = pattern.match response.body

          unless match_result.nil?
            encrypted_result = match_result[1]
            res_xml = decrypt(encrypted_result)
          end
        when :query_trade
          pattern = /<QueryTradeResult>(.+)<\/QueryTradeResult>/

          match_result = pattern.match response.body

          unless match_result.nil?
            res_xml = CGI.unescapeHTML match_result[1]
          end
        when :do_action
          res_xml = decrypt(response.body)
        end

        begin
          parser = Nori.new(:advanced_typecasting => false)
          res_hash = parser.parse(res_xml)['Root']['Data'] unless res_xml.nil?
        end

        { "Xml" => res_xml, "Hash" => res_hash }
      end
  end
end
