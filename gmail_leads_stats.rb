require 'gmail'

#TODO do the job
  #TODO messages stats
  #TODO time parameter
        #TODO: (everything by default)
  
#TODO package:
      #TODO basic UI
      #TODO oauth

#TODO: use method alias to append my code
#TODO: patch only our own instance of Net::IMap::ResponseParser

module Net
  class IMAP
    class ResponseParser 
      def msg_att
        match(T_LPAR)
        attr = {}
        while true
          token = lookahead
          case token.symbol
          when T_RPAR
            shift_token
            break
          when T_SPACE
            shift_token
            token = lookahead
          end
          case token.value
          when /\A(?:ENVELOPE)\z/ni
            name, val = envelope_data
          when /\A(?:FLAGS)\z/ni
            name, val = flags_data
          when /\A(?:INTERNALDATE)\z/ni
            name, val = internaldate_data
          when /\A(?:RFC822(?:\.HEADER|\.TEXT)?)\z/ni
            name, val = rfc822_text
          when /\A(?:RFC822\.SIZE)\z/ni
            name, val = rfc822_size
          when /\A(?:BODY(?:STRUCTURE)?)\z/ni
            name, val = body_data
          when /\A(?:UID)\z/ni
            name, val = uid_data

          when /\A(?:X-GM-MSGID)\z/ni  # Added X-GM-MSGID extension
            name, val = uid_data
          when /\A(?:X-GM-THRID)\z/ni  # Added X-GM-THRID extension
            name, val = uid_data

          else
            parse_error("unknown attribute `%s'", token.value)
          end
          attr[name] = val
        end
        return attr
      end

    end
  end
end

module GmailAnalytics

  module GmailIntegration

    def self.pull_thread_ids(login,password,days)
      emails, thread_ids = nil
    
      after_date = if days.to_i > 0
        Date.today - days.to_i
      else
        nil
      end
    
      Gmail.new(login, password) do |gmail|
        mailbox = gmail.mailbox("[Gmail]/All Mail")
    
        query_filters = if after_date
          {:after => after_date}
        else
          {}
        end
    
        emails = mailbox.emails query_filters
    
        uids_range = emails.first.uid .. emails.last.uid
    
        response_rows = gmail.imap.uid_fetch( uids_range, "(X-GM-THRID)")
    
        thread_ids = response_rows.map {|row|
          row.attr["X-GM-THRID"].to_s(16)
        }
      end
    
      thread_ids
    end

  end

  module DataAnalysis
  
    def self.thread_ids_counters(thread_ids)
      thread_ids_counters = {}
      thread_ids.each do |thread_id|
        thread_ids_counters[thread_id] ||= 0
        thread_ids_counters[thread_id] += 1
      end

      thread_ids_counters
    end

    def self.thread_length_stats(thread_ids_counters)
      thread_stats = []
      thread_ids_counters.values.each do |count|
        next if count.nil?
        thread_stats[count] ||= 0
        thread_stats[count] += 1
      end
      thread_stats
    end

    def self.four_steps_stats(thread_length_stats)
      four_steps_stats = (1..4).map{ |thread_length|
        thread_lengths_to_include = thread_length..-1
        thread_counters = thread_length_stats[thread_lengths_to_include]
        thread_counters.reject(&:nil?).inject(:+)
      }
    end

    def self.generate_thread_stats(thread_ids)
      thread_ids_counters = thread_ids_counters(thread_ids)
      thread_length_stats = thread_length_stats(thread_ids_counters)
      four_steps_stats = four_steps_stats(thread_length_stats)
      [four_steps_stats, thread_length_stats]
    end

  end
  
  module Presentation

    def self.present_stats(four_step_stats, full_thread_stats)
      output = ""
    
      output << "Four steps stats:\n"
      output << "Step 1 - inquiry:        #{four_step_stats[0]}\n"
      output << "Step 2 - instructions:   #{four_step_stats[1]}\n"
      output << "Step 3 - confirmation:   #{four_step_stats[2]}\n"
      output << "Step 4 - details:        #{four_step_stats[3]}\n"
      output << "\n\n"
    
      output << "Full thread length stats (number of threads by length):\n"
    
      full_thread_stats.each_with_index do |number_of_threads, thread_length|
        if thread_length && number_of_threads
          output <<  "|% 5d|% 5d|\n" % [thread_length, number_of_threads]
        end
      end
    
      output
    end
    
  end
    
  def self.run(login,password,days)

    thread_ids = GmailIntegration.pull_thread_ids(login,password,days)
    four_steps_stats, full_thread_stats = DataAnalysis.generate_thread_stats(thread_ids)
    Presentation.present_stats four_steps_stats, full_thread_stats 
  end
  
end
