require "./rate_control"

class ConversationsFetcher
  attr_accessor :conversation_ids

  def initialize(intercom, since, per_page)
    @intercom = intercom
    @since = since
    @per_page = per_page
    @conversation_ids = []
    run
  end

  def run
    fetching = true
    page = 1
    while fetching
      params = {page: page, per_page: @per_page}
      conversations = intercom_request @intercom, params do |p|
        @intercom.conversations.find_all(p)
      end
      conversations.each do |conversation|
        @conversation_ids << conversation.id
        if conversation.updated_at.to_i < @since
          fetching = false
        end
      end
      puts "iteration #{page}"
      page+=1
    end
  end
end