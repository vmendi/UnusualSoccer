#!/usr/bin/env ruby

class Error_Extractor

  def run all_lines, output_path

    # Matches with any error
    matches = []

    # A good regular expression tester: http://www.rubular.com/
    all_lines.each { |line|
      # Exceptions in the server
      match_data = line.match(/TargetInvocationException:.*MatchID: (\d+)/)

      # Exceptions in the server, alternate method
      if match_data == nil
        match_data = line.match(/ServerException:.*MatchID: (\d+)/)
      end

      # UNSYNCS
      if match_data == nil
        match_data = line.match(/>{6} (\d+)/)
      end

      # Exceptions in the client
      if match_data == nil
        match_data = line.match(/CLIENT_ERROR.*MatchID: (\d+)/)
      end

      if match_data != nil
        # We always have the matchID in the first group
        matchID = match_data[1]
        matches.push matchID
      end
    }

    matches.uniq!

    puts 'Dumping ' + matches.length.to_s + ' matches'

    # We generate a file for each match with error
    matches.each { |num_match|
      File.open(output_path + "_" + num_match + '.txt', 'w') { |io|
        get_lines_for_match(all_lines, num_match).each { |line| io.puts line }
      }
    }
  end

  # Returns only the lines for 'num_match'
  def get_lines_for_match (global_lines, num_match)
    ret = []
    global_lines.each { |line|
      unless line.index(num_match) == nil
        ret.push line
      end
    }
    ret
  end

end

class Chat_Extractor
  def run all_lines, output_filename

    # Hash with key == match_id, value == Array with every chat line for that match
    chat_lines_per_match = {}

    all_lines.each { |line|
      # 443086 Chat:
      chat_match = line.match(/(\d+) Chat:/)

      if chat_match != nil
        match_id = chat_match[1]   # matchID is always in the first group

        # Create the array for the given match if not created yet
        unless chat_lines_per_match.has_key? match_id
          chat_lines_per_match[match_id] = []
        end

        # Add new chat line to the match
        chat_lines_per_match[match_id].push line
      end
    }

    # Write all the matches chats to one file
    File.open(output_filename, 'w') { |io|
      chat_lines_per_match.each_key { |match_id|
        io.puts "========== Chat for match " + match_id + "=========="

        chat_lines_per_match[match_id].each { |line| io.puts line }

        io.puts ""
      }
    }

  end
end

def look_for_recent_log
  newest_time = nil
  newest_file = nil

  Dir.foreach('./') { |dirEntry|
    if !File.directory?(dirEntry) && File.extname(dirEntry) == '.log'
      if (newest_time == nil ||
          (File.mtime(dirEntry) <=> newest_time) > 0)
          newest_time = File.mtime(dirEntry)
          newest_file = dirEntry
      end
    end
  }

  newest_file
end


input = ARGV[0]

if input == nil || !File.exists?(input)
  input = look_for_recent_log
  if (input == nil)
    puts 'File not found'
    exit
  end
end

output_path = './log_processor_output/'

unless ARGV[1] == nil
  output_path = ARGV[1]
end

unless output_path.end_with?('/') || output_path.end_with?('\\')
output_path += '/'
end

unless File.directory? output_path
  Dir::mkdir output_path
end

puts 'Reading file ' + input

all_lines = IO.readlines input
puts all_lines.length.to_s + ' lines read'

the_processor = Error_Extractor.new
the_processor.run(all_lines, output_path + input)

the_chat_processor = Chat_Extractor.new
the_chat_processor.run(all_lines, output_path + input + '_chat.txt')

puts 'done'