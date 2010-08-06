$KCODE='u'
require 'rubygems'
require 'open-uri'
require 'nokogiri'

unless $*.length==2
  puts <<EOS
USAGE: #$0 dir keyword
  get wikipedia content and save to {dir}/{keyword}.txt
EOS
  exit 1
end

dir=$*[0]
keyword=$*[1]

BASE_URI='http://ja.wikipedia.org/wiki/'
uri=BASE_URI+URI.escape(keyword)
puts "opening #{uri}"
raw_content=open(uri){|f|f.read}
doc=Nokogiri(raw_content)
body=doc/"div[@id='bodyContent']"

open(File.join(dir,keyword+'.txt'),'w'){|f|
  (body/"p").each{|elm|
    f.puts elm.text
  }
}
puts "done"

