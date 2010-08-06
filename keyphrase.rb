require 'rubygems'
require 'pit'
require 'digest/sha1'
require File.join(File.dirname(__FILE__),'yahoo_keyphrase.rb')
require File.join(File.dirname(__FILE__),'mcvalue.rb')

CACHE_DIR=File.join(File.dirname(__FILE__),'cache')

content=ARGF.read

extractors={
  :yahoo_keyphrase => lambda {|text|
    hash=Digest::SHA1.hexdigest(text)
    cache_path=File.join(CACHE_DIR,'yahoo',hash)
    if File.exists? cache_path
      return open(cache_path){|f|Marshal.load(f)}
    end
    result=YahooKeyphraseAPI.new(Pit.get('yahoo')['appid']).
      extract(text).
      sort_by{|x|-x[:score]}.
      map{|x| x[:keyphrase] }
    open(cache_path,'w'){|f| Marshal.dump(result,f) }
    return result
  },
  :mc_value => lambda {|text|
    return MCValue.new.extract(text)
  }
}

extractors.each{|k,v|
  keywords=v.call(content)
  puts "============= #{k} =============="
  puts keywords.join(", ")
}
