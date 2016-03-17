require 'spec_helper'

describe Spree::Payment do
  let(:user) { Spree::User.create!(:email => 'test_user@xyz.com', :password => 'test_password') }
  let(:order) { Spree::Order.create! { |order| order.user = user }}

  before(:each) do
    allow_any_instance_of(Spree::Stock::Quantifier).to receive_messages(can_supply?: true)
    order.update_column(:total, 1000)
    order.update_column(:payment_total, 200)
    @shipping_category = Spree::ShippingCategory.create!(:name => 'test')
    @stock_location = Spree::StockLocation.create! :name => 'test'
    @product = Spree::Product.create!(:name => 'test_product', :price => 10, :shipping_category_id => @shipping_category.id)
    @stock_item = @product.master.stock_items.first
    @stock_item.adjust_count_on_hand(10)
    @stock_item.save!

    order.line_items.create! :variant_id => @product.master.id, :quantity => 1
    @gtpay_payment_method = Spree::Gateway::Gtpay.create(:name => "GTpay bank", :preferences => { test_mode: true })
    @gtpay_payment = order.payments.create!(:amount => 100, :payment_method_id => @gtpay_payment_method.id) { |p| p.state = 'checkout' }
  end

  describe 'process_and_complete!' do
    before do
      allow(@gtpay_payment).to receive(:started_processing!).and_return(true)
      allow(@gtpay_payment).to receive(:complete!).and_return(true)
    end

    it "should receive started_processing!" do
      expect(@gtpay_payment).to receive(:started_processing!).and_return(true)
      @gtpay_payment.process_and_complete!
    end

    it "should receive complete!" do
      expect(@gtpay_payment).to receive(:complete!).and_return(true)
      @gtpay_payment.process_and_complete!
    end
  end
end
