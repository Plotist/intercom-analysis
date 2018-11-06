def intercom_request(intercom, request_block)
  limit_details = intercom.rate_limit_details
  if limit_details[:remaining] <= 2
    puts "requests limit is less then/equal to 2"
    puts "sleeping for #{limit_details[:reset_at].to_i - Time.now.to_i} seconds"
    if limit_details[:reset_at].to_i > Time.now.to_i
      sleep(limit_details[:reset_at].to_i - Time.now.to_i)
      yield request_block
    else
      intercom_request(intercom, request_block)
    end
  else
    yield request_block
  end
end