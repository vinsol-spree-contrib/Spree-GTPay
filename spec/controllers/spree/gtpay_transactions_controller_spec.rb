require 'spec_helper'

describe Spree::GtpayTransactionsController do
  before do
    @transaction = double(Spree::GtpayTransaction)
    @transactions = [@transaction]
  end

  describe 'callback' do
    before do
      allow(@transactions).to receive(:pending).and_return(@transactions)
      allow(@transactions).to receive(:where).and_return(@transactions)
      allow(@transaction).to receive(:update_transaction).and_return(true)
      allow(@transaction).to receive(:successful?).and_return(true)
      @order = double(Spree::Order)
      allow(controller).to receive(:current_order).and_return(@order)
      allow(@order).to receive(:gtpay_transactions).and_return(@transactions)
      allow(@order).to receive(:complete_and_finalize).and_return(true)
      @user = double(Spree::User)
      allow(controller).to receive(:spree_current_user).and_return(@user)
      allow(@user).to receive(:generate_spree_api_key!).and_return(true)
      allow(controller).to receive(:set_current_order).and_return(@order)
    end

    def send_request
      post :callback, { :gtpay_tranx_amt => "100.0", :gtpay_tranx_status_code => "00", :gtpay_tranx_status_msg => "Approved", :use_route => 'spree' }
    end

    context 'load_gtpay_transaction' do

      it "should_receive pending" do
        expect(@transactions).to receive(:pending).and_return(@transactions)
        send_request
      end

      it "should receive gtpay_transactions on order" do
        expect(@order).to receive(:gtpay_transactions).and_return(@transactions)
        send_request
      end

      it "should receive where" do
        expect(@transactions).to receive(:where).and_return(@transactions)
        send_request
      end

      context 'when transaction not present' do
        before do
          allow(@transactions).to receive(:where).and_return([])
          allow(@order).to receive(:state).and_return("payment")
        end

        it "should redirect to order state checkout" do
          send_request
          expect(response).to redirect_to(spree.checkout_state_path("payment"))
        end

        it "should set flash error" do
          send_request
          expect(flash[:error]).to eq("Your Order cannot be processed. Please contact customer support <br/> Reason: Approved <br/> Transaction Reference: ".html_safe)
        end
      end
    end

    it "should_receive update_transaction" do
      expect(@transaction).to receive(:update_transaction).with({ :gtpay_tranx_amount => "100.0", :gtpay_tranx_status_code => "00", :gtpay_tranx_status_msg => "Approved" }).and_return(true)
      send_request
    end

    context 'when successful? is true' do
      context 'reset_redirect_to_order_detail' do

        it "should set session order_id to nil" do
          send_request
          expect(session[:order_id]).to be_nil
        end

        it "should set flash notice" do
          send_request
          expect(flash[:notice]).to eq("Your Order has been processed successfully. <br/> Transaction Reference:  <br/> Transaction Code: 00 <br/> Transaction Message: Approved")
        end

        it "should redirect to completion path" do
          send_request
          expect(response).to redirect_to(spree.order_path(@order))
        end
      end
    end

    context 'when successful? is false' do
      before do
        allow(@transaction).to receive(:gtpay_tranx_status_msg).and_return("Invalid transaction")
        allow(@order).to receive(:state).and_return("payment")
        allow(@transaction).to receive(:successful?).and_return(false)
        allow(@transaction).to receive(:gtpay_tranx_id).and_return("1234")
      end

      it "should set flash error" do
        send_request
        expect(flash[:error]).to eq("Your Transaction was not successful. <br/> Reason: Invalid transaction. <br/> Transaction reference: 1234. <br/> Please Try again")
      end

      it "should redirect_to payment state" do
        send_request
        expect(response).to redirect_to(spree.checkout_state_path(@order.state))
      end
    end

  end

  describe 'index' do

    def send_request(options = {})
      get :index, options.merge(:use_route => 'spree')
    end

    before do
      @user = double(Spree::User, :addresses => @current_user_addresses, :generate_spree_api_key! => false, :last_incomplete_spree_order => nil)
      allow(controller).to receive(:spree_current_user).and_return(@user)
      allow(@user).to receive(:gtpay_transactions).and_return(@transactions)
      allow(@transactions).to receive(:includes).and_return(@transactions)
      allow(@transactions).to receive(:order).and_return(@transactions)
      allow(@transactions).to receive(:page).and_return(@transactions)
      allow(@transactions).to receive(:per).and_return(@transactions)
      allow(controller).to receive(:authenticate_spree_user!).and_return(true)
    end

    it "controller should receive authenticate_spree_user" do
      expect(controller).to receive(:authenticate_spree_user!).and_return(true)
      send_request
    end

    it "user should_receive gtpay_transactions" do
      expect(@user).to receive(:gtpay_transactions).and_return(@transactions)
      send_request
    end

    it "transactions should_receive includes" do
      expect(@transactions).to receive(:includes).with(:order).and_return(@transactions)
      send_request
    end

    it "transactions should_receive order" do
      expect(@transactions).to receive(:order).with('updated_at desc').and_return(@transactions)
      send_request
    end

    it "transactions should_receive page" do
      expect(@transactions).to receive(:page).with("2").and_return(@transactions)
      send_request(:page => "2")
    end

    it "transactions should_receive per" do
      expect(@transactions).to receive(:per).with(20).and_return(@transactions)
      send_request
    end
  end
end
