module Spree
  class GtpayTransaction < ActiveRecord::Base
    include WebpayMethods

    CURRENCY_CODE = { "NGN" => "566", "USD" => "844" }
    MINIMUM_AMOUNT = 25
    PENDING      = 'Pending'
    SUCCESSFUL  = 'Successful'
    UNSUCCESSFUL = 'Unsuccessful'

    before_validation :generate_tranx_id, :set_default_attirbutes, on: :create
    before_update :set_status, if: :gtpay_tranx_status_code_changed?
    before_update :order_complete_and_finalize, :send_transaction_mail, if: [:status_changed?, :successful?]
    before_update :order_set_failure_for_payment, if: [:status_changed?, :unsuccessful?]

    validates :gtpay_tranx_id, :user, :gtpay_tranx_amount, :gtpay_tranx_currency, presence: true
    validates :gtpay_tranx_amount, numericality: true

    belongs_to :user
    belongs_to :order

    scope :pending, -> { where(status: PENDING) }
    scope :successful, -> { where(status: SUCCESSFUL) }

    delegate :total, :gtpay_payment, :complete_and_finalize, :set_failure_for_payment, to: :order, prefix: true
    delegate :email, to: :user, allow_nil: true

    def amount_in_cents
      (gtpay_tranx_amount.to_f*100).round.to_i
    end

    def successful?
      status == SUCCESSFUL
    end

    def pending?
      status == PENDING
    end

    def unsuccessful?
      status == UNSUCCESSFUL
    end

    def amount_valid?
      gtpay_tranx_amount >= order_total
    end

    def successful_status_code?
      gtpay_tranx_status_code == "00"
    end

    def update_transaction(transaction_params)
      self.gtpay_tranx_amount = transaction_params[:gtpay_tranx_amount]
      self.gtpay_tranx_status_code = transaction_params[:gtpay_tranx_status_code]
      self.gtpay_tranx_status_msg = transaction_params[:gtpay_tranx_status_msg]
      if successful_status_code?
        update_transaction_on_query
      else
        self.save(validate: false)
      end
    end

    def update_transaction_on_query
      response = query_interswitch
      self.gtpay_tranx_status_code = response["ResponseCode"]
      self.gtpay_tranx_status_msg = response["ResponseDescription"]
      self.gtpay_tranx_amount = response["Amount"].to_f / 100
      save(validate: false)
    end

    private

    def set_status
      if successful_status_code? && amount_valid?
        self.status = SUCCESSFUL
      else
        self.status = UNSUCCESSFUL
      end
    end

    def generate_tranx_id
      begin
        self.gtpay_tranx_id = "#{ENVIRONMENT_INITIALS}" + SecureRandom.hex(8)
      end while GtpayTransaction.exists?(gtpay_tranx_id: gtpay_tranx_id)
    end

    def set_default_attirbutes
      self.gtpay_tranx_currency = CURRENCY_CODE[order.currency]
      self.gtpay_tranx_amount = order_total
      self.status = PENDING
    end

    def send_transaction_mail
      if defined? ::Delayed
        Spree::TransactionNotificationMailer.send_mail(self).deliver_later
      else
        Spree::TransactionNotificationMailer.send_mail(self)
      end
    end
  end

end
