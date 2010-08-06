require 'rubygems'
require 'pit'
require File.join(File.dirname(__FILE__),'yahoo_keyphrase.rb')

content=ARGF.read

extractors={
  :yahoo_keyphrase => lambda {|text|
    YahooKeyphraseAPI.new(Pit.get('yahoo')['appid']).
      extract(text).
      sort_by{|x|-x[:score]}.
      map{|x| x[:keyphrase] }
  },
}

extractors.each{|k,v|
  keywords=v.call(content)
  puts "engine: #{k}"
  puts "keywords: "
  puts "    "+keywords.join(", ")
}
