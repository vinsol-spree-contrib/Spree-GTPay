require 'spec_helper'


describe Spree::Admin::GtpayTransactionsController do
  let(:user) { double(Spree::User, id: 1) }
  let(:role) { double(Spree::Role) }
  let(:roles) { [role] }

  before do
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:authorize_admin).and_return(true)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(user).to receive(:spree_api_key).and_return(true)
    allow(user).to receive(:roles).and_return(roles)
    allow(roles).to receive(:includes).and_return(roles)
    allow(role).to receive(:ability).and_return(true)
    @transaction = double(Spree::GtpayTransaction, id: 1)
    @transactions = [@transaction]
  end

  describe 'index' do
    def send_request(options = {})
      get :index, options.merge(:use_route => 'spree')
    end

    before do
      allow(Spree::GtpayTransaction).to receive(:ransack).and_return(@transactions)
      allow(@transactions).to receive(:order).and_return(@transactions)
      allow(@transactions).to receive(:result).and_return(@transactions)
      allow(@transactions).to receive(:page).and_return(@transactions)
      allow(@transactions).to receive(:per).and_return(@transactions)
    end

    it "should receive ransack" do
      expect(Spree::GtpayTransaction).to receive(:ransack).with({'gtpay_tranx_id' => "12345678"}).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive result on transactions" do
      expect(@transactions).to receive(:result).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive order on transactions" do
      expect(@transactions).to receive(:order).with('created_at desc').and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive page on transactions" do
      expect(@transactions).to receive(:page).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end

    it "should_receive per on transactions" do
      expect(@transactions).to receive(:per).with(20).and_return(@transactions)
      send_request({:q => {:gtpay_tranx_id => "12345678"}})
    end
  end


  describe 'query_interface' do
    def send_request
      xhr :get, :query_interface, :id => @transaction.id, :use_route => 'spree'
    end

    before do
      allow(Spree::GtpayTransaction).to receive(:find).and_return(@transaction)
      allow(@transaction).to receive(:update_transaction_on_query).and_return(true)
    end

    it "should_receive update_transaction_on_query on transaction" do
      expect(@transaction).to receive(:update_transaction_on_query).and_return(true)
      send_request
    end

    it "should render query interface" do
      send_request
      expect(response).to render_template(:query_interface)
    end
  end
end
