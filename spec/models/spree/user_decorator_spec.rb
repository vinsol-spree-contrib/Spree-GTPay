require 'spec_helper'

describe Spree::User do
  it {is_expected.to have_many(:gtpay_transactions)}
end 