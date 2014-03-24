SpreeGtpay  [![Build Status](https://travis-ci.org/vinsol/Spree-Gtpay.svg)](https://travis-ci.org/vinsol/Spree-Gtpay)
==========


Installation
------------

Add spree_gtpay to your Gemfile:

```ruby
gem 'spree_gtpay', :git => 'git://github.com/vinsol/Spree-Gtpay.git'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_gtpay:install
```

Configuration
--------

This is an extension for GTBank payment method used for Card payment using GTBank Gateway(Interswitch).

To set this up:

Setup the Payment Method Log in as an admin and add a new Payment Method (under Configuration), using following details:

Name: GTBank

Environment: Production (or what ever environment you prefer)

Provider: Spree::Gateway::Gtpay

Active: yes

Click **Create* , and now add your credentials in the screen that follows:

Payment Url: Provide payment url provided by GTbank.

Merchant: provide merchant id provided bt GTbank


Click Update


After this You will need to create Constant in initializer folder.

eg. initializers/gtbank_constant.rb

create hash like

GT_DATA = {:product_id => "xxxx", :mac_id => "xxxxxxxxx", :query_url => "xxxxxx" }

These are the details which are provided by interswitch(Ask about it from GTbank if you dont have it) and replace xxx with exact values provided.


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
