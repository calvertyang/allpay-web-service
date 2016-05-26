[![Gem Version](https://badge.fury.io/rb/allpay-web-service.svg)](http://badge.fury.io/rb/allpay-web-service)
![Analytics](https://ga-beacon.appspot.com/UA-44933497-3/CalvertYang/allpay-web-service?pixel)

# Allpay Web Service

Basic API client for Allpay credit card Web Service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'allpay-web-service'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install allpay-web-service
```

## Usage

#### Initialize

```ruby
require "allpay-web-service"

client = AllpayWebService::Client.new(
  merchant_id: "2000214",
  hash_key: "ejCk326UnaZWKisg",
  hash_iv: "q9jcZX8Ib9LM8wYk"
)
```

## Example

#### Create Trade

* OTP Trade

  ```ruby
  result = client.create_trade(
    ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=CreateTrade",
    MerchantTradeNo: "TEST000001",
    MerchantTradeDate: "2016/05/26 00:00:00",
    TotalAmount: 100,
    TradeDesc: "OTP Trade Test",
    CardNo: 4311952222222222,
    CardValidMM: "12",
    CardValidYY: "20",
    CardCVV2: 222,
    PhoneNumber: "0987654321"
  )
  ```

* Non-OTP Trade

  ```ruby
  result = client.create_trade(
    ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=CreateTrade",
    MerchantTradeNo: "TEST000001",
    MerchantTradeDate: "2016/05/26 00:00:00",
    TotalAmount: 100,
    TradeDesc: "Non-OTP Trade Test",
    CardNo: 4311952222222222,
    CardValidMM: "12",
    CardValidYY: "20",
    CardCVV2: 222
  )
  ```

#### Verify Order By OTP

```ruby
result = client.verify_order_by_otp(
  ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=QueryTrade",
  MerchantTradeNo: "TEST000001",
  TradeNo: "3c4c591f65153095b01",
  OtpCode: "1234"
)
```

#### Resend OTP code

```ruby
result = client.resend_otp(
  ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=ResendOtp",
  MerchantTradeNo: "TEST000001",
  TradeNo: "3c4c591f65153095b01"
)
```

#### Query Trade / Platform Query Trade

* Query Trade

  ```ruby
  result = client.query_trade(
    ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=QueryTrade",
    MerchantTradeNo: "TEST000001"
  )
  ```

* Platform Query Trade

  ```ruby
  result = client.query_trade(
    ServiceURL: "http://pay-stage.allpay.com.tw/merchantapi/creditcard.asmx?op=QueryTrade",
    MerchantTradeNo: "TEST000001",
    PlatformID: "9999999"
  )
  ```

#### Do Action

```ruby
result = client.do_action(
  ServiceURL: "http://pay-stage.allpay.com.tw/CreditDetail/DoAction",
  MerchantTradeNo: "TEST000001",
  TradeNo: "3c4c591f65153095b01",
  Action: "C",
  TotalAmount: 100
)
```

---

#### Result

All methods are return XML/Hash format result.

`result["Xml"]`: XML format result.

`result["Hash"]`: Hash format result.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CalvertYang/allpay-web-service.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
