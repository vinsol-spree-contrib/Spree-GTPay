require 'spec_helper'

describe Spree::Gateway::Gtpay do
  let(:pending_payment) { double(Spree::Payment, :state => 'pending') }
  let(:complete_payment) { double(Spree::Payment, :state => 'complete') }
  let(:void_payment) { double(Spree::Payment, :state => 'void') }
  before { @gtpay_payment = Spree::Gateway::Gtpay.new }
  it { expect(@gtpay_payment.actions).to eq(["capture", "void"]) }
  it { expect(@gtpay_payment.can_capture?(pending_payment)).to be_truthy }
  it { expect(@gtpay_payment.can_capture?(complete_payment)).to be_falsey }
  it { expect(@gtpay_payment.can_void?(pending_payment)).to be_truthy }
  it { expect(@gtpay_payment.can_void?(void_payment)).to be_falsey }
  it { expect(@gtpay_payment.source_required?).to be_falsey }

  it 'voids a payment' do
    expect(ActiveMerchant::Billing::Response).to receive(:new).with(true, "", {}, {}).and_return(true)
    @gtpay_payment.void
  end

  it 'captures a payment' do
    expect(ActiveMerchant::Billing::Response).to receive(:new).with(true, "", {}, {}).and_return(true)
    @gtpay_payment.capture
  end
end
