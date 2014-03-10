require 'spec_helper'

describe Spree::Gateway::Gtpay do
  let(:pending_payment) { mock_model(Spree::Payment, :state => 'pending') }
  let(:complete_payment) { mock_model(Spree::Payment, :state => 'complete') }
  let(:void_payment) { mock_model(Spree::Payment, :state => 'void') }
  before { @gtpay_payment = Spree::Gateway::Gtpay.new }
  it { @gtpay_payment.actions.should eq(["capture", "void"]) }
  it { @gtpay_payment.can_capture?(pending_payment).should be_true }
  it { @gtpay_payment.can_capture?(complete_payment).should be_false }
  it { @gtpay_payment.can_void?(pending_payment).should be_true }
  it { @gtpay_payment.can_void?(void_payment).should be_false }
  it { @gtpay_payment.source_required?.should be_false }

  it 'voids a payment' do
    ActiveMerchant::Billing::Response.should_receive(:new).with(true, "", {}, {}).and_return(true)
    @gtpay_payment.void
  end

  it 'captures a payment' do
    ActiveMerchant::Billing::Response.should_receive(:new).with(true, "", {}, {}).and_return(true)
    @gtpay_payment.capture
  end
end