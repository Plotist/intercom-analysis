require "./rate_control"

class NotesWriter

  def initialize(intercom, conversation_ids, pattern, skip_pattern_for, since)
    @intercom = intercom
    @conversation_ids = conversation_ids
    @pattern = pattern
    @skip_pattern_for = skip_pattern_for
    @since = since
  end

  def write(to_file_name)
    File.open(to_file_name, 'w') do |file|
      @conversation_ids.each do |conv_id|
        begin
          params = {id: conv_id}
          conversation = intercom_request @intercom, params do |p|
            @intercom.conversations.find(p)
          end

          next unless conversation_satisfiable?(conversation)

          user = intercom_request @intercom, params do |p|
            @intercom.users.find({id: conversation.user.id})
          end

          country_name = "Not defined"
          if user.location_data.is_a?(Intercom::LocationData) && user.location_data.country_name
            country_name = user.location_data.country_name
          end

          user_email = "Not defined"
          if user.email
            user_email = user.email
          end

          notes = []
          conversation.conversation_parts.each do |cp|
            compose_note_object(notes, cp, conversation, country_name, user_email)
          end
          notes.each do |note|
            yield file, note
          end
        rescue => e
          puts "{{Failed #{conv_id}: }} #{e}"
          next
        end
      end
    end
  end

  def compose_note_object(notes, cp, conversation, country_name, user_email)
    if note_satisfiable?(cp)
      notes << { conversation_part: cp, conversation: conversation, country_name: country_name, email: user_email }
    end
  end

  def note_satisfiable?(conversation_part)
    (conversation_part.created_at.to_i < @since) &&
    ((conversation_part.part_type === "note" && conversation_part.body.downcase.match(@pattern)) ||
        (conversation_part.part_type === "note" && conversation_part.author.id === @skip_pattern_for[:id]))
  end

  def conversation_satisfiable?(conv)
    matches = 0
    conv.conversation_parts.each do |cp|
      matches+=1 if note_satisfiable?(cp)
    end
    matches > 0
  end
end
