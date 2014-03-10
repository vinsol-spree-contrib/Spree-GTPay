Spree::Admin::BaseHelper.module_eval do

  def set_selected_class(status = nil)
    if params[:q] && status == params[:q][:status_eq]
      return "tab_active"
    elsif !(status || params[:q])
      return "tab_active"
    end
  end
end