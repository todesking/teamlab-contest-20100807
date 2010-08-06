require 'MeCab'

class RMeCab
  def initialize(option='')
    @tagger=MeCab::Tagger.new(option)
  end
  def parse(str,option='')
    n=@tagger.parseToNode(str)
    result=[]
    while n
      term=Term.new(:surface=>n.surface,:feature=>n.feature,:cost=>n.cost)
      result.push term unless term.pos.beos?
      n=n.next
    end
    return result
  end

  class Term
    attr_reader :surface          # 表層形
    attr_reader :pos              # 品詞
    attr_reader :cost             # 生起コスト
    attr_reader :conjugation_form # 活用形
    attr_reader :conjugation_type # 活用型
    attr_reader :root             # 原形
    attr_reader :reading          # 読み
    attr_reader :pronounce        # 発音
    def initialize args
      @surface=args[:surface]
      @cost=args[:cost]
      features=args[:feature].split(',')
      @pos=POS.new(features[0..3])
      @conjugation_form=features[4]
      @conjugation_type=features[5]
      @root=features[6]
      @reading=features[7]
      @pronounce=features[8]
    end
    def to_s
      "#{@surface}(#{@pos})"
    end
  end

  class POS
    def initialize(array)
      @data=array
    end
    def [](n)
      return @data[n] ? @data[n] : '*'
    end
    def length
      return @data.length
    end
    def to_s
      @data.join('-')
    end
    def beos?
      @data.first == 'BOS/EOS'
    end
  end
end
