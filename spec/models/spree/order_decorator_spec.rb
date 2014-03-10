require 'spec_helper'

describe Spree::Order do
  let(:user) { Spree::User.create!(:email => 'test_user@xyz.com', :password => 'test_password') }
  let(:order) { Spree::Order.create! { |order| order.user = user }}

  before(:each) do
    Spree::Stock::Quantifier.any_instance.stub(can_supply?: true)
    order.update_column(:total, 1000)
    order.update_column(:payment_total, 200)
    @shipping_category = Spree::ShippingCategory.create!(:name => 'test')
    @stock_location = Spree::StockLocation.create! :name => 'test' 
    @product = Spree::Product.create!(:name => 'test_product', :price => 10, :shipping_category_id => @shipping_category.id)
    @stock_item = @product.master.stock_items.first
    @stock_item.adjust_count_on_hand(10)
    @stock_item.save!

    order.line_items.create! :variant_id => @product.master.id, :quantity => 1
  end

  def create_order_with_state(state)
    Spree::Order.create! do |order|
      order.user = user
      order.state = state
      total = 100
    end
  end

  describe 'gtpay_payment' do
    context 'when gtpay_payment present' do
      before(:each) do
        @gtpay_payment_method = Spree::Gateway::Gtpay.create(:name => "GTpay bank", :environment => Rails.env)
      end

      context 'when payment state is checkout' do
        before do
          @gtpay_payment = order.payments.create!(:amount => 100, :payment_method_id => @gtpay_payment_method.id) { |p| p.state = 'checkout' }
        end

        it "should return gtpay_payment" do
          order.gtpay_payment.should eq(@gtpay_payment)
        end

      end

      context 'when payment state is pending' do
        before do
          @gtpay_payment = order.payments.create!(:amount => 100, :payment_method_id => @gtpay_payment_method.id) { |p| p.state = 'checkout' }
        end

        it "should return gtpay_payment" do
          order.gtpay_payment.should eq(@gtpay_payment)
        end
      end
    end

    context 'when gtpay_payment not present' do
      it "should return nil" do
        order.gtpay_payment.should be_nil
      end
    end
  end

  describe 'complete_and_finalize' do
    before do
      @gtpay_payment_method = Spree::Gateway::Gtpay.create(:name => "gtpay epay", :environment => Rails.env)
      @order = create_order_with_state("payment")
      @payment = @order.payments.create!(:amount => 100, :payment_method_id => @gtpay_payment_method.id) { |p| p.state = 'checkout' }
    end

    it "should receive complete!" do
      @order.complete_and_finalize
      @order.state.should eq("complete")
    end

    it "set completed_at for order" do
      @order.complete_and_finalize
      @order.completed_at.should be_within(2.seconds).of(Time.current)
    end

    it "should set payment to complete" do
      @order.complete_and_finalize
      @payment.reload.state.should eq("completed")
    end

    it "should receive finalize!" do
      @order.should_receive(:finalize!)
      @order.complete_and_finalize
    end

  end

  describe 'set_failure_for_payment' do
    before do
      @gtpay_payment_method = Spree::Gateway::Gtpay.create(:name => "gtpay epay", :environment => Rails.env)
      @order = create_order_with_state("payment")
      @payment = @order.payments.create!(:amount => 100, :payment_method_id => @gtpay_payment_method.id) { |p| p.state = 'processing' }
    end

    it "payment state should be failed" do
      @order.set_failure_for_payment
      @payment.reload.state.should eq("failed")
    end
  end

end