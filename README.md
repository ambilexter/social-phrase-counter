social-phrase-counter
=====================
Given a text input (currently, the last 1500 results for a twitter search) show phrases 
that are being used over and over. This can be useful for detecting ad campaigns, 
botnets, and artificially constructed social movements (astroturf).

Requires a twitter application consumer key and secret (see http://apps.twitter.com).

To use, create keys.local.rb (see keys.rb) and edit config.rb, then run 'target-phrases'. 
Phrase analysis will show up on stdout. Twitter search results (for sanity-checking)
will be written to current directory.

