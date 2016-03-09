require 'spec_helper'

describe Spree::GtpayTransaction do
  GT_DATA = {:product_id => "xxxx", :mac_id => "xxxxxxxxx", :query_url => "xxxxxx" }
  let(:shipping_category) { Spree::ShippingCategory.create!(:name => "Default Shipping") }
  before do
    allow_any_instance_of(Spree::Stock::Quantifier).to receive_messages(can_supply?: true)
    @user = Spree::User.create!(:email => 'test_user@xyz.com', :password => 'test_password')
    @order = Spree::Order.create!
    @product = Spree::Product.create!(:name => 'test_product', :price => 30, :shipping_category_id => shipping_category.id)
    @variant = @product.variants.create!(:sku => 'M12345')
    @line_item = @order.line_items.new(:quantity => 1)
    @line_item.variant = @variant
    @line_item.save!
    @transaction = @order.gtpay_transactions.create! { |t| t.user = @user }
  end

  describe 'constants' do

    it "should return hash of currency code" do
      expect(Spree::GtpayTransaction::CURRENCY_CODE).to eq({ "NGN" => "566", "USD" => "844" })
    end

    it "should PENDING value" do
      expect(Spree::GtpayTransaction::PENDING).to eq("Pending")
    end

    it "should MINIMUM_AMOUNT value" do
      expect(Spree::GtpayTransaction::SUCCESSFUL).to eq("Successful")
    end

    it "should MINIMUM_AMOUNT value" do
      expect(Spree::GtpayTransaction::UNSUCCESSFUL).to eq("Unsuccessful")
    end
  end

  describe 'scope pending' do
    before do
      @transaction1 = @order.gtpay_transactions.create! { |t| t.user = @user }
      @transaction1.status = "successful"
      @transaction1.save
      allow(@transaction).to receive(:order_complete_and_finalize).and_return(true)
      allow(@transaction).to receive(:send_transaction_mail).and_return(true)
    end

    it "should contain pending transactions" do
      expect(Spree::GtpayTransaction.pending).to match_array([@transaction])
    end
  end

  describe 'scope successful' do
    before do
      @transaction1 = @order.gtpay_transactions.create! { |t| t.user = @user }
      allow(@transaction1).to receive(:order_complete_and_finalize).and_return(true)
      allow(@transaction1).to receive(:send_transaction_mail).and_return(true)
      @transaction1.status = "Successful"
      @transaction1.save!
    end

    it "should contain successful transactions" do
      expect(Spree::GtpayTransaction.successful).to match_array([@transaction1])
    end
  end

  describe 'validations' do
    it { expect(@transaction).to validate_presence_of(:user) }
    it { expect(@transaction).to validate_presence_of(:gtpay_tranx_id) }
    it { expect(@transaction).to validate_presence_of(:gtpay_tranx_amount) }
    it { expect(@transaction).to validate_presence_of(:gtpay_tranx_currency) }

    context 'numericality' do
      before do
        @transaction.gtpay_tranx_amount = "ew"
      end

      it "should not save" do
        expect(@transaction.save).to be_falsey
      end

    end
  end

  describe 'associations' do
    it {is_expected.to belong_to(:user)}
    it {is_expected.to belong_to(:order)}
  end

  describe 'amount_valid?' do
    context 'when order total is = than gtpay_tranx_amount' do
      it "return true" do
        expect(@transaction.amount_valid?).to be_truthy
      end
    end

    context 'when order total is more than gtpay_tranx_amount' do
      before do
        allow(@transaction).to receive(:order_total).and_return(10000)
      end

      it "return false" do
        expect(@transaction.amount_valid?).to be_falsey
      end
    end
  end

  describe 'generate_tranx_id' do
    context 'on create' do
      before do
        @transaction1 = @order.gtpay_transactions.create! {|t| t.user = @user }
      end

      it "should generate_tranx_id" do
        expect(@transaction1.gtpay_tranx_id).to be_present
        expect(@transaction1.gtpay_tranx_id.size).to be(18)
      end
    end

    context 'on update' do
      before do
        @tranx_id = @transaction.gtpay_tranx_id
        @transaction.update_attributes(:gtpay_tranx_amount => 100)
      end

      it "transaction tranx_id should remain same" do
        expect(@transaction.gtpay_tranx_id).to eq(@tranx_id)
      end
    end
  end

  describe 'set_status' do
    context 'when gtpay_tranx_status_code changed' do

      context 'when successful_status_code and amount valid' do
        before do
          allow(@transaction).to receive(:order_complete_and_finalize).and_return(true)
          allow(@transaction).to receive(:send_transaction_mail).and_return(true)
          @transaction.gtpay_tranx_status_code = "00"
          @transaction.save
        end

        it "should set status to successful" do
          expect(@transaction.status).to eq("Successful")
        end
      end


      context 'when successful_status_code is false' do
        before do
          allow(@transaction).to receive(:order_set_failure_for_payment).and_return(true)
          @transaction.gtpay_tranx_status_code = "Z0"
          @transaction.save
        end

        it "should set status to unsuccessful" do
          expect(@transaction.status).to eq("Unsuccessful")
        end
      end

      context 'when amount_valid is false' do
        before do
          gtpay_gateway = Spree::Gateway::Gtpay.new
          gtpay_gateway.name = 'test'
          gtpay_gateway.save!
          FactoryGirl.create(:payment, payment_method_id: gtpay_gateway.id, order_id: @order.id)
          allow(@transaction).to receive(:order_set_failure_for_payment).and_return(true)
          allow(@transaction).to receive(:order_total).and_return(10000)
          @transaction.gtpay_tranx_amount = 25.0
          @transaction.gtpay_tranx_status_code = "00"
          @transaction.save
        end

        it "should set status to unsuccessful" do
          expect(@transaction.status).to eq("Unsuccessful")
        end
      end
    end

    context 'when gtpay_tranx_status_code not changed' do
      before do
        @transaction.gtpay_tranx_amount = 25.0
      end

      it "should not receive set_status" do
        expect(@transaction).not_to receive(:set_status)
        @transaction.save
      end
    end
  end

  describe 'order_complete_and_finalize' do
    context 'when status changed to successful' do
      before do
        @transaction.status = "Successful"
        allow(@transaction).to receive(:send_transaction_mail).and_return(true)
      end

      it "should receive order_complete_and_finalize" do
        expect(@transaction).to receive(:order_complete_and_finalize).and_return(true)
        @transaction.save
      end
    end

    context 'when status changed to pending' do
      before do
        @transaction.status = "Pending"
      end

      it "should not receive order_complete_and_finalize" do
        expect(@transaction).not_to receive(:order_complete_and_finalize)
        @transaction.save
      end
    end

    context 'when status not changed' do
      before do
        @transaction.gtpay_tranx_amount = 32.0
      end

      it "should not receive order_complete_and_finalize" do
        expect(@transaction).not_to receive(:order_complete_and_finalize)
        @transaction.save
      end
    end
  end

  describe 'send_transaction_mail' do
    context 'when status changed to successful' do
      before do
        allow(@transaction).to receive(:order_complete_and_finalize).and_return(true)
        @transaction.status = "Successful"
        @job = double(Delayed::Job)
        allow(Spree::TransactionNotificationMailer).to receive(:delay).and_return(@job)
        allow(@job).to receive(:send_mail).and_return(true)
      end

      it "should receive delay on TransactionNotificationMailer" do
        expect(Spree::TransactionNotificationMailer).to receive(:delay).and_return(@job)
        @transaction.save
      end

      it "should_receive send_mail on delayed job" do
        expect(@job).to receive(:send_mail).with(@transaction).and_return(true)
        @transaction.save
      end
    end

    context 'when status changed to pending' do
      before do
        @transaction.status = "Pending"
      end

      it "should not receive send_transaction_mail" do
        expect(@transaction).not_to receive(:send_transaction_mail)
        @transaction.save
      end
    end

    context 'when status not changed' do
      before do
        @transaction.gtpay_tranx_amount = 32.0
      end

      it "should not receive send_transaction_mail" do
        expect(@transaction).not_to receive(:send_transaction_mail)
        @transaction.save
      end
    end
  end


  describe 'order_set_failure_for_payment' do
    context 'when status changed to unsuccessful' do
      before do
        @transaction.status = "Unsuccessful"
      end

      it "should receive order_set_failure_for_payment" do
        expect(@transaction).to receive(:order_set_failure_for_payment).and_return(true)
        @transaction.save
      end
    end

    context 'when status changed to pending' do
      before do
        @transaction.status = "Pending"
      end

      it "should not receive order_set_failure_for_payment" do
        expect(@transaction).not_to receive(:order_set_failure_for_payment)
        @transaction.save
      end
    end

    context 'when status not changed' do
      before do
        @transaction.gtpay_tranx_amount = 32.0
      end

      it "should not receive order_set_failure_for_payment" do
        expect(@transaction).not_to receive(:order_set_failure_for_payment)
        @transaction.save
      end
    end
  end



  describe 'set_default_attirbutes' do
    context 'on create' do
      before do
        @transaction1 = @order.gtpay_transactions.create! { |t| t.user = @user }
      end

      it "should set currency" do
        expect(@transaction.gtpay_tranx_currency).to eq(Spree::GtpayTransaction::CURRENCY_CODE[@order.currency])
      end

      it "should set amount" do
        expect(@transaction.gtpay_tranx_amount).to eq(@order.reload.total)
      end

      it "should set status" do
        expect(@transaction.status).to eq("Pending")
      end
    end

    context 'on update' do
      before do
        @status = @transaction.status
        @transaction.update(:gtpay_tranx_amount => 100)
      end

      it "transaction status should remain same" do
        expect(@transaction.status).to eq(@status)
      end
    end
  end

  describe 'successful_status_code?' do
    context 'when status code is 00' do
      before do
        @transaction.update_column('gtpay_tranx_status_code', "00")
      end

      it "should return true" do
        expect(@transaction.successful_status_code?).to be_truthy
      end
    end

    context 'when status code is other than 00' do
      before do
        @transaction.update_column('gtpay_tranx_status_code', "Z6")
      end

      it "should return false" do
        expect(@transaction.successful_status_code?).to be_falsey
      end
    end
  end

  describe 'amount_in_cents' do
    before { @transaction.update(:gtpay_tranx_amount => 100) }
    it "should return amount in cents" do
      expect(@transaction.amount_in_cents).to eq(10000)
    end
  end

  describe 'successful?' do
    context 'when status is successful' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::SUCCESSFUL)
      end

      it "should return true" do
        expect(@transaction.successful?).to be_truthy
      end
    end

    context 'when status is pending' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::PENDING)
      end

      it "should return false" do
        expect(@transaction.successful?).to be_falsey
      end
    end
  end

  describe 'pending?' do
    context 'when status is pending' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::PENDING)
      end

      it "should return true" do
        expect(@transaction.pending?).to be_truthy
      end
    end

    context 'when status is unsuccessful' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::UNSUCCESSFUL)
      end

      it "should return false" do
        expect(@transaction.pending?).to be_falsey
      end
    end
  end

  describe 'unsuccessful?' do
    context 'when status is unsuccessful' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::UNSUCCESSFUL)
      end

      it "should return true" do
        expect(@transaction.unsuccessful?).to be_truthy
      end
    end

    context 'when status is pending' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::PENDING)
      end

      it "should return false" do
        expect(@transaction.unsuccessful?).to be_falsey
      end
    end
  end

  describe 'update_transaction' do
    context 'when successful_status_code?' do
      before do
        @transaction_params = {:gtpay_tranx_amount => 30.0, :gtpay_tranx_status_code => "00", :gtpay_tranx_status_msg => "Approved"}
        allow(@transaction).to receive(:update_transaction_on_query).and_return(true)
      end

      it "should_receive update_transaction_on_query" do
        expect(@transaction).to receive(:update_transaction_on_query).and_return(true)
        @transaction.update_transaction(@transaction_params)
      end
    end


    context 'when successful_status_code? is false' do
      before do
        allow(@transaction).to receive(:order_set_failure_for_payment).and_return(true)
        @transaction_params = {:gtpay_tranx_amount => 30.0, :gtpay_tranx_status_code => "Z0", :gtpay_tranx_status_msg => "Declined"}
      end

      it "should save values" do
        @transaction.update_transaction(@transaction_params)
        @transaction.reload
        expect(@transaction.gtpay_tranx_amount).to eq(30.0)
        expect(@transaction.gtpay_tranx_status_code).to eq("Z0")
        expect(@transaction.gtpay_tranx_status_msg).to eq("Declined")
      end
    end
  end


  describe 'update_transaction_on_query' do
    before do
      allow(@transaction).to receive(:order_complete_and_finalize).and_return(true)
      allow(@transaction).to receive(:send_transaction_mail).and_return(true)
      @transaction_params = {"Amount" => 3000.0, "ResponseCode" => "00", "ResponseDescription" => "Approved"}
      allow(@transaction).to receive(:query_interswitch).and_return(@transaction_params)
    end

    it "should_receive query_interswitch" do
      expect(@transaction).to receive(:query_interswitch).and_return(@transaction_params)
      @transaction.update_transaction_on_query
    end

    it "should update with transaction params" do
      @transaction.update_transaction_on_query
      @transaction.reload
      expect(@transaction.gtpay_tranx_amount).to eq(30.0)
      expect(@transaction.gtpay_tranx_status_code).to eq("00")
      expect(@transaction.gtpay_tranx_status_msg).to eq("Approved")
    end
  end

  describe 'delegate' do

    context 'to order' do

      it "should return total" do
        expect(@transaction.order_total).to eq(@order.reload.total)
      end

      it "should return gtpay_payment" do
        expect(@transaction.order_gtpay_payment).to eq(@order.gtpay_payment)
      end

      context 'complete_and_finalize' do
        before do
          @payment = double(Spree::Payment)
          allow(@order).to receive(:gtpay_payment).and_return(@payment)
          allow(@payment).to receive(:process_and_complete!)
          allow(@transaction).to receive(:order).and_return(@order)
        end

        it "receive complete_and_finalize on order" do
          expect(@order).to receive(:complete_and_finalize).and_return(true)
          @transaction.order_complete_and_finalize
        end
      end

      context 'order_set_failure_for_payment' do
        before do
          @payment = double(Spree::Payment)
          allow(@order).to receive(:gtpay_payment).and_return(@payment)
          allow(@payment).to receive(:process_and_complete!)
          allow(@transaction).to receive(:order).and_return(@order)
        end

        it "receive complete_and_finalize on order" do
          expect(@order).to receive(:set_failure_for_payment).and_return(true)
          @transaction.order_set_failure_for_payment
        end
      end

    end

  end

  describe 'webpay methods' do
    describe 'query_interswitch' do
      before do
        allow(@transaction).to receive(:transaction_params).and_return("productId=4880")
        allow(@transaction).to receive(:transaction_hash).and_return("abcde3wd")
        @response = { :parsed_response => ["abcd"] }
        allow(HTTParty).to receive(:get).and_return(@response)
      end

      it "should receive get on Httparty" do
        expect(HTTParty).to receive(:get).with("#{GT_DATA[:query_url]}productId=4880", {:headers => { "Hash" => "abcde3wd"} })
        @transaction.send(:query_interswitch)
      end

      it "should_receive parsed_response on response" do
        expect(@response).to receive(:parsed_response).and_return(true)
        @transaction.send(:query_interswitch)
      end

      context 'when exception occurs' do
        before do
          allow(HTTParty).to receive(:get).and_raise
        end

        it "should return empty hash" do
          expect(@transaction.send(:query_interswitch)).to eq({})
        end
      end
    end
  end



  describe 'transaction_params' do
    it "should return params" do
      expect(@transaction.send(:transaction_params)).to eq("?productid=#{GT_DATA[:product_id]}&transactionreference=#{@transaction.gtpay_tranx_id}&amount=#{@transaction.amount_in_cents}")
    end
  end


  describe 'transaction_hash' do
    it "should receive " do
      expect(Digest::SHA512).to receive(:hexdigest).with(GT_DATA[:product_id] + @transaction.gtpay_tranx_id + GT_DATA[:mac_id]).and_return("transaction_hash")
      @transaction.send(:transaction_hash)
    end
  end
end
