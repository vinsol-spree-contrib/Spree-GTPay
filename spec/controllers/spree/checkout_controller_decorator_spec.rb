require 'spec_helper'


describe Spree::CheckoutController do
  let(:order) { double(Spree::Order, :remaining_total => 1000, :state => 'payment', id: 1) }
  let(:user) { double(Spree::User) }
  let(:gtpay_payment_method) { double(Spree::Gateway::Gtpay, id: 1) }
  let(:gtpay_transaction) { double(Spree::GtpayTransaction, :transaction_id => 11) }
  let(:gtpay_payment) {double(Spree::Payment)}

  before(:each) do
    allow(user).to receive(:generate_spree_api_key!).and_return(true)
    allow(user).to receive(:last_incomplete_spree_order).and_return(nil)
    allow(order).to receive(:token).and_return(1000)
    allow(controller).to receive(:ensure_order_not_completed).and_return(true)
    allow(controller).to receive(:ensure_checkout_allowed).and_return(true)
    allow(controller).to receive(:ensure_sufficient_stock_lines).and_return(true)
    allow(controller).to receive(:ensure_valid_state).and_return(true)
    allow(controller).to receive(:associate_user).and_return(true)
    allow(controller).to receive(:check_authorization).and_return(true)
    allow(controller).to receive(:current_order).and_return(order)
    allow(controller).to receive(:setup_for_current_state).and_return(true)
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(order).to receive(:has_checkout_step?).with("payment").and_return(true)
    allow(order).to receive(:payment?).and_return(true)
    allow(Spree::Gateway::Gtpay).to receive(:first).and_return(gtpay_payment_method)
    allow(controller).to receive(:after_update_attributes).and_return(false)
    allow(order).to receive(:update_from_params).and_return(true)
    allow(order).to receive(:next).and_return(true)
    allow(order).to receive(:completed?).and_return(true)
    allow(order).to receive(:can_go_to_state?).and_return(false)
    allow(order).to receive(:delivery?).and_return(false)
    allow(order).to receive(:state=).and_return("payment")
    allow(Spree::PaymentMethod).to receive(:where).and_return([gtpay_payment_method])
    allow(gtpay_payment_method).to receive(:kind_of?).and_return true
    allow(Spree::Gateway::Gtpay).to receive(:first).and_return(gtpay_payment_method)
    allow(controller).to receive(:gtpay_payment_method).and_return(gtpay_payment_method)
    allow(user).to receive(:orders).and_return(Spree::Order.none)
    allow(order).to receive(:temporary_address=)
  end

  describe '#update' do
    def send_request(params = {})
      put :update, params.merge!(:use_route => 'spree', :id => order.id)
    end


    describe 'redirect_to_gtpay' do

      context 'when state payment and payment payments_attributes present' do

        it "should receive where on Spree::PaymentMethod with select_gtpay_payment returning gtpay_payment_method" do
          expect(Spree::PaymentMethod).to receive(:where).with(:id => gtpay_payment_method.id.to_s).and_return([gtpay_payment_method])
          send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
        end

        context 'when payment_method kind_of Spree::Gateway::Gtpay' do

          context 'when update_from_params returns true' do
            it "should redirect to confirm_path" do
              expect(order).to receive(:update_from_params).and_return(true)
              expect(controller).to receive(:permitted_checkout_attributes)
              send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
              expect(response).to redirect_to("/gtpay_confirm")
            end
          end

          context 'when update_attributes returns false' do
            before do
              allow(order).to receive(:update_from_params).and_return(false)
            end

            it "should redirect_to address page" do
              send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
              expect(response).to redirect_to(spree.checkout_state_path(order.state))
            end

            it "should set flash message" do
              send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "payment")
              expect(flash[:error]).to eq("Something went wrong. Please try again")
            end
          end

        end

        context 'when payment_method not kind_of PaymentMethod' do
          before do
            allow(gtpay_payment_method).to receive(:kind_of?).and_return(false)
          end

          it "should_receive update_attributes" do
            send_request(:order => { :payments_attributes => [{:payment_method_id => 3}]}, :state => "payment")
            expect(response).not_to redirect_to("/gtpay_confirm")
          end
        end
      end

      context 'when state payment not payment' do
        it "should not receive where on Spree::PaymentMethod" do
          expect(Spree::PaymentMethod).not_to receive(:where)
          send_request(:order => { :payments_attributes => [{:payment_method_id => gtpay_payment_method.id}]}, :state => "deliver")
        end
      end

      context 'when payments_attributes not present' do
        it "should not receive where on Spree::PaymentMethod" do
          expect(Spree::PaymentMethod).not_to receive(:where)
          send_request(:order => { :state => "payment" })
        end
      end
    end
  end


  describe 'confirm' do
    before do
      @gtpay_transactions = [gtpay_transaction]
      allow(order).to receive(:gtpay_transactions).and_return(@gtpay_transactions)
      allow(gtpay_transaction).to receive(:user=).and_return(user)
      allow(@gtpay_transactions).to receive(:create).and_yield(gtpay_transaction).and_return(gtpay_transaction)
      allow(gtpay_transaction).to receive(:persisted?).and_return(true)
    end

    def send_request
      get :confirm, :use_route => "spree"
    end

    it "should gtpay_transactions on order" do
      expect(order).to receive(:gtpay_transactions).and_return(@gtpay_transactions)
      send_request
    end

    it "should create on gtpay_transactions" do
      expect(@gtpay_transactions).to receive(:create).and_return(gtpay_transaction)
      send_request
    end

    it "should receive user= on gtpay_transaction" do
      expect(gtpay_transaction).to receive(:user=).and_return(user)
      send_request
    end

    context 'when transaction is created is valid' do
      before do
        allow(gtpay_transaction).to receive(:persisted?).and_return(true)
      end

      it "should render without layout" do
        send_request
        expect(response).not_to render_template(:layout)
        expect(response).to render_template(:confirm)
      end

    end

    context 'when transaction is created is invalid' do
      before do
        allow(gtpay_transaction).to receive(:persisted?).and_return(false)
        allow(gtpay_transaction).to receive(:errors).and_return({})
      end

      it "should redirect to payment step" do
        send_request
        expect(response).to redirect_to(spree.checkout_state_path(:state => "payment"))
      end

      context 'flash error' do
        context 'when error in amount' do
          before do
            allow(gtpay_transaction).to receive("errors").and_return({:gtpay_tranx_amount => "must be greater than 25"})
          end

          it "should set flash error for minimum amount" do
            send_request
            expect(flash[:error]).to eq("Minimum amount for order must be above #{Spree::Money.new(Spree::GtpayTransaction::MINIMUM_AMOUNT)}")
          end
        end

        context "when no error in amount" do
          before do
            allow(gtpay_transaction).to receive("errors").and_return({})
          end

          it "should set flash error for something went wrong" do
            send_request
            expect(flash[:error]).to eq("Something went wrong. Please try again")
          end
        end
      end
    end

  end

end
