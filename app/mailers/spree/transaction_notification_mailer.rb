module Spree
  class TransactionNotificationMailer < ActionMailer::Base
    helper 'application'

    def send_mail(transaction)
      @transaction = transaction

      email = @transaction.user.email
      @order = @transaction.order
      @status = @transaction.status
      mail(
        :to => email,
        :subject => "#{Spree::Config[:site_name]} - GTbank Payment Transaction #{@status} notification"
      )
    end
  end
end