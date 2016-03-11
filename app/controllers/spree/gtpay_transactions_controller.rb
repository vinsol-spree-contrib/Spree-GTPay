module Spree
  class GtpayTransactionsController < StoreController
    before_action :load_gtpay_transaction, only: :callback
    skip_before_action :verify_authenticity_token, only: :callback
    before_action :authenticate_spree_user!, :only => :index

    def callback
      if  @transaction.update_transaction(transaction_params) && @transaction.successful?
        reset_redirect_to_order_detail
      else
        flash[:error] = Spree.t(:unsuccessful_transaction, status_msg: @transaction.gtpay_tranx_status_msg, transaction_id: @transaction.gtpay_tranx_id).html_safe
        redirect_to checkout_state_path(current_order.state)
      end
    end

    def index
      @transactions = spree_current_user.gtpay_transactions.includes(:order).order('updated_at desc').page(params[:page]).per(20)
    end

    private

    def load_gtpay_transaction
      unless @transaction = current_order.gtpay_transactions.pending.where(:gtpay_tranx_id => params[:gtpay_tranx_id]).first
        redirect_to checkout_state_path(current_order.state), :flash => { :error => Spree.t(:unprocessable_order, status_msg: params[:gtpay_tranx_status_msg], transaction_id: params[:gtpay_tranx_id]).html_safe }
      end
    end

    def transaction_params
      { :gtpay_tranx_amount => params[:gtpay_tranx_amt], gtpay_tranx_status_code: params[:gtpay_tranx_status_code], gtpay_tranx_status_msg: params[:gtpay_tranx_status_msg] }
    end

    def reset_redirect_to_order_detail
      session[:order_id] = nil
      flash.notice = Spree.t(:order_processed, transaction_id: params[:gtpay_tranx_id], status_code: params[:gtpay_tranx_status_code], status_msg: params[:gtpay_tranx_status_msg]).html_safe
      redirect_to spree.order_path(current_order)
    end

  end
end
