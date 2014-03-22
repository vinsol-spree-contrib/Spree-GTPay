require 'spec_helper'

describe Spree::GtpayTransaction do
  GT_DATA = {:product_id => "xxxx", :mac_id => "xxxxxxxxx", :query_url => "xxxxxx" }
  let(:shipping_category) { Spree::ShippingCategory.create!(:name => "Default Shipping") }
  before do
    Spree::Stock::Quantifier.any_instance.stub(can_supply?: true)
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
      Spree::GtpayTransaction::CURRENCY_CODE.should eq({ "NGN" => "566", "USD" => "844" })
    end

    it "should PENDING value" do
      Spree::GtpayTransaction::PENDING.should eq("Pending")
    end

    it "should MINIMUM_AMOUNT value" do
      Spree::GtpayTransaction::SUCCESSFUL.should eq("Successful")
    end

    it "should MINIMUM_AMOUNT value" do
      Spree::GtpayTransaction::UNSUCCESSFUL.should eq("Unsuccessful")
    end
  end

  describe 'scope pending' do
    before do
      @transaction1 = @order.gtpay_transactions.create! { |t| t.user = @user }
      @transaction1.status = "successful"
      @transaction1.save
      @transaction.stub(:order_complete_and_finalize).and_return(true)
      @transaction.stub(:send_transaction_mail).and_return(true)
    end
  
    it "should contain pending transactions" do
      Spree::GtpayTransaction.pending.should =~ [@transaction]
    end
  end

  describe 'scope successful' do
    before do
      @transaction1 = @order.gtpay_transactions.create! { |t| t.user = @user }
      @transaction1.stub(:order_complete_and_finalize).and_return(true)
      @transaction1.stub(:send_transaction_mail).and_return(true)
      @transaction1.status = "Successful"
      @transaction1.save!
    end
  
    it "should contain successful transactions" do
      Spree::GtpayTransaction.successful.should =~ [@transaction1]
    end
  end

  describe 'validations' do
    it { @transaction.should validate_presence_of(:user) }
    it { @transaction.should validate_presence_of(:gtpay_tranx_id) }
    it { @transaction.should validate_presence_of(:gtpay_tranx_amount) }
    it { @transaction.should validate_presence_of(:gtpay_tranx_currency) }
  
    context 'numericality' do
      before do
        @transaction.gtpay_tranx_amount = "ew"
      end

      it "should not save" do
        @transaction.save.should be_false
      end

    end
  end


  describe 'mass assignment' do
    it {should allow_mass_assignment_of(:gtpay_tranx_status_code)}
    it {should allow_mass_assignment_of(:gtpay_tranx_memo)}
    it {should allow_mass_assignment_of(:gtpay_tranx_status_msg)}
    it {should allow_mass_assignment_of(:gtpay_tranx_amount)}
  end

  describe 'associations' do
    it {should belong_to(:user)}
    it {should belong_to(:order)}
  end

  describe 'amount_valid?' do
    context 'when order total is = than gtpay_tranx_amount' do
      it "return true" do
        @transaction.amount_valid?.should be_true
      end
    end

    context 'when order total is more than gtpay_tranx_amount' do
      before do
        @transaction.stub(:order_total).and_return(10000)
      end

      it "return false" do
        @transaction.amount_valid?.should be_false
      end
    end
  end

  describe 'generate_tranx_id' do
    context 'on create' do
      before do
        @transaction1 = @order.gtpay_transactions.create! {|t| t.user = @user }
      end

      it "should generate_tranx_id" do
        @transaction1.gtpay_tranx_id.should be_present
        @transaction1.gtpay_tranx_id.size.should be(18)
      end
    end

    context 'on update' do
      before do
        @tranx_id = @transaction.gtpay_tranx_id
        @transaction.update_attributes(:gtpay_tranx_amount => 100)
      end

      it "transaction tranx_id should remain same" do
        @transaction.gtpay_tranx_id.should eq(@tranx_id)
      end
    end
  end

  describe 'set_status' do
    context 'when gtpay_tranx_status_code changed' do

      context 'when successful_status_code and amount valid' do
        before do
          @transaction.stub(:order_complete_and_finalize).and_return(true)
          @transaction.stub(:send_transaction_mail).and_return(true)
          @transaction.gtpay_tranx_status_code = "00"
          @transaction.save
        end

        it "should set status to successful" do
          @transaction.status.should eq("Successful")
        end
      end


      context 'when successful_status_code is false' do
        before do
          @transaction.stub(:order_set_failure_for_payment).and_return(true)
          @transaction.gtpay_tranx_status_code = "Z0"
          @transaction.save
        end

        it "should set status to unsuccessful" do
          @transaction.status.should eq("Unsuccessful")
        end
      end

      context 'when amount_valid is false' do
        before do
          @transaction.stub(:order_set_failure_for_payment).and_return(true)
          @transaction.gtpay_tranx_amount = 25.0
          @transaction.gtpay_tranx_status_code = "00"
          @transaction.save
        end

        it "should set status to unsuccessful" do
          @transaction.status.should eq("Unsuccessful")
        end
      end
    end

    context 'when gtpay_tranx_status_code not changed' do
      before do
        @transaction.gtpay_tranx_amount = 25.0
      end

      it "should not receive set_status" do
        @transaction.should_not_receive(:set_status)
        @transaction.save
      end
    end
  end

  describe 'order_complete_and_finalize' do
    context 'when status changed to successful' do
      before do
        @transaction.status = "Successful"
        @transaction.stub(:send_transaction_mail).and_return(true)
      end

      it "should receive order_complete_and_finalize" do
        @transaction.should_receive(:order_complete_and_finalize).and_return(true)
        @transaction.save
      end
    end

    context 'when status changed to pending' do
      before do
        @transaction.status = "Pending"
      end

      it "should not receive order_complete_and_finalize" do
        @transaction.should_not_receive(:order_complete_and_finalize)
        @transaction.save
      end
    end

    context 'when status not changed' do
      before do
        @transaction.gtpay_tranx_amount = 32.0
      end

      it "should not receive order_complete_and_finalize" do
        @transaction.should_not_receive(:order_complete_and_finalize)
        @transaction.save
      end
    end
  end

  describe 'send_transaction_mail' do
    context 'when status changed to successful' do
      before do
        @transaction.stub(:order_complete_and_finalize).and_return(true)
        @transaction.status = "Successful"
        @job = double(Delayed::Job)
        Spree::TransactionNotificationMailer.stub(:delay).and_return(@job)
        @job.stub(:send_mail).and_return(true)
      end

      it "should receive delay on TransactionNotificationMailer" do
        Spree::TransactionNotificationMailer.should_receive(:delay).and_return(@job)
        @transaction.save
      end

      it "should_receive send_mail on delayed job" do
        @job.should_receive(:send_mail).with(@transaction).and_return(true)
        @transaction.save
      end
    end

    context 'when status changed to pending' do
      before do
        @transaction.status = "Pending"
      end

      it "should not receive send_transaction_mail" do
        @transaction.should_not_receive(:send_transaction_mail)
        @transaction.save
      end
    end

    context 'when status not changed' do
      before do
        @transaction.gtpay_tranx_amount = 32.0
      end

      it "should not receive send_transaction_mail" do
        @transaction.should_not_receive(:send_transaction_mail)
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
        @transaction.should_receive(:order_set_failure_for_payment).and_return(true)
        @transaction.save
      end
    end

    context 'when status changed to pending' do
      before do
        @transaction.status = "Pending"
      end

      it "should not receive order_set_failure_for_payment" do
        @transaction.should_not_receive(:order_set_failure_for_payment)
        @transaction.save
      end
    end

    context 'when status not changed' do
      before do
        @transaction.gtpay_tranx_amount = 32.0
      end

      it "should not receive order_set_failure_for_payment" do
        @transaction.should_not_receive(:order_set_failure_for_payment)
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
        @transaction.gtpay_tranx_currency.should eq(Spree::GtpayTransaction::CURRENCY_CODE[@order.currency])
      end

      it "should set amount" do
        @transaction.gtpay_tranx_amount.should eq(@order.reload.total)
      end

      it "should set status" do
        @transaction.status.should eq("Pending")
      end
    end

    context 'on update' do
      before do
        @status = @transaction.status
        @transaction.update_attributes(:gtpay_tranx_amount => 100)
      end

      it "transaction status should remain same" do
        @transaction.status.should eq(@status)
      end
    end
  end

  describe 'successful_status_code?' do
    context 'when status code is 00' do
      before do
        @transaction.update_column('gtpay_tranx_status_code', "00")
      end

      it "should return true" do
        @transaction.successful_status_code?.should be_true
      end
    end

    context 'when status code is other than 00' do
      before do
        @transaction.update_column('gtpay_tranx_status_code', "Z6")
      end

      it "should return false" do
        @transaction.successful_status_code?.should be_false
      end
    end
  end

  describe 'amount_in_cents' do
    it "should return amount in cents" do
      @transaction.amount_in_cents.should eq(3000)
    end
  end

  describe 'successful?' do
    context 'when status is successful' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::SUCCESSFUL)
      end

      it "should return true" do
        @transaction.successful?.should be_true
      end
    end

    context 'when status is pending' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::PENDING)
      end

      it "should return false" do
        @transaction.successful?.should be_false
      end
    end
  end

  describe 'pending?' do
    context 'when status is pending' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::PENDING)
      end

      it "should return true" do
        @transaction.pending?.should be_true
      end
    end

    context 'when status is unsuccessful' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::UNSUCCESSFUL)
      end

      it "should return false" do
        @transaction.pending?.should be_false
      end
    end
  end

  describe 'unsuccessful?' do
    context 'when status is unsuccessful' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::UNSUCCESSFUL)
      end

      it "should return true" do
        @transaction.unsuccessful?.should be_true
      end
    end

    context 'when status is pending' do
      before do
        @transaction.update_column('status', Spree::GtpayTransaction::PENDING)
      end

      it "should return false" do
        @transaction.unsuccessful?.should be_false
      end
    end
  end

  describe 'update_transaction' do
    context 'when successful_status_code?' do
      before do
        @transaction_params = {:gtpay_tranx_amount => 30.0, :gtpay_tranx_status_code => "00", :gtpay_tranx_status_msg => "Approved"}
        @transaction.stub(:update_transaction_on_query).and_return(true)
      end

      it "should_receive update_transaction_on_query" do
        @transaction.should_receive(:update_transaction_on_query).and_return(true)
        @transaction.update_transaction(@transaction_params)
      end
    end


    context 'when successful_status_code? is false' do
      before do
        @transaction.stub(:order_set_failure_for_payment).and_return(true)
        @transaction_params = {:gtpay_tranx_amount => 30.0, :gtpay_tranx_status_code => "Z0", :gtpay_tranx_status_msg => "Declined"}
      end

      it "should save values" do
        @transaction.update_transaction(@transaction_params)
        @transaction.reload
        @transaction.gtpay_tranx_amount.should eq(30.0)
        @transaction.gtpay_tranx_status_code.should eq("Z0")
        @transaction.gtpay_tranx_status_msg.should eq("Declined")
      end
    end
  end


  describe 'update_transaction_on_query' do
    before do
      @transaction.stub(:order_complete_and_finalize).and_return(true)
      @transaction.stub(:send_transaction_mail).and_return(true)
      @transaction_params = {"Amount" => 3000.0, "ResponseCode" => "00", "ResponseDescription" => "Approved"}
      @transaction.stub(:query_interswitch).and_return(@transaction_params)
    end

    it "should_receive query_interswitch" do
      @transaction.should_receive(:query_interswitch).and_return(@transaction_params)
      @transaction.update_transaction_on_query
    end

    it "should update with transaction params" do
      @transaction.update_transaction_on_query
      @transaction.reload
      @transaction.gtpay_tranx_amount.should eq(30.0)
      @transaction.gtpay_tranx_status_code.should eq("00")
      @transaction.gtpay_tranx_status_msg.should eq("Approved")
    end
  end

  describe 'delegate' do

    context 'to order' do

      it "should return total" do
        @transaction.order_total.should eq(@order.reload.total)
      end

      it "should return gtpay_payment" do
        @transaction.order_gtpay_payment.should eq(@order.gtpay_payment)
      end

      context 'complete_and_finalize' do
        before do
          @payment = mock_model(Spree::Payment)
          @order.stub(:gtpay_payment).and_return(@payment)
          @payment.stub(:process_and_complete!)
          @transaction.stub(:order).and_return(@order)
        end

        it "receive complete_and_finalize on order" do
          @order.should_receive(:complete_and_finalize).and_return(true)
          @transaction.order_complete_and_finalize
        end
      end

      context 'order_set_failure_for_payment' do
        before do
          @payment = mock_model(Spree::Payment)
          @order.stub(:gtpay_payment).and_return(@payment)
          @payment.stub(:process_and_complete!)
          @transaction.stub(:order).and_return(@order)
        end

        it "receive complete_and_finalize on order" do
          @order.should_receive(:set_failure_for_payment).and_return(true)
          @transaction.order_set_failure_for_payment
        end
      end

    end

  end

  describe 'webpay methods' do
    describe 'query_interswitch' do
      before do
        @transaction.stub(:transaction_params).and_return("productId=4880")
        @transaction.stub(:transaction_hash).and_return("abcde3wd")
        @response = { :parsed_response => ["abcd"] }
        HTTParty.stub(:get).and_return(@response)
      end

      it "should receive get on Httparty" do
        HTTParty.should_receive(:get).with("#{GT_DATA[:query_url]}productId=4880", {:headers => { "Hash" => "abcde3wd"} })
        @transaction.send(:query_interswitch)
      end

      it "should_receive parsed_response on response" do
        @response.should_receive(:parsed_response).and_return(true)
        @transaction.send(:query_interswitch)
      end

      context 'when exception occurs' do
        before do
          HTTParty.stub(:get).and_raise
        end

        it "should return empty hash" do
          @transaction.send(:query_interswitch).should eq({})
        end
      end
    end
  end



  describe 'transaction_params' do
    it "should return params" do
      @transaction.send(:transaction_params).should eq("?productid=#{GT_DATA[:product_id]}&transactionreference=#{@transaction.gtpay_tranx_id}&amount=#{@transaction.amount_in_cents}")
    end
  end


  describe 'transaction_hash' do
    it "should receive " do
      Digest::SHA512.should_receive(:hexdigest).with(GT_DATA[:product_id] + @transaction.gtpay_tranx_id + GT_DATA[:mac_id]).and_return("transaction_hash")
      @transaction.send(:transaction_hash)
    end
  end
end