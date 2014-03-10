require 'spec_helper'


describe Spree::CheckoutController do
  let(:order) { mock_model(Spree::Order, :remaining_total => 1000, :state => 'payment') }
  let(:user) { mock_model(Spree::User) }
  let(:gtpay_payment_method) { mock_model(Spree::Gateway::Gtpay) }
  let(:gtpay_transaction) { mock_model(Spree::GtpayTransaction, :transaction_id => 11) }
  let(:gtpay_payment) {mock_model(Spree::Payment)}

  before(:each) do  
    user.stub(:generate_spree_api_key!).and_return(true)
    user.stub(:last_incomplete_spree_order).and_return(nil)
    order.stub(:token).and_return(1000)
    controller.stub(:ensure_order_not_completed).and_return(true)
    controller.stub(:ensure_checkout_allowed).and_return(true)
    controller.stub(:ensure_sufficient_stock_lines).and_return(true)
    controller.stub(:ensure_valid_state).and_return(true)
    controller.stub(:associate_user).and_return(true)
    controller.stub(:check_authorization).and_return(true)
    controller.stub(:current_order).and_return(order)  
    controller.stub(:setup_for_current_state).and_return(true)
    controller.stub(:spree_current_user).and_return(user)
    order.stub(:has_checkout_step?).with("payment").and_return(true)
    order.stub(:payment?).and_return(true)
    Spree::Gateway::Gtpay.stub(:first).and_return(gtpay_payment_method)
    controller.stub(:after_update_attributes).and_return(false)
    order.stub(:update_attributes).and_return(true)
    order.stub(:next).and_return(true)
    order.stub(:completed?).and_return(true)
    order.stub(:can_go_to_state?).and_return(false)
    order.stub(:delivery?).and_return(false)
    order.stub(:state=).and_return("payment")
    Spree::PaymentMethod.stub(:where).and_return([gtpay_payment_method])
    Spree::Gateway::Gtpay.stub(:first).and_return(gtpay_payment_method)
    controller.stub(:select_gtpay_payment).and_return({:payment_method_id => gtpay_payment_method.id.to_s})
    controller.stub(:gtpay_payment_method).and_return(gtpay_payment_method)
  end

  describe '#update' do
    def send_request(params = {})
      put :update, params.merge!(:use_route => 'spree', :id => order.id)
    end


    describe 'redirect_to_gtpay' do

      context 'when state payment and payment payments_attributes present' do

        it "should receive where on Spree::PaymentMethod with select_gtpay_payment returning gtpay_payment_method" do
          Spree::PaymentMethod.should_receive(:where).with(:id => gtpay_payment_method.id.to_s).and_return([gtpay_payment_method])
          send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
        end

        context 'when payment_method kind_of Spree::Gateway::Gtpay' do
          it "should_receive update_attributes" do
            order.should_receive(:update_attributes).and_return(true)
            controller.should_receive(:object_params)
            send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
          end

          context 'when update_attributes returns true' do
            it "should redirect to confirm_path" do
              send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
              response.should redirect_to("/gtpay_confirm")
            end
          end

          context 'when update_attributes returns false' do
            before do
              order.stub(:update_attributes).and_return(false)
            end

            it "should redirect_to address page" do
              send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
              response.should redirect_to(spree.checkout_state_path(:state => "address"))
            end

            it "should set flash message" do
              send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
              flash[:error].should eq("Something went wrong. Please try again")
            end
          end

        end

        context 'when payment_method not kind_of PaymentMethod' do
          before do
            gtpay_payment_method.stub(:kind_of?).and_return(false)
          end

          it "should_receive update_attributes" do
            send_request(:order => { :payments_attributes => [{:payment_method_id => 3}]}, :state => "payment")
            response.should_not redirect_to("/gtpay_confirm")
          end        
        end
      end

      context 'when state payment not payment' do
        it "should not receive where on Spree::PaymentMethod" do
          Spree::PaymentMethod.should_not_receive(:where)
          send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "deliver")
        end
      end

      context 'when payments_attributes not present' do
        it "should not receive where on Spree::PaymentMethod" do
          Spree::PaymentMethod.should_not_receive(:where)
          send_request(:order => { :state => "payment" })
        end
      end
    end
  end


  describe 'confirm' do
    before do
      @gtpay_transactions = [gtpay_transaction]
      order.stub(:gtpay_transactions).and_return(@gtpay_transactions)
      gtpay_transaction.stub(:user=).and_return(user)
      @gtpay_transactions.stub(:create).and_yield(gtpay_transaction).and_return(gtpay_transaction)
    end

    def send_request
      get :confirm, :use_route => "spree"
    end

    it "should gtpay_transactions on order" do
      order.should_receive(:gtpay_transactions).and_return(@gtpay_transactions)
      send_request
    end

    it "should create on gtpay_transactions" do
      @gtpay_transactions.should_receive(:create).and_return(gtpay_transaction)
      send_request
    end

    it "should receive user= on gtpay_transaction" do
      gtpay_transaction.should_receive(:user=).and_return(user)
      send_request
    end

    context 'when transaction is created is valid' do
      before do
        gtpay_transaction.stub(:persisted?).and_return(true)
      end

      it "should render without layout" do
        send_request
        response.should_not render_template(:layout)
        response.should render_template(:confirm)
      end

    end

    context 'when transaction is created is invalid' do
      before do
        gtpay_transaction.stub(:persisted?).and_return(false)
      end

      it "should redirect to payment step" do
        send_request
        response.should redirect_to(spree.checkout_state_path(:state => "payment"))
      end

      context 'flash error' do
        context 'when error in amount' do
          before do
            gtpay_transaction.stub("errors").and_return({:gtpay_tranx_amount => "must be greater than 25"})
          end

          it "should set flash error for minimum amount" do
            send_request
            flash[:error].should eq("Minimum amount for order must be above #{Spree::Money.new(Spree::GtpayTransaction::MINIMUM_AMOUNT)}")
          end
        end

        context "when no error in amount" do
          before do
            gtpay_transaction.stub("errors").and_return({})
          end

          it "should set flash error for something went wrong" do
            send_request
            flash[:error].should eq("Something went wrong. Please try again")
          end
        end
      end
    end

  end

end