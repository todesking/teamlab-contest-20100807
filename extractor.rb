$KCODE='u'
require File.join(File.dirname(__FILE__),'extractor_def.rb')

title=$stdin.gets
content=$stdin.read

keywords=EXTRACTORS[$*[0].to_sym].call(title,content)
puts keywords.join(", ")
