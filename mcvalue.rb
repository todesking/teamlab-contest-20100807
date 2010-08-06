require File.join(File.dirname(__FILE__),'rmecab.rb')

class MCValue
  def initialize
    @mecab=RMeCab.new("-x 未知語")
  end
  def extract(text)
    # TODO: dummy
    @mecab.
      parse(text).
      map{|x|
        if x.pos[0] == '名詞'
          x
        else
          nil
        end
      }.
      select{|x| x!=nil}.
      map{|x| x.surface}[0..20]
  end
end
