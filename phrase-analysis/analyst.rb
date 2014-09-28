require 'social-phrase-counter/phrase-analysis/analyst-data.rb'
require 'social-phrase-counter/phrase-analysis/word-counter.rb'
require 'social-phrase-counter/phrase-analysis/search-twitter.rb'

module PhraseAnalyst
  class Analyst

    def initialize term, search_config, flags

      @source = SearchTwitter.new(flags[:source], flags[:method], search_config)
      
      @word_counter = WordCounter.new

      @supporting_data = AnalystData.new()

      $stderr.puts "initialization complete."

    end # initialize()

    def run

      $stderr.print "Results for #{term}...\n"

      # entries should work. would reverse_each{|item| block} be more fun?
      @source.get_results.entries.reverse.each do |chunk|
        log_search_results chunk
        
        case @source.categorize_this chunk
          when :count then count chunk
          when :nocount then mark_uncounted chunk
        end
        
      end # each chunk
      
      save_tempfiles @source.compile(@supporting_data.full_results,""), @source.compile(@supporting_data.compiled_text, "Counted: ")

      puts pretty_print @word_counter.phrases

      return @word_counter.phrases

    end # run()


    def log_search_results data
      @supporting_data.full_results << data
    end


    def count data

      @word_counter.count_words data.text

      @supporting_data.compiled_text << data

    end # count

    # placeholder
    def mark_uncounted data
      @supporting_data.uncounted_data << data
    end

    def pretty_print data

      flat_data = {}
      phrases_by_count = @word_counter.by_count
      suppress_display = {}

      inner = 0
      outer = 0
      
      $stderr.puts "Flattening and de-duping..."
      data.sort_by {|k, v| k}.reverse.each do |length, phrases|
        phrases.each do |phrase,count|
          outer += 1
          flat_data[phrase] = count
          next if count==1 or suppress_display[phrase] == :yes

          phrases_by_count[count].each do |test_phrase|
            inner += 1
            suppress_display[test_phrase] = :yes if (phrase[test_phrase] and phrase != test_phrase)
          end # all the phrases with this count examined for de-duping          

        end # all the phrases
      end # all the lengths


      result= "\n\n ----------------\n\n"      
      seen = 0
      $stderr.puts "preparing output..."
      flat_data.sort_by {|k, v| v}.reverse.each do |phrase, count|
        break unless stop_reporting(count, seen) == :keep_going
        next if suppress_display[phrase] == :yes

        result <<  "#{phrase}: #{count}\n"

        (3...count).to_a.reverse.each do |more|
          phrases_by_count[more].each do |test_phrase|
            # need a custom-matching function, that only works on whole words
            # so "me food" doesn't match "some food and"
            if test_phrase[phrase] and not suppress_display[test_phrase]
              result << "     #{test_phrase}: #{more}\n" 
              suppress_display[test_phrase] = :yes
            end
          end
        end

        seen += 1
      end

      return result
    end # pretty print


    def stop_reporting count_data, result_quantity
      # the more data we have, the less interesting smaller data is.
      return :stop if count_data == 2 unless result_quantity < 16
      return :stop if count_data == 1

      return :keep_going
    end

    def old_pretty_print data, supplemental_data
      result=""
      count=0
      
      puts "\n\n ----------------\n\n"
      data.sort_by {|k, v| v}.reverse.each do |pair|
        break unless stop_reporting(pair[1], count) == :keep_going
        
        # otherwise ...
        count +=1
        
        result << pair[0].to_s + ": " + pair[1].to_s + "\n"
        
        supplemental_data.sort_by {|k, v| v}.reverse.each do |sub_pair|
          result << "       " + sub_pair[0].to_s + ": " + sub_pair[1].to_s + "\n" if (sub_pair[0].to_s[pair[0].to_s] and sub_pair[1] > (pair[1]/3) and pair[1]>2)
        end 
      end #
      
      return result
    end # old pretty print
    
    
    # 'tempfiles' because they're overwritten each run
    def save_tempfiles raw_data, curated_data

      File.open("raw-source-tweets","w") do |tf|
        raw_data.split(/\n/).each do  |line| 
          tf.puts line
        end
      end

      File.open("uniq-source-tweets","w") do |tf|
        curated_data.split(/\n/).each do  |line| 
          tf.puts line
        end
      end
      
    end  #save tempfiles


  end # Class PhraseAnalyst
end # Module




