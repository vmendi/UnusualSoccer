#!/usr/bin/env ruby

# Non-match errors
class General_Error_Extractor
  
  def run all_lines, output_path

    server = []
    players = {}
    discarded = {}

    all_lines.each { |line|
      # CLIENT_ERRORs discarding any line that contains MatchID
      client_match = line.match(/CLIENT_ERROR:(\d+)(?!.*MatchID).*/)

      if client_match != nil
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
        playerID = client_match[1]
        if players[playerID] == nil
          players[playerID] = []
        end
        players[playerID].push line       
      end

      # Server errors. Any line with an [ERROR] tag and not CLIENT_ERROR in it
      server_match = line.match(/\[ERROR\](?!.*CLIENT_ERROR).*/)

      if server_match != nil
        server.push line
      end
    }

    # Print how many discarded and their kind we have
    discarded.keys.each { |key|
      puts "Discarded #{key}: #{discarded[key]} lines"
    }
    
    # Create a file per player and while we are at it, log everything to a general file as well
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

    # Now the non-client errors
    File.open(output_path + "GeneralServer.txt", 'w') { |general_io|

      puts "Dumping #{server.length} server lines with some error..."

      server.each { |line|
        general_io.puts line
      }
    }

    end

end

class Match_Error_Extractor

  def run all_lines, output_path

    # A hash with the match_id as key and an array of lines as value
    matches = {}

    # A good regular expression tester: http://www.rubular.com/
    all_lines.each { |line|
      
      match_data = line.match(/MatchID.? (\d+)/)
      
      if match_data != nil
        # We always have the matchID in the first group
        match_id = match_data[1]
        
        if matches[match_id] == nil
          matches[match_id] = []
        end

        matches[match_id].push line
      end
    }

    puts matches.keys.length.to_s + ' matches detected'
    dumped_matches_count = 0

    # We generate a file for each match with error
    matches.keys.each { |match_id|
      if has_any_match_error matches[match_id]
        dumped_matches_count = dumped_matches_count + 1
        File.open(output_path + "Match_#{match_id}.txt", 'w') { |io|
          matches[match_id].each { |line| io.puts line }
        }
      end
    }

    puts 'Dumped ' + dumped_matches_count.to_s + ' matches'
  end

  def has_any_match_error(the_match)
    the_match.each { |line|
       # Exceptions in the server
      if line.match(/TargetInvocationException:/)
        return true
      end

      # Exceptions in the server, alternate method
      if line.match(/ServerException:/)
        return true
      end

      # UNSYNCS
      if line.match(/>{6}/)
        return true
      end

      # Exceptions in the client
      if line.match(/CLIENT_ERROR/)
        return true
      end
    }
    return false
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

  Dir.foreach('./logs/') { |dirEntry|
    dirEntry = "./logs/" + dirEntry
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
  !File.directory?(dirEntry) && (File.extname(dirEntry) == '.log' || File.extname(dirEntry) == '.txt' || File.extname(dirEntry).match(/\d+/))
end

def prepare_output_path input_file

  output_path = File.basename(input_file)

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

the_general_processor = General_Error_Extractor.new
the_general_processor.run(all_lines, output_path)

the_chat_processor = Chat_Extractor.new
the_chat_processor.run(all_lines, output_path + "Chat.txt")

puts 'done'