require 'spec_helper'


describe Spree::Admin::GtpayTransactionsController do
  let(:user) { mock_model(Spree::User) }
  let(:role) { mock_model(Spree::Role) }
  let(:roles) { [role] }

  before do
    controller.stub(:spree_current_user).and_return(user)
    controller.stub(:authorize_admin).and_return(true)
    controller.stub(:authorize!).and_return(true)
    user.stub(:generate_spree_api_key!).and_return(true)
    user.stub(:roles).and_return(roles)
    roles.stub(:includes).and_return(roles)
    role.stub(:ability).and_return(true)
    @transaction = mock_model(Spree::GtpayTransaction)
    @transactions = [@transaction]
  end


  describe 'index' do
    def send_request(options = {})
      get :index, options.merge(:use_route => 'spree')
    end

    before do
      Spree::GtpayTransaction.stub(:ransack).and_return(@transactions)
      @transactions.stub(:order).and_return(@transactions)
      @transactions.stub(:result).and_return(@transactions)
      @transactions.stub(:page).and_return(@transactions)
      @transactions.stub(:per).and_return(@transactions)
    end

    it "should receive ransack" do
      Spree::GtpayTransaction.should_receive(:ransack).with({'gtpay_tranx_id' => "12345678"}).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive result on transactions" do
      @transactions.should_receive(:result).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive order on transactions" do
      @transactions.should_receive(:order).with('created_at desc').and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive page on transactions" do
      @transactions.should_receive(:page).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive per on transactions" do
      @transactions.should_receive(:per).with(20).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end
  end


  describe 'query_interface' do
    def send_request
      xhr :get, :query_interface, :id => @transaction.id, :use_route => 'spree'
    end

    before do
      Spree::GtpayTransaction.stub(:find).and_return(@transaction)
      @transaction.stub(:update_transaction_on_query).and_return(true)
    end

    it "should_receive update_transaction_on_query on transaction" do
      @transaction.should_receive(:update_transaction_on_query).and_return(true)
      send_request
    end

    it "should render query interface" do
      send_request
      response.should render_template(:query_interface)
    end
  end
end