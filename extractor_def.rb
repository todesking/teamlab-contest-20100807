$KCODE='u'
require 'rubygems'
require 'pit'
require 'digest/sha1'
require File.join(File.dirname(__FILE__),'yahoo_keyphrase.rb')
require File.join(File.dirname(__FILE__),'mcvalue.rb')

CACHE_DIR=File.join(File.dirname(__FILE__),'cache')

EXTRACTORS={
  :yahoo_keyphrase => lambda {|title,text|
    hash=Digest::SHA1.hexdigest(title+text)
    cache_path=File.join(CACHE_DIR,'yahoo',hash)
    if File.exists? cache_path
      return open(cache_path){|f|Marshal.load(f)}
    end
    result=YahooKeyphraseAPI.new(Pit.get('yahoo',:require=>{'appid'=>'appid'})['appid']).
      extract(title+text).
      sort_by{|x|-x[:score]}.
      map{|x| x[:keyphrase] }
    open(cache_path,'w'){|f| Marshal.dump(result,f) }
    return result
  },
  :mc_value => lambda {|title,text|
    return MCValue.new.extract(title,text)
  }
}
