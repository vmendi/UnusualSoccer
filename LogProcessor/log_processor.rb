#!/usr/bin/env ruby

# Non-match errors
class General_Client_Error_Extractor
  
  def run all_lines, output_path

    players = {}
    discarded = {}

    all_lines.each { |line|
      # CLIENT_ERRORs discarding any line that contains MatchID
      the_line_match = line.match(/CLIENT_ERROR:(\d+)(?!.*MatchID).*/)

      if the_line_match != nil
        # We also want to discard common known errors as RealtimeConnectionFailed
        if line.match(/RealtimeConnectionFailed/)
          if not discarded.has_key? "RealtimeConnectionFailed"
            discarded["RealtimeConnectionFailed"] = 1
          else
            discarded["RealtimeConnectionFailed"] = discarded["RealtimeConnectionFailed"] + 1
          end

          next
        end

        # Store the line associating it with a playerID
        playerID = the_line_match[1]
        if players[playerID] == nil
          players[playerID] = []
        end
        players[playerID].push line
      end
    }

    # Print how many discarded and their kind we have
    discarded.keys.each { |key|
      puts "Discarded #{key}: #{discarded[key]} lines"
    }
    
    # Log everything to a general file, and also create a file per player
    File.open(output_path + "GeneralClient.txt", 'w') { |general_io|

      puts "Dumping #{players.length} players with some error..."

      players.keys.each { |key|
        File.open(output_path + "Player_#{key}.txt", 'w') { |player_io|
          players[key].each { |line|
            player_io.puts line
            general_io.puts line
          }
        }
      }
    }

    end

end

class Match_Error_Extractor

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
      File.open(output_path + "Match_#{num_match}.txt", 'w') { |io|
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
    if is_log_file dirEntry
      if (newest_time == nil ||
          (File.mtime(dirEntry) <=> newest_time) > 0)
          newest_time = File.mtime(dirEntry)
          newest_file = dirEntry
      end
    end
  }

  newest_file
end

def is_log_file dirEntry
  !File.directory?(dirEntry) && (File.extname(dirEntry) == '.log' || File.extname(dirEntry).match(/\d+/))
end

def prepare_output_path input_file

  output_path = input_file

  unless ARGV[1] == nil
    output_path = ARGV[1]
  end

  unless output_path.end_with?('/') || output_path.end_with?('\\')
    output_path += '_out/'
  end

  unless File.directory? output_path
    Dir::mkdir output_path
  end

  output_path
end

def get_input_file
  input_file = ARGV[0]

  if input_file == nil || !File.exists?(input_file)
    puts 'No file name supplied or file supplied doesnt exist. Looking for the most recent log...'        
    input_file = look_for_recent_log
  end
end

######################################
# Main program
######################################

input_file = get_input_file

if (input_file == nil)
  puts 'File not found... exiting.'
  exit
end

output_path = prepare_output_path input_file

puts "Reading file #{input_file}"

all_lines = IO.readlines input_file
puts all_lines.length.to_s + ' lines read'

the_match_processor = Match_Error_Extractor.new
the_match_processor.run(all_lines, output_path)

the_general_processor = General_Client_Error_Extractor.new
the_general_processor.run(all_lines, output_path)

the_chat_processor = Chat_Extractor.new
the_chat_processor.run(all_lines, output_path + "Chat.txt")

puts 'done'