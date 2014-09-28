# "term" is required, otherwise it doesn't do anything

def term
  return "searchterm"
end

# flags for analyst
def flags 
  return {
    :source => :twitter, # defaults to :twitter
    :method => :historic # defaults to historic
  }
end

# config options (see http://rdoc.info/gems/twitter/Twitter/REST/Search)

def config  
  return { 
    :count => 1500, 
  :result_type => "recent",
#  :until => "2000-01-01", # YYYY-MM-DD, but twitter's index only goes back ~7d

#  :count => 100, # tweets returned per page
#  :geocode =>  # latitude, longitude, radius
#  :lang =>  # ISO 639-1 code
#  :since_id => , # tweet id
#  :max_id => # tweet id
  }
end
