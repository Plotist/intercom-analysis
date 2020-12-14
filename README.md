# intercom-analysis
Ruby interface for extraction and categorization of intercom conversation notes and related metadata

Example script 

```ruby
require "intercom"
require "dotenv/load"
require "./rate_control"
require "./conversations_fetcher"
require "./notes_writer"

intercom = Intercom::Client.new(token: ENV["INTERCOM_API_KEY"], handle_rate_limit: true)
# fresh it up
intercom.admins.me

# Set time_from for ConversationsFetcher. This is needed since current version of API
# only supports recurrent conversations extraction. Last argument is a simple per_page option
last_week = Time.now.to_i - 120

start_time = Time.now
conversations_fetcher = ConversationsFetcher.new(intercom, last_week, 50)
conversation_ids = conversations_fetcher.conversation_ids
puts "conversations gathered"
puts "conversations count: #{conversation_ids.count}"

# gather notes with applied pattern from fetched conversations
notes_writer = NotesWriter.new(intercom, conversation_ids, /\[.*\]/, {id: nil}, last_week)
notes_writer.write "./last_week_topics.csv" do |file, note|
  note_body = note[:conversation_part].body.gsub(/<[^>]*>/ui,'').gsub(',','').lstrip.rstrip
  line_content = "#{note[:conversation].id},#{note_body}"
  puts "about to write [#{line_content}]"
  file.write("#{line_content}\n")
end
end_time = Time.now

puts "Done in #{end_time-start_time} seconds"
 ```
