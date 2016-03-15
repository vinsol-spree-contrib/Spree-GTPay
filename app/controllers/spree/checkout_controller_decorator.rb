Spree::CheckoutController.class_eval do
  before_action :redirect_to_gtpay, only: :update
  helper_method :gtpay_payment_method

  def confirm
    @transaction = @order.gtpay_transactions.create { |t| t.user = spree_current_user }
    if @transaction.persisted?
      render layout: false
    else
      set_flash_error
      redirect_to checkout_state_path(@order.state) and return
    end
  end

  private
  def redirect_to_gtpay
    if payment_page?
      payment_method =  Spree::PaymentMethod.where(id: params[:order][:payments_attributes].first['payment_method_id']).first
      if payment_method.kind_of?(Spree::Gateway::Gtpay)
        if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
          redirect_to(gtpay_confirm_path)
        else
          flash[:error] = Spree.t(:internal_error)
          redirect_to checkout_state_path(@order.state)
        end
      end
    end
  end

  def payment_page?
    params[:state] == "payment" && params[:order][:payments_attributes]
  end

  def set_flash_error
    if @transaction.errors[:gtpay_tranx_amount].present?
      flash[:error] = Spree.t(:minimum_amount, minimum_amount: Spree::Money.new(Spree::GtpayTransaction::MINIMUM_AMOUNT))
    else
      flash[:error] = Spree.t(:internal_error)
    end
  end

  def gtpay_payment_method
    Spree::Gateway::Gtpay.first
  end

end
