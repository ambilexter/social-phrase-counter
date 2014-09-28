# or is it the container for the enumerable? given data and a category, store 
# the data in that category. (does it really do anything else?)
# make the categories easily extensible.  Eventually, maybe, let the 
# categories be user-defined?
# like, create no lists first, and when the first one comes in, pick the 
# right thing and instantiate it then.


module PhraseAnalyst
  class AnalystData

    def initialize
      @compiled_text=[] # curated data
      @full_results=[] # total search results
      @uncounted_data=[] # unused yet

    end # initialize

    attr_accessor :compiled_text, :full_results, :uncounted_data

  end # class
end # module
