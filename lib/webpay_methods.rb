module WebpayMethods
  private

  def query_interswitch
    headers = {:headers => { "Hash" => transaction_hash} }
    begin
      HTTParty.get("#{GT_DATA[:query_url]}#{transaction_params}", headers).parsed_response
    rescue
      {}
    end
  end

  def transaction_params
    "?productid=#{GT_DATA[:product_id]}&transactionreference=#{gtpay_tranx_id}&amount=#{amount_in_cents}"
  end

  def transaction_hash
    Digest::SHA512.hexdigest(GT_DATA[:product_id] + gtpay_tranx_id + GT_DATA[:mac_id])
  end

end