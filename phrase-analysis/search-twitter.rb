module PhraseAnalyst
  class SearchTwitter

    def initialize source, method, search_config

      case source
      when :json
        fail "NYI"
      else  # defaults to :twitter
        @twitter_client = create_authed_client
      end # source chosen

      case method
      when :realtime
        alias :get_results :get_results_realtime
      else
        alias :get_results :get_results_historical
      end

      @search_arguments = search_config

      @my_flags = {}
      @my_flags[:total] = 1500 or search_config[:count]

      
      # internal state-keeping for counting
      @seen_text= Hash.new{|h,k| h[k] = []}
      # @seen_ids={0} # why doesn't this work?
      @seen_ids = Hash.new(0)


    end

    def create_authed_client
      require './keys' # personal developer access lives in a separate file

      begin
        $stderr.print "Authenticating..."
        client = Twitter::REST::Client.new do |config|
          config.consumer_key,  
          config.consumer_secret,
          config.bearer_token = get_my_keys

          # wrap this in an error handler; 
          # if there's no userkeys specified in keys.local.rb it'll still work
          # user authenticaiton gets you rate-limited later, I think?
          config.access_token, config.access_token_secret = get_user_keys
        end
      rescue StandardError => ex
        $stderr.puts "Client creation failed, now what?"
        $stderr.puts ex.inspect
        $stderr.puts ex.message
      end
      $stderr.puts "done."

      return client
    end

    def get_results_realtime
      fail "NYI"
    end

    def get_results_historical
      # eventually, trap errors here.
      # for example, the json-parsing bit of the faraday middleware will 
      # throw an ArgumentError if the request fails w/empty results
      @cached_results = 
        @twitter_client.search(term, @search_arguments).take(@my_flags[:total])
       return @cached_results
    end


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
