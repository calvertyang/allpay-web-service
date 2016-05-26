require "base64"
require "uri"
require "net/http"
require "net/https"
require "nori"

module AllpayWebService
  class Response
    attr_accessor :hash, :xml, :errors
  end

  class ErrorMessage
    def self.generate params
      case params[:msg]
      when :missing_parameter
        "Missing required parameter: #{params[:field]}"
      when :wrong_parameter_type
        "Parameter should be #{params[:type]}"
      when :wrong_data
        "#{params[:field]} should be #{params[:data]}"
      when :wrong_length
        "The maximum length for #{params[:field]} is #{params[:length]}"
      when :wrong_format
        "The format for #{params[:field]} is wrong"
      when :cannot_be_empty
        "#{params[:field]} cannot be empty"
      end
    end
  end

  class Client
    attr_accessor :merchant_id, :hash_key, :hash_iv

    def initialize merchant_id:, hash_key:, hash_iv:
      raise_argument_error(msg: :missing_parameter, field: :merchant_id) if merchant_id.nil?
      raise_argument_error(msg: :wrong_data, field: :merchant_id, data: "String") unless merchant_id.is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :merchant_id) if merchant_id.empty?
      raise_argument_error(msg: :wrong_length, field: :merchant_id, length: 10) if merchant_id.size > 10

      raise_argument_error(msg: :missing_parameter, field: :hash_key) if hash_key.nil?
      raise_argument_error(msg: :wrong_data, field: :hash_key, data: "String") unless hash_key.is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :hash_key) if hash_key.empty?

      raise_argument_error(msg: :missing_parameter, field: :hash_iv) if hash_iv.nil?
      raise_argument_error(msg: :wrong_data, field: :hash_iv, data: "String") unless hash_iv.is_a? String
      raise_argument_error(msg: :cannot_be_empty, field: :hash_iv) if hash_iv.empty?

      @merchant_id = merchant_id
      @hash_key = hash_key
      @hash_iv = hash_iv
    end

    # Create trade
    #
    # @param params [Hash] The params to create trade.
    # @return [Response] response data
    def create_trade params = {}
      raise_argument_error(msg: :wrong_parameter_type, type: "Hash") unless params.is_a? Hash

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if params[:ServiceURL].nil?
      raise_argument_error(msg: :wrong_data, field: :ServiceURL, data: "String") unless params[:ServiceURL].is_a? String

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if params[:MerchantTradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :MerchantTradeNo, data: "String") unless params[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :MerchantTradeNo, length: 20) if params[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeDate) if params[:MerchantTradeDate].nil?
      raise_argument_error(msg: :wrong_data, field: :MerchantTradeDate, data: "String") unless params[:MerchantTradeDate].is_a? String
      raise_argument_error(msg: :wrong_length, field: :MerchantTradeDate, length: 20) if params[:MerchantTradeDate].size > 20
      raise_argument_error(msg: :wrong_format, field: :MerchantTradeDate) unless /\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}/.match(params[:MerchantTradeDate])

      raise_argument_error(msg: :missing_parameter, field: :TotalAmount) if params[:TotalAmount].nil?
      raise_argument_error(msg: :wrong_data, field: :TotalAmount, data: "Integer") unless params[:TotalAmount].is_a? Fixnum

      raise_argument_error(msg: :missing_parameter, field: :TradeDesc) if params[:TradeDesc].nil?
      raise_argument_error(msg: :wrong_data, field: :TradeDesc, data: "String") unless params[:TradeDesc].is_a? String
      raise_argument_error(msg: :wrong_length, field: :TradeDesc, length: 200) if params[:TradeDesc].size > 200

      raise_argument_error(msg: :missing_parameter, field: :CardNo) if params[:CardNo].nil?
      raise_argument_error(msg: :wrong_data, field: :CardNo, data: "Integer") unless params[:CardNo].is_a? Fixnum

      raise_argument_error(msg: :missing_parameter, field: :CardValidMM) if params[:CardValidMM].nil?
      raise_argument_error(msg: :wrong_data, field: :CardValidMM, data: "String") unless params[:CardValidMM].is_a? String
      raise_argument_error(msg: :wrong_length, field: :CardValidMM, length: 2) if params[:CardValidMM].size > 2

      raise_argument_error(msg: :missing_parameter, field: :CardValidYY) if params[:CardValidYY].nil?
      raise_argument_error(msg: :wrong_data, field: :CardValidYY, data: "String") unless params[:CardValidYY].is_a? String
      raise_argument_error(msg: :wrong_length, field: :CardValidYY, length: 2) if params[:CardValidYY].size > 2

      if params.has_key? :CardCVV2
        raise_argument_error(msg: :wrong_data, field: :CardCVV2, data: "Integer") unless params[:CardCVV2].is_a? Fixnum
      end

      if params.has_key? :UnionPay
        raise_argument_error(msg: :wrong_data, field: :UnionPay, data: "Integer") unless params[:UnionPay].is_a? Fixnum
      end

      if params.has_key? :Installment
        raise_argument_error(msg: :wrong_data, field: :Installment, data: "Integer") unless params[:Installment].is_a? Fixnum
      end

      if params.has_key? :ThreeD
        raise_argument_error(msg: :wrong_data, field: :ThreeD, data: "Integer") unless params[:ThreeD].is_a? Fixnum
      end

      if params.has_key? :CharSet
        raise_argument_error(msg: :wrong_data, field: :CharSet, data: "String") unless params[:CharSet].is_a? String
        raise_argument_error(msg: :wrong_length, field: :CharSet, length: 10) if params[:CharSet].size > 10
      end

      if params.has_key? :Enn
        raise_argument_error(msg: :wrong_data, field: :Enn, data: "String") unless params[:Enn].is_a? String
        raise_argument_error(msg: :wrong_length, field: :Enn, length: 1) if params[:Enn].size > 1
      end

      if params.has_key? :BankOnly
        raise_argument_error(msg: :wrong_data, field: :BankOnly, data: "String") unless params[:BankOnly].is_a? String
        raise_argument_error(msg: :wrong_length, field: :BankOnly, length: 120) if params[:BankOnly].size > 120
      end

      if params.has_key? :Redeem
        raise_argument_error(msg: :wrong_data, field: :Redeem, data: "String") unless params[:Redeem].is_a? String
        raise_argument_error(msg: :wrong_length, field: :Redeem, length: 1) if params[:Redeem].size > 1
      end

      if params.has_key? :PhoneNumber
        raise_argument_error(msg: :wrong_data, field: :PhoneNumber, data: "String") unless params[:PhoneNumber].is_a? String
        raise_argument_error(msg: :wrong_length, field: :PhoneNumber, length: 10) if params[:PhoneNumber].size > 10
      end

      if params.has_key? :AddMember
        raise_argument_error(msg: :wrong_data, field: :AddMember, data: "String") unless params[:AddMember].is_a? String
        raise_argument_error(msg: :wrong_length, field: :AddMember, length: 1) if params[:AddMember].size > 1
      end

      if params[:AddMember] == 1
        raise_argument_error(msg: :missing_parameter, field: :CName) if params[:CName].nil?
        raise_argument_error(msg: :wrong_data, field: :CName, data: "String") unless params[:CName].is_a? String
        raise_argument_error(msg: :cannot_be_empty, field: :CName) if params[:CName].empty?
        raise_argument_error(msg: :wrong_length, field: :CName, length: 60) if params[:CName].size > 60
      end

      if params.has_key? :Email
        raise_argument_error(msg: :wrong_data, field: :Email, data: "String") unless params[:Email].is_a? String
        raise_argument_error(msg: :wrong_length, field: :Email, length: 100) if params[:Email].size > 100
      end

      if params.has_key? :Remark
        raise_argument_error(msg: :wrong_data, field: :Remark, data: "String") unless params[:Remark].is_a? String
        raise_argument_error(msg: :wrong_length, field: :Remark, length: 200) if params[:Remark].size > 200
      end

      if params.has_key? :PlatformID
        raise_argument_error(msg: :wrong_data, field: :PlatformID, data: "String") unless params[:PlatformID].is_a? String
        raise_argument_error(msg: :wrong_length, field: :PlatformID, length: 9) if params[:PlatformID].size > 9
      end

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
      }.merge(params)
      data[:TradeDesc] = CGI.escape(data[:TradeDesc])[0...200]
      data[:CardValidMM] = data[:CardValidMM].to_s.rjust(2, "0")
      data[:Remark] = CGI.escape(data[:Remark])[0...200]

      post_data = build_post_data trade_type: :create_trade, params: data

      response = request(service_url: params[:ServiceURL], data: post_data, is_soap_request: true)

      parse trade_type: :create_trade, response: response
    end

    # Verify order by otp code
    #
    # @param params [Hash] The params to verify order by otp code.
    # @return [Response] response data
    def verify_order_by_otp params = {}
      raise_argument_error(msg: :wrong_parameter_type, type: "Hash") unless params.is_a? Hash

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if params[:ServiceURL].nil?
      raise_argument_error(msg: :wrong_data, field: :ServiceURL, data: "String") unless params[:ServiceURL].is_a? String

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if params[:MerchantTradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :MerchantTradeNo, data: "String") unless params[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :MerchantTradeNo, length: 20) if params[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :TradeNo) if params[:TradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :TradeNo, data: "String") unless params[:TradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :TradeNo, length: 20) if params[:TradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :OtpCode) if params[:OtpCode].nil?
      raise_argument_error(msg: :wrong_data, field: :OtpCode, data: "String") unless params[:OtpCode].is_a? String
      raise_argument_error(msg: :wrong_length, field: :OtpCode, length: 10) if params[:OtpCode].size > 10

      if params.has_key? :PlatformID
        raise_argument_error(msg: :wrong_data, field: :PlatformID, data: "String") unless params[:PlatformID].is_a? String
        raise_argument_error(msg: :wrong_length, field: :PlatformID, length: 9) if params[:PlatformID].size > 9
      end

      data = {
        MerchantID: @merchant_id,
        PlatformID: ""
      }.merge(params)

      post_data = build_post_data trade_type: :verify_order_by_otp, params: data

      response = request(service_url: params[:ServiceURL], data: post_data, is_soap_request: true)

      parse trade_type: :verify_order_by_otp, response: response
    end

    # Resend otp code
    #
    # @param params [Hash] The params to resend otp code.
    # @return [Response] response data
    def resend_otp params = {}
      raise_argument_error(msg: :wrong_parameter_type, type: "Hash") unless params.is_a? Hash

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if params[:ServiceURL].nil?
      raise_argument_error(msg: :wrong_data, field: :ServiceURL, data: "String") unless params[:ServiceURL].is_a? String

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if params[:MerchantTradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :MerchantTradeNo, data: "String") unless params[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :MerchantTradeNo, length: 20) if params[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :TradeNo) if params[:TradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :TradeNo, data: "String") unless params[:TradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :TradeNo, length: 20) if params[:TradeNo].size > 20

      if params.has_key? :PlatformID
        raise_argument_error(msg: :wrong_data, field: :PlatformID, data: "String") unless params[:PlatformID].is_a? String
        raise_argument_error(msg: :wrong_length, field: :PlatformID, length: 9) if params[:PlatformID].size > 9
      end

      data = {
        MerchantID: @merchant_id,
        PlatformID: ""
      }.merge(params)

      post_data = build_post_data trade_type: :resend_otp, params: data

      response = request(service_url: params[:ServiceURL], data: post_data, is_soap_request: true)

      parse trade_type: :resend_otp, response: response
    end

    # Query trade information
    #
    # @param params [Hash] The params to query trade information.
    # @return [Response] response data
    def query_trade params = {}
      raise_argument_error(msg: :wrong_parameter_type, type: "Hash") unless params.is_a? Hash

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if params[:ServiceURL].nil?
      raise_argument_error(msg: :wrong_data, field: :ServiceURL, data: "String") unless params[:ServiceURL].is_a? String

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if params[:MerchantTradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :MerchantTradeNo, data: "String") unless params[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :MerchantTradeNo, length: 20) if params[:MerchantTradeNo].size > 20

      if params.has_key? :PlatformID
        raise_argument_error(msg: :wrong_data, field: :PlatformID, data: "String") unless params[:PlatformID].is_a? String
        raise_argument_error(msg: :cannot_be_empty, field: :PlatformID) if params[:PlatformID].nil? or params[:PlatformID].empty?
        raise_argument_error(msg: :wrong_length, field: :PlatformID, length: 9) if params[:PlatformID].size > 9
      end

      trade_type = params[:PlatformID].nil? ? :query_trade : :platform_query_trade

      data = {
        PlatformID: ""
      }.merge(params)

      post_data = build_post_data trade_type: trade_type, params: data

      response = request(service_url: params[:ServiceURL], data: post_data, is_soap_request: true)

      parse trade_type: :query_trade, response: response
    end

    # Execute action for trade
    #
    # @param params [Hash] The params to execute action for trade. See the official manual for more information.
    # @return [Response] response data
    def do_action params = {}
      raise_argument_error(msg: :wrong_parameter_type, type: "Hash") unless params.is_a? Hash

      raise_argument_error(msg: :missing_parameter, field: :ServiceURL) if params[:ServiceURL].nil?
      raise_argument_error(msg: :wrong_data, field: :ServiceURL, data: "String") unless params[:ServiceURL].is_a? String

      raise_argument_error(msg: :missing_parameter, field: :MerchantTradeNo) if params[:MerchantTradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :MerchantTradeNo, data: "String") unless params[:MerchantTradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :MerchantTradeNo, length: 20) if params[:MerchantTradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :TradeNo) if params[:TradeNo].nil?
      raise_argument_error(msg: :wrong_data, field: :TradeNo, data: "String") unless params[:TradeNo].is_a? String
      raise_argument_error(msg: :wrong_length, field: :TradeNo, length: 20) if params[:TradeNo].size > 20

      raise_argument_error(msg: :missing_parameter, field: :Action) if params[:Action].nil?
      raise_argument_error(msg: :wrong_data, field: :Action, data: "String") unless params[:Action].is_a? String
      raise_argument_error(msg: :wrong_length, field: :Action, length: 1) if params[:Action].size > 1

      raise_argument_error(msg: :missing_parameter, field: :TotalAmount) if params[:TotalAmount].nil?
      raise_argument_error(msg: :wrong_data, field: :TotalAmount, data: "Integer") unless params[:TotalAmount].is_a? Fixnum

      if params.has_key? :PlatformID
        raise_argument_error(msg: :wrong_data, field: :PlatformID, data: "String") unless params[:PlatformID].is_a? String
        raise_argument_error(msg: :wrong_length, field: :PlatformID, length: 9) if params[:PlatformID].size > 9
      end

      data = {}.merge(params)

      post_data = build_post_data trade_type: :do_action, params: data

      response = request service_url: params[:ServiceURL], data: post_data, platform_id: params[:PlatformID]

      parse trade_type: :do_action, response: response
    end

    private

      def raise_argument_error params
        raise ArgumentError, ErrorMessage.generate(params)
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

      def build_post_data trade_type:, params:
        case trade_type
        when :create_trade
          xml_data= "<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{@merchant_id}</MerchantID><MerchantTradeNo>#{params[:MerchantTradeNo]}</MerchantTradeNo><MerchantTradeDate>#{params[:MerchantTradeDate]}</MerchantTradeDate><TotalAmount>#{params[:TotalAmount]}</TotalAmount><TradeDesc>#{params[:TradeDesc]}</TradeDesc><CardNo>#{params[:CardNo]}</CardNo><CardValidMM>#{params[:CardValidMM]}</CardValidMM><CardValidYY>#{params[:CardValidYY]}</CardValidYY><CardCVV2>#{params[:CardCVV2]}</CardCVV2><UnionPay>#{params[:UnionPay]}</UnionPay><Installment>#{params[:Installment]}</Installment><ThreeD>#{params[:ThreeD]}</ThreeD><CharSet>#{params[:CharSet]}</CharSet><Enn>#{params[:Enn]}</Enn><BankOnly>#{params[:BankOnly]}</BankOnly><Redeem>#{params[:Redeem]}</Redeem><PhoneNumber>#{params[:PhoneNumber]}</PhoneNumber><AddMember>#{params[:AddMember]}</AddMember><CName>#{params[:CName]}</CName><Email>#{params[:Email]}</Email><Remark>#{params[:Remark]}</Remark><PlatformID>#{params[:PlatformID]}</PlatformID></Data></Root>"
          encrypted_data = encrypt(xml_data)
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><CreateTrade xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><xmlData>#{encrypted_data}</xmlData></CreateTrade></soap12:Body></soap12:Envelope>"
        when :verify_order_by_otp
          xml_data = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{params[:MerchantID]}</MerchantID><MerchantTradeNo>#{params[:MerchantTradeNo]}</MerchantTradeNo><TradeNo>#{params[:TradeNo]}</TradeNo><OtpCode>#{params[:OtpCode]}</OtpCode><PlatformID>#{params[:PlatformID]}</PlatformID></Data></Root>"
          encrypted_data = encrypt(xml_data)
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><VerifyOrderByOtp xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><xmlData>#{encrypted_data}</xmlData></VerifyOrderByOtp></soap12:Body></soap12:Envelope>"
        when :resend_otp
          xml_data = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{params[:MerchantID]}</MerchantID><MerchantTradeNo>#{params[:MerchantTradeNo]}</MerchantTradeNo><TradeNo>#{params[:TradeNo]}</TradeNo><PlatformID></PlatformID></Data></Root>"
          encrypted_data = encrypt(xml_data)
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><ResendOtp xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><xmlData>#{encrypted_data}</xmlData></ResendOtp></soap12:Body></soap12:Envelope>"
        when :query_trade
          merchant_trade_no = encrypt(params[:MerchantTradeNo])
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><QueryTrade xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><merchantTradeNo>#{merchant_trade_no}</merchantTradeNo></QueryTrade></soap12:Body></soap12:Envelope>"
        when :platform_query_trade
          merchant_trade_no = encrypt(params[:MerchantTradeNo])
          platform_id = encrypt(params[:PlatformID])
          "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><PlatformQueryTrade xmlns=\"http://PaymentCenter.AllPay.com.tw/\"><merchantID>#{@merchant_id}</merchantID><merchantTradeNo>#{merchant_trade_no}</merchantTradeNo><PlatformID>#{platform_id}</PlatformID></PlatformQueryTrade></soap12:Body></soap12:Envelope>"
        when :do_action
          encrypt("<?xml version=\"1.0\" encoding=\"utf-8\" ?><Root><Data><MerchantID>#{@merchant_id}</MerchantID><MerchantTradeNo>#{params[:MerchantTradeNo]}</MerchantTradeNo><TradeNo>#{params[:TradeNo]}</TradeNo><Action>#{params[:Action]}</Action><TotalAmount>#{params[:TotalAmount]}</TotalAmount></Data></Root>")
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
          raise Net::HTTPError, http_response.message
        else
          raise Net::HTTPError, "Unexpected HTTP response."
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
