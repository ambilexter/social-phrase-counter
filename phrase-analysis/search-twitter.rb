module PhraseAnalyst
  class SearchTwitter

    def initialize source, method, search_config

      case method
      when :realtime
        alias :get_results :get_results_realtime
        @client_type = "Streaming"
      else
        alias :get_results :get_results_historical
        @client_type = "REST"
      end

      case source
      when :json
        fail "NYI"
      else  # defaults to :twitter
        @twitter_client = create_authed_client
      end # source chosen

      @search_arguments = search_config

      @my_flags = {}
      @my_flags[:total] = search_config[:count] or 1500
      
      # internal state-keeping for counting
      @seen_text= Hash.new{|h,k| h[k] = []}
      # @seen_ids={0} # why doesn't this work?
      @seen_ids = Hash.new(0)

    end


    def create_authed_client
      require './keys' # personal developer access lives in a separate file

      begin
        $stderr.print "Authenticating..."
        consumer_key, consumer_secret, bearer_token = get_my_keys

        # wrap this in an error handler; 
        # if there's no userkeys specified in keys.local.rb historic 
        # will still work but streaming will not. Also, rate limits differ?
        access_token, access_token_secret = get_user_keys

        client = eval("Twitter::#{@client_type}::Client").new do |config|
          config.consumer_key = consumer_key  
          config.consumer_secret = consumer_secret
          config.bearer_token = bearer_token if @client_type == :historic
          config.access_token = access_token
          config.access_token_secret = access_token_secret
        end
      rescue StandardError => ex
        $stderr.puts "Client creation failed, now what?"
        $stderr.puts ex.inspect
        $stderr.puts ex.message
	exit
      end
      $stderr.puts "done."
      
      return client
    end
    
    def get_results_realtime
      @cached_results=[]
      
      begin
        @twitter_client.filter(:track => term) do |object|
          case object
          when Twitter::Streaming::StallWarning
            warn "stream stalled?"
            break
          when Twitter::Tweet
            @cached_results.unshift(object)
            warn "found " << @cached_results.length.to_s if @cached_results.length % 25 == 0
            break if @cached_results.length > @my_flags[:total]
          else 
            warn "stream returned: " << object.inspect
          end
        end # stream

      rescue Twitter::Error::Unauthorized => ex
        puts "Is the system clock correct?" if 
          /Timestamp out of bounds/.match(ex.message)
        fail ex.message
      end

      return @cached_results
    end # get_results_realtime
    
    def get_results_historical
      # eventually, trap more errors here.
      # for example, the json-parsing bit of the faraday middleware will 
      # throw an ArgumentError if the request fails w/empty results
      # the REST client will throw
      # Rate limit exceeded (Twitter::Error::TooManyRequests)

      begin
        @cached_results = 
          @twitter_client.search(term, @search_arguments).take(@my_flags[:total])

        @search_arguments[:max_id] =  (@cached_results.last.id - 1).to_s
        @cached_results += 
          @twitter_client.search(term, @search_arguments).take(@my_flags[:total])

      rescue Twitter::Error::TooManyRequests => ex
        warn "Rate limit exceeded!"
        @client_type = "Streaming"
        return create_authed_client.get_results_realtime
      end

      return @cached_results
    end

    def back_even_further
      @search_arguments[:max_id] =  (@last_results.last.id - 1).to_s unless @last_results.eql?(nil)
      return @last_results = @twitter_client.search(term, @search_arguments).take(@my_flags[:total])
      warn "search further back complete"
    end # back_even_further

    def categorize_this tweet
      if tweet.text =~ /^RT @/

        return :nocount unless @seen_text[tweet.text] == [] or @seen_text[tweet.text] == nil

        @seen_text[tweet.text] << tweet.id # this is currrently only storing counted IDs, is that a problem?
        return :count

      else
        return :nocount unless @seen_ids[tweet.id] == 0

        @seen_ids[tweet.id] += 1
        return :count

      end
    end #categorized


    def compile(list, tag)
      warn tag << " " << list.length.to_s
      result=""
      list.each do |tweet|
        result += tag + 
          tweet.id.to_s + "\n" +
          tweet.user.screen_name.to_s + " " +
          tweet.created_at.to_s + "\n" + 
          tweet.full_text + "\n" + 
          'retweet? ' + tweet.retweet?.to_s +
          "\n-------------------\n"
      end # each tweet

      return result
    end # compile


  end # class
end # module
