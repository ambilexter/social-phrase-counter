require 'rubygems'
require 'minitest/autorun'
require 'phrase-analysis/word-counter.rb'

class TestCounter < MiniTest::Test

  def test_count_some_words 
    @counter.count_some_words(@test_array, 2) 
    assert_equal({ 2 => @expected_full_output[2] }, @counter.phrases)
  end

  def test_count_words
    @counter.count_words(@test_phrase)
    assert_equal @expected_full_output, @counter.phrases
  end 

  def test_by_count

    @counter.count_words(@test_phrase_short)
    bc = @counter.by_count
    assert_includes bc[1], "one two"
    
  end

  def setup
    @counter = PhraseAnalyst::WordCounter.new

    @test_phrase_short = <<EOS
one two three
EOS

    @test_array_short = [ "one", "two", "three" ]

    @expected_short_output =
      { 2 => { "one two" => 1, "two three" => 1 },
      3 => {"one two three" => 1 } }
 
    # now that this is HoA the order of phrases matters?
#    @expected_short_by_count_output = 
#      { 1 => ["one two" , "two three", "one two three"] }

    @test_phrase = <<EOS
I told my wrath my wrath did end
EOS
    @test_array = [ "I", "told", "my", "wrath", "my", "wrath", "did", "end" ]

    @expected_full_output=
      { 2 => { "i told" => 1, "told my" => 1, "my wrath" => 2, 
        "wrath my" => 1, "wrath did" => 1, "did end" => 1 },
      3 =>  { "i told my" => 1, "told my wrath" => 1, "my wrath my" => 1, 
        "wrath my wrath" => 1, "my wrath did" => 1, "wrath did end" => 1}, 
      4 =>  { "i told my wrath" => 1, "told my wrath my" => 1, 
        "my wrath my wrath" => 1, "wrath my wrath did" => 1,
        "my wrath did end" => 1 },
      5 =>  { "i told my wrath my" => 1, "told my wrath my wrath" => 1,
        "my wrath my wrath did" => 1, "wrath my wrath did end" => 1 },
      6 =>  { "i told my wrath my wrath" => 1, 
        "told my wrath my wrath did" => 1,
        "my wrath my wrath did end" => 1 }, 
      7 =>  { "i told my wrath my wrath did" => 1, 
        "told my wrath my wrath did end" => 1 },
      8 => { "i told my wrath my wrath did end" => 1}
    }
    end
end # class

module PhraseAnalyst
  class WordCounter
    attr_reader :phrases_by_count
    end
end


# counter.count_words( <<EOS
# I was angry with my friend,
# I told my wrath my wrath did end
# I was angry with my foe:
# I told it not, my wrath did grow:
# EOS
# )

#



# long quote is long.
# expected_output = { 2 => 
#  "i was" => 2, "was angry" => 2, "angry with" => 2, 
#  "with my" => 2, "my friend," => 1, "i told" => 2, "told my" => 1,
#  "my wrath" => 3, "wrath my" => 1, "friend, i" => 1, 
#  "wrath did" => 2, "did end" => 2, "my foe:" => 1, "foe: i" => 1,
#  "told it" => 1, "not, my" => 1, "did grow:"
  



