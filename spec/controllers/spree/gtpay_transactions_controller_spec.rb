require 'spec_helper'

describe Spree::GtpayTransactionsController do
  before do
    @transaction = mock_model(Spree::GtpayTransaction)
    @transactions = [@transaction]
  end

  describe 'callback' do
    before do
      @transactions.stub(:pending).and_return(@transactions)
      @transactions.stub(:where).and_return(@transactions)
      @transaction.stub(:update_transaction).and_return(true)
      @transaction.stub(:successful?).and_return(true)
      @order = mock_model(Spree::Order)
      controller.stub(:current_order).and_return(@order)
      @order.stub(:gtpay_transactions).and_return(@transactions)
      @order.stub(:complete_and_finalize).and_return(true)
      @user = mock_model(Spree::User)
      controller.stub(:spree_current_user).and_return(@user)
      @user.stub(:generate_spree_api_key!).and_return(true)
      controller.stub(:set_current_order).and_return(@order)
    end

    def send_request
      post :callback, { :gtpay_tranx_amt => "100.0", :gtpay_tranx_status_code => "00", :gtpay_tranx_status_msg => "Approved", :use_route => 'spree' }
    end

    context 'load_gtpay_transaction' do

      it "should_receive pending" do
        @transactions.should_receive(:pending).and_return(@transactions)
        send_request
      end

      it "should receive gtpay_transactions on order" do
        @order.should_receive(:gtpay_transactions).and_return(@transactions)
        send_request
      end

      it "should receive where" do
        @transactions.should_receive(:where).and_return(@transactions)
        send_request
      end

      context 'when transaction not present' do
        before do
          @transactions.stub(:where).and_return([])
          @order.stub(:state).and_return("payment")
        end

        it "should redirect to order state checkout" do
          send_request
          response.should redirect_to(spree.checkout_state_path("payment"))
        end

        it "should set flash error" do
          send_request
          flash[:error].should eq("Your Order cannot be processed. Please contact customer support <br/> Reason: Approved <br/> Transaction Reference: ".html_safe)
        end
      end
    end

    it "should_receive update_transaction" do
      @transaction.should_receive(:update_transaction).with({ :gtpay_tranx_amount => "100.0", :gtpay_tranx_status_code => "00", :gtpay_tranx_status_msg => "Approved" }).and_return(true)
      send_request
    end

    context 'when successful? is true' do
      context 'reset_redirect_to_order_detail' do

        it "should set session order_id to nil" do
          send_request
          session[:order_id].should be_nil
        end

        it "should set flash notice" do
          send_request
          flash[:notice].should eq("Your Order has been processed successfully. <br/> Transaction Reference:  <br/> Transaction Code: 00 <br/> Transaction Message: Approved")
        end

        it "should redirect to completion path" do
          send_request
          response.should redirect_to(spree.order_path(@order))
        end
      end
    end

    context 'when successful? is false' do
      before do
        @transaction.stub(:gtpay_tranx_status_msg).and_return("Invalid transaction")
        @order.stub(:state).and_return("payment")
        @transaction.stub(:successful?).and_return(false)
        @transaction.stub(:gtpay_tranx_id).and_return("1234")
      end

      it "should set flash error" do
        send_request
        flash[:error].should eq("Your Transaction was not successful. <br/> Reason: Invalid transaction. <br/> Transaction reference: 1234. <br/> Please Try again")
      end

      it "should redirect_to payment state" do
        send_request
        response.should redirect_to(spree.checkout_state_path(@order.state))
      end
    end

  end

  describe 'index' do

    def send_request(options = {})
      get :index, options.merge(:use_route => 'spree')
    end

    before do
      @user = mock_model(Spree::User, :addresses => @current_user_addresses, :generate_spree_api_key! => false, :last_incomplete_spree_order => nil)
      controller.stub(:spree_current_user).and_return(@user)
      @user.stub(:gtpay_transactions).and_return(@transactions)
      @transactions.stub(:includes).and_return(@transactions)
      @transactions.stub(:order).and_return(@transactions)
      @transactions.stub(:page).and_return(@transactions)
      @transactions.stub(:per).and_return(@transactions)
      controller.stub(:authenticate_spree_user!).and_return(true)
    end

    it "controller should receive authenticate_spree_user" do
      controller.should_receive(:authenticate_spree_user!).and_return(true)
      send_request
    end

    it "user should_receive gtpay_transactions" do
      @user.should_receive(:gtpay_transactions).and_return(@transactions)
      send_request
    end

    it "transactions should_receive includes" do
      @transactions.should_receive(:includes).with(:order).and_return(@transactions)
      send_request
    end

    it "transactions should_receive order" do
      @transactions.should_receive(:order).with('updated_at desc').and_return(@transactions)
      send_request
    end

    it "transactions should_receive page" do
      @transactions.should_receive(:page).with("2").and_return(@transactions)
      send_request(:page => "2")
    end

    it "transactions should_receive per" do
      @transactions.should_receive(:per).with(20).and_return(@transactions)
      send_request
    end
  end
end