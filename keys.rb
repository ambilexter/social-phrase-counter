def get_my_keys
  my_api_key = ""
  my_api_secret = ""
  bearer_token=""

  return my_api_key,my_api_secret, bearer_token
end

def get_user_keys
  my_user_key=""
  my_user_secret=""

  return my_user_key, my_user_secret
end


#### needs fix: keys should live in the user's homedir
begin
  require_relative 'keys.local.rb' 
rescue LoadError => ex

  puts %{
---------------
create keys.local.rb
it should have get_my_keys (and optionally get_user_keys), 
only with your data filled in
---------------
}
end



