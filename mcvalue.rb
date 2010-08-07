require File.join(File.dirname(__FILE__),'rmecab.rb')
require 'jcode'

class MCValue
  def initialize
    @mecab=RMeCab.new("-x 未知語")
  end

  def extract(title,text)
    normalized_title=text_filter(title)
    word_stream=stream_filter(@mecab.parse(text_filter(title+'　'+text))).
      map{|x|
        case
        when %w(名詞 未知語 動詞).include?(x.pos[0]) && !%w(非自立 代名詞).include?(x.pos[1])
          x
        when x.pos[1]=='アルファベット'
          x
        when x.pos[1]=='名詞接続'
          x
        else
          nil
        end
      }
    buf=[]
    collocations=Collocations.new
    word_stream.each{|w|
      if w.nil?
        collocations.add_all make_possible_collocations(buf)
        buf=[]
      else
        buf.push w
      end
    }
    collocations.add_all make_possible_collocations(buf)
    puts "possible collocations: #{collocations.unique_collocations.size}"
    sorted=collocations.unique_collocations.sort_by{|c|
      score=-mcvalue_of(collocations,c)
      score*=2 if normalized_title.index(c.surface)
      score-=c.surface.jlength*0.1
      score
    }.map{|c|c.surface}
    return merge_simwords(sorted)[0,40]
  end

  def merge_simwords(sorted)
    result=[]
    sorted.each{|s|
      result.push(s) unless result.index{|r|r.index(s)||s.index(r)}
    }
    return result
  end

  def mcvalue_of collocations,c
    if c.surface =~ /^(.|[０-９]{1,5}|[Ａ-Ｚａ-ｚ０-９]{0,2})$/
      return 0.0
    else
      weight=1.0
      if c.surface =~ /・/
        weight=1+c.surface.jcount('・')
      end
      reparsed=@mecab.parse(c.surface)
      if reparsed.length==1
        word=reparsed.first
        case
        when word.surface =~ /^[Ａ-Ｚａ-ｚ０-９]{0,2}$/
          weight=0.0
        when word.pos[0]=='未知語' && word.surface.jlength<3
          weight=0.0
        when word.pos[1]=='固有名詞'
          weight=3.0
        when word.pos[0]=='未知語'
          weight=5.0
        when %w(接尾).include?(word.pos[1])
          weight=0.0
        end
      end
      return 0.0 if weight==0.0
      summary=collocations.summary_of(c)
      return 0.0 if summary[:count] < 2
      return weight*c.length*(summary[:count] - summary[:longer].to_f/[summary[:longer_unique],1].max)
    end
  end

  def make_possible_collocations words
    result=[]
    (1..words.length).each{|size|
      (0..(words.length-size)).each{|i|
        result.push Collocation.new(words[i,size])
      }
    }
    return result
  end

  HAN2ZEN=%w|
  (（
  )）
  [［
  ]］
  !！
  @＠
  $＄
  :：
  -‐
  +＋
  ･・
  /／
  ,，
  .．
  %％
  "”
  |
  def text_filter(text)
    HAN2ZEN.each{|x|
      xx=x.split(//)
      text=text.gsub(xx[0],'　')
      text=text.gsub(xx[1],'　')
    }
    return text.tr('0-9a-zA-Z','０-９ａ-ｚＡ-Ｚ')
  end

  def number? s
    return !s.nil? && s.pos[0]=='名詞' && s.pos[1]=='数'
  end

  def stream_filter(stream)
    prev=nil
    result=[]
    stream.each{|s|
      case
      when number?(s) && number?(prev)
        result.pop
        result.push prev.merge(s)
      when s.surface=='・'
      else
        result.push s
      end
      prev=result.last
    }
    return result
  end

  class Collocation
    def initialize(words)
      @words=words
      @length=words.length
    end

    attr_reader :words
    attr_reader :length

    def contains?(other)
      sl=self.length
      ol=other.length
      return false if sl<ol
      i=0
      while i<=(sl-ol)
        j=0
        while j<ol
          break if words[i+j].surface!=other.words[j].surface
          j+=1
        end
        return true if j==ol
        i+=1
      end
      return false
    end

    def eql?(other)
      return false if length!=other.length
      i=0
      l=length
      while i<l
        return false if words[i].surface != other.words[i].surface
        i+=1
      end
      return true
    end

    def hash
      self.words.hash
    end

    def surface
      @words.map(&:surface).join('')
    end

    def avg_cost
      @words.map(&:cost).inject(0.0){|a,x|a+x}/length
    end
  end

  class Collocations
    def initialize
      @collocs={}
    end

    def add_all collocations
      collocations.each{|c| add c}
    end

    def add collocation
      if @collocs.has_key? collocation
        @collocs[collocation]+=1
      else
        @collocs[collocation]=1
      end

    end

    def summary_of colloc
      longer=0
      longer_unique=0
      @collocs.each{|c,count|
        if colloc.length < c.length && c.contains?(colloc)
          longer+=count
          longer_unique+=1
        end
      }
      return {
        :count=>@collocs[colloc] || 0,
        :longer=>longer,
        :longer_unique=>longer_unique
      }
    end

    def unique_collocations
      @collocs.keys
    end
  end
end
