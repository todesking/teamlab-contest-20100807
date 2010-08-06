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
    attr_accessor :surface          # 表層形
    attr_accessor :pos              # 品詞
    attr_accessor :cost             # 生起コスト
    attr_accessor :conjugation_form # 活用形
    attr_accessor :conjugation_type # 活用型
    attr_accessor :root             # 原形
    attr_accessor :reading          # 読み
    attr_accessor :pronounce        # 発音
    def initialize args
      return if args.nil?
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

    # てきとうにつなげる
    def merge(other,new_pos=@pos)
      t=Term.new(nil)
      t.surface=surface+other.surface
      t.pos=new_pos
      t.cost=cost
      t.root=root+other.root
      t.reading=reading+other.reading
      t.pronounce=pronounce+other.pronounce
      return t
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
