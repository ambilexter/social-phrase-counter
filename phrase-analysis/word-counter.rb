
module PhraseAnalyst
  class WordCounter

    attr_reader :phrases

    def initialize

      @phrases = Hash.new { |h,k| h[k] = Hash.new(0) }

      @phrases_by_count = Hash.new { |k, v| k[v] = [] }

      # consider including various forms of 'to be'. or not.
#      @stopwords = [ "a", "an", "and", "as", "for", 
#                     "it", "of", "or", "the", "to"]
	@stopwords =[]
    end
        
    # the count_* routines have no useful return values -- they're called
    # over and over again, and results collected in @phrases over time.

    def count_words text
      words = text.split(/\s+/) # this is still insufficiently smart

      # if this is directed at somebody, don't phrasify that part
      while words[0] =~ /^@/
       	words.shift
      end

      (2..words.length).to_a.reverse.each do |howmany| 
        count_some_words(words, howmany) 
      end
      return @phrases
    end # counted

    def count_some_words words, some
      words.each_index do |i|
        unless i >= words.length-(some-1) or stop_word?(words[i])  #ugh

          phrase = words[i...i+some].join(" ")
          phrase.downcase!
          
          @phrases[some][phrase] += 1

        end # don't go off the end
      end
    end # count_some_words

    # this recalcs every time it's called
    def by_count
      @phrases.each do |length, pairs|
        pairs.each do |phrase,count|
          @phrases_by_count[count] << phrase
        end
      end
      
      return @phrases_by_count
    end
    
    def stop_word? word
      @stopwords.include?(word)
    end 

  end # class
end # module
