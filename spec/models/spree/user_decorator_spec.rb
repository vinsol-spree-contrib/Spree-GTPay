require 'spec_helper'

describe Spree::User do
  it {should have_many(:gtpay_transactions)}
end 