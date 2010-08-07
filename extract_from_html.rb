$KCODE='u'

require File.join(File.dirname(__FILE__),'ext','extractcontent.rb')

raw_content=ARGF.read

body,title=ExtractContent.analyse(raw_content)

puts title
puts body
