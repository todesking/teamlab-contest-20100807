require File.join(File.dirname(__FILE__),'extractor_def.rb')

title=''
content=ARGF.read

EXTRACTORS.each{|k,v|
  keywords=v.call(title,content)
  puts "============= #{k} =============="
  puts keywords.join(", ")
}
