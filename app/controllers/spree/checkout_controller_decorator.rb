Spree::CheckoutController.class_eval do
  before_filter :redirect_to_gtpay, :only => [:update]
  helper_method :gtpay_payment_method

  def confirm
    @transaction = @order.gtpay_transactions.create { |t| t.user = spree_current_user }
    if @transaction.persisted?
      render :layout => false
    else
      set_flash_error
      redirect_to checkout_state_path(@order.state) and return
    end
  end

  private

  def redirect_to_gtpay
    if payment_page?
      payment_method = Spree::PaymentMethod.where(:id => (select_gtpay_payment(params[:order][:payments_attributes])[:payment_method_id])).first
      if payment_method.kind_of?(Spree::Gateway::Gtpay)
        if @order.update_attributes(object_params)
          redirect_to(gtpay_confirm_path) and return
        else
          flash[:error] = "Something went wrong. Please try again"
          redirect_to checkout_state_path("address") and return
        end
      end
    end
  end

  def payment_page?
    params[:state] == "payment" && params[:order][:payments_attributes]
  end

  def set_flash_error
    if @transaction.errors[:gtpay_tranx_amount].present?
      flash[:error] = "Minimum amount for order must be above #{Spree::Money.new(Spree::GtpayTransaction::MINIMUM_AMOUNT)}"
    else
      flash[:error] = "Something went wrong. Please try again"
    end
  end

  def select_gtpay_payment(payment_attributes)
    payment_attributes.select { |payment| payment["payment_method_id"] == gtpay_payment_method.id.to_s }.first
  end

  def gtpay_payment_method
    Spree::Gateway::Gtpay.first
  end

end