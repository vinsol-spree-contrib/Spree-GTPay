Spree GTPay  [![Code Climate](https://codeclimate.com/github/vinsol/Spree-Gtpay.png)](https://codeclimate.com/github/vinsol/Spree-Gtpay) [![Build Status](https://travis-ci.org/vinsol/Spree-GTPay.svg?branch=master)](https://travis-ci.org/vinsol/Spree-GTPay)
==========

Enable spree store to allow payment via [GTBank](http://gtbank.com/) Payment (a foremost Nigerian bank)

####For customer:

Customer can pay via GTBank payment method at Checkout. Customer can also see the list of GTBank Transactions initiated by them.

####For admin:

Admin can see the list of GTBank Transactions initiated by customers under admin section. Admin can also ping GTBank gateway for an updated status of a transaction and the transaction is then updated accordingly. 


Installation
------------

Add spree_gtpay to your Gemfile:

```ruby
gem 'spree_gtpay'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_gtpay:install
```

Configuration
--------

1. To setup the payment method Login as an admin and add a new Payment Method (under Configuration), using following details:

  ```
  Name: GTBank
  Environment: Production (or what ever environment you prefer)
  Provider: Spree::Gateway::Gtpay
  Active: yes
  ```

2. Click update after adding your credentials in the screen that follows:

  ```
  Payment Url: Provide payment url provided by GTBank.
  Merchant: provide merchant id provided bt GTBank
  ```

3. After this you need to create ```initializers/gtbank_constant.rb``` and add below mentioned to the same file.

  ```
  GT_DATA = {:product_id => "xxxx", :mac_id => "xxxxxxxxx", :query_url => "xxxxxx" }
  ```

These are the details which are provided by interswitch(Ask about it from GTBank if you dont have it) and replace xxx with exact values provided.


Testing
-------

You need to do a quick one-time creation of a test application and then you can use it to run the tests.

    bundle exec rake test_app

Then run the rspec tests with:

    bundle exec rspec .



Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License
