require 'social-phrase-counter/phrase-analysis/analyst-data.rb'
require 'social-phrase-counter/phrase-analysis/word-counter.rb'
require 'social-phrase-counter/phrase-analysis/search-twitter.rb'

module PhraseAnalyst
  class Analyst

    def initialize term, search_config, flags

      @at_least_this_many = 16
      @sub_list_max = 7
      @sub_list_min_count = 5

      @total_counted_chunks = 0
      @suppress_display = {}

      @source = SearchTwitter.new(flags[:source], flags[:method], search_config)
      @word_counter = WordCounter.new
      @supporting_data = AnalystData.new()

      warn "initialization complete."

    end # initialize()
    
    def run

      warn "Results for #{term}..."
      case flags[:threaded]
      when :yes
        flags[:goback] ||= 5
        run_threaded(flags[:goback])
      else
        run_not_threaded
      end

      @total_counted_chunks = @supporting_data.compiled_text.length
      
      save_tempfiles @source.compile(@supporting_data.full_results,""), @source.compile(@supporting_data.compiled_text, "Counted: ")

      puts pretty_print @word_counter.phrases

      return @word_counter.phrases
    end

    def run_threaded iterations_back

      current_results = @source.back_even_further
      next_results = current_results

      iterations_back.times do 
        request = Thread.new { next_results = @source.back_even_further }
        data = Thread.new { iterate_over(current_results) }
        
        data.join
        request.join

        current_results = next_results
      end
    end # run_threaded

    def run_not_threaded
      results = @source.get_results
      iterate_over(results)
    end 

    def iterate_over results
      
      results.entries.reverse.each do |chunk|
        log_search_results chunk
        
        case @source.categorize_this chunk
        when :count then count chunk
        when :nocount then mark_uncounted chunk
        end
        
      end # each chunk
    end

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

      $stderr.puts "Flattening and de-duping..."
      data.sort_by {|k, v| k}.reverse.each do |length, phrases|
        phrases.each do |phrase,count|

          flat_data[phrase] = count
          next if count==1 or @suppress_display[phrase] == :yes

          phrases_by_count[count].each do |test_phrase|

            @suppress_display[test_phrase] = :yes if (phrase[test_phrase] and phrase != test_phrase)
          end # all the phrases with this count examined for de-duping          

        end # all the phrases
      end # all the lengths


      result= "\n\n ----------------\n\n"      
      seen = 0
      biggest = 0
      $stderr.puts "preparing output..."
      flat_data.sort_by {|k, v| v}.reverse.each do |phrase, count|
        biggest = count if count > biggest
        break unless stop_reporting(count, seen, biggest) == :keep_going
        next if @suppress_display[phrase] == :yes

        result <<  "#{phrase}: #{count}\n"
        result << sub_phrases(phrase, count, phrases_by_count) if count > @sub_list_min_count

        seen += 1
      end # each phrase (left-justified)

      return result
    end # pretty print

    def sub_phrases phrase, count, phrases_by_count
      sub_list_count=0
      result = ""

      (@sub_list_min_count...count).to_a.reverse.each do |more|

        phrases_by_count[more].each do |test_phrase|
          # need a custom-matching function, that only works on whole words
          # so "me food" doesn't match "some food and"
          if test_phrase[phrase] and not @suppress_display[test_phrase]
            result << "     #{test_phrase}: #{more}\n" 
            @suppress_display[test_phrase] = :yes
            sub_list_count += 1
          end # matches, not suppressed

          return result if sub_list_count > @sub_list_max

        end # each phrase (indented)
      end # each count

      return result
    end # sub_phrases


    def stop_reporting count_data, result_quantity, biggest

      # the more data we have, the less interesting smaller data is.
      return :stop if count_data == 2

      return :stop if result_quantity > @at_least_this_many and 
        (count_data < biggest/20 or result_quantity > @total_counted_chunks/20)
      
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




