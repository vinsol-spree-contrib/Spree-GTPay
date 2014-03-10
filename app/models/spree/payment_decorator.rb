Spree::Payment.class_eval do
  
  def process_and_complete!
    started_processing!
    complete!
  end
end