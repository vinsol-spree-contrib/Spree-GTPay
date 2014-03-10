module Spree
  module Admin
    class GtpayTransactionsController < ResourceController

      def index
        @search = Spree::GtpayTransaction.ransack(params[:q])
        @gtpay_transactions = @search.result.order('created_at desc').page(params[:page]).per(20)
      end

      def query_interface
        @gtpay_transaction.update_transaction_on_query
      end

    end
  end
end