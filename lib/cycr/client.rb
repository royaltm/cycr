require 'net/telnet'

module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # This class is the implementation of the Cyc server client.
  class Client
    # If set to true, all communication with the server is logged
    # to standard output
    attr_accessor :debug
    attr_reader :host, :port

    # Error raised if the Cyc server reports an error
    class CycError < RuntimeError
    end

    # Creates new Client.
    def initialize(host="localhost",port="3601",debug=false)
      @debug = debug
      @host = host
      @port = port
      @pid = Process.pid
      @parser = Parser.new
      @mts_cache = {}
      @builder = Builder.new
    end

    # (Re)connects to the cyc server.
    def reconnect
      @pid = Process.pid
      @conn = Net::Telnet.new("Port" => @port, "Telnetmode" => false,
                              "Timeout" => 600, "Host" => @host)
    end

    # Returns the connection object. Ensures that the pid of current
    # process is the same as the pid, the connection was initialized with.
    #
    # If the block is given, the command is guarded by assertion, that
    # it will be performed, even if the connection was reset.
    def connection
      #puts "#{@pid} #{Process.pid}"
      if @conn.nil? or @pid != Process.pid
        reconnect
      end
      if block_given?
        begin
          yield @conn
        rescue Errno::ECONNRESET
          reconnect
          yield @conn
        end
      else
        @conn
      end
    end

    protected :connection, :reconnect

    def clear_cache
      @mts_cache = {}
    end

    # Closes connection with the server
    def close
      connection{|c| c.puts("(api-quit)")}
      @conn = nil
    end

    # Sends message +msg+ directly to the Cyc server and
    # returns the parsed answer.
    def talk(msg, options={})
      send_message(msg)
      receive_answer(options)
    end

    # Sends message +msg+ directly to the Cyc server and
    # returns the raw answer (i.e. not parsed).
    def raw_talk(msg, options={})
      send_message(msg)
      receive_raw_answer(options)
    end

    # Send the raw message.
    def send_message(msg)
      @last_message = msg
      puts "Send: #{msg}" if @debug
      connection{|c| c.puts(msg)}
    end

    def receive_answer(options={})
      receive_raw_answer do |answer|
        begin
          result = @parser.parse(answer,options[:stack])
        rescue Parser::ContinueParsing => ex
          result = ex.stack
          current_result = result
          last_message = @last_message
          while current_result.size == 100 do
            send_message("(subseq #{last_message} #{result.size} " +
                         "#{result.size + 100})")
            current_result = receive_answer(options) || []
            result.concat(current_result)
          end
        rescue CycError => ex
          puts ex.to_s
          return nil
        end
        return result
      end
    end

    # Receive raw answer from server. If a +block+ is given
    # the answer is yield to the block, otherwise the naswer is returned.
    def receive_raw_answer(options={})
      answer = connection{|c| c.waitfor(/./)}
      puts "Recv: #{answer}" if @debug
      if answer.nil?
        raise "Unknwon error occured. " +
          "Check the submitted query in detail:\n" +
          @last_message
      end
      while not answer =~ /\n/ do
        next_answer = connection{|c| c.waitfor(/./)}
        puts "Recv: #{next_answer}" if @debug
        if answer.nil?
          answer = next_answer
        else
          answer += next_answer
        end
      end
      # XXX ignore some potential asynchronous answers
      # XXX check if everything works ok
      #answer = answer.split("\n")[-1]
      answer = answer.sub(/(\d\d\d) (.*)/,"\\2")
      if($1.to_i == 200)
        if block_given?
          yield answer
        else
          return answer
        end
      else
        unless $2.nil?
          raise CycError.new($2.sub(/^"/,"").sub(/"$/,"") + "\n" + @last_message)
        else
          raise CycError.new("Unknown error! #{answer}")
        end
        nil
      end
    end


    def method_missing(name,*args,&block)
      @builder.reset
      @builder.send(name,*args,&block)
      talk(@builder.to_cyc)
    end
  end
end
