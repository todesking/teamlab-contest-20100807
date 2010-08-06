require File.join(File.dirname(__FILE__),'rmecab.rb')
require 'jcode'

class MCValue
  def initialize
    @mecab=RMeCab.new("-x 未知語")
  end

  def extract(text)
    word_stream=stream_filter(@mecab.parse(text_filter(text))).
      map{|x|
        case
        when %w(名詞 未知語).include?(x.pos[0]) && !%w(非自立 代名詞).include?(x.pos[1])
          x
        when x.pos[1]=='アルファベット'
          x
        else
          nil
        end
      }.
      map{|x| x.nil? ? nil : x.surface}
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
      -mcvalue_of(collocations,c)
    }.map{|c|c.surface}
    return merge_simwords(sorted)[0,40]
  end

  def merge_simwords(sorted)
    result=[]
    sorted.each{|s|
      result.push(s) unless result.index{|r|r.index(s)}
    }
    return result
  end

  def mcvalue_of collocations,c
    if c.surface =~ /^.$|^[０-９]*$/
      return 0.0
    else
      weight=1.0
      reparsed=@mecab.parse(c.surface)
      if reparsed.length==1
        word=reparsed.first
        case
        when word.pos[1]=='固有名詞' || word.pos[0]=='未知語'
          weight=3.0
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
  -ー
  +＋
  ･・
  /／
  ,，
  .．
  %％
  |
  def text_filter(text)
    HAN2ZEN.each{|x|
      xx=x.split(//)
      text=text.gsub(xx[0],xx[1])
    }
    return text.tr('0-9a-zA-Z','０-９ａ-ｚＡ-Ｚ')
  end

  def number? s
    return !s.nil? && s.pos[0]=='名詞' && s.pos[1]=='数'
  end

  def stream_filter(stream)
    prev=nil
    result=[]
    join_to_next=false
    stream.each{|s|
      case
      when join_to_next
        join_to_next=false
        result.last.surface+='・'+s.surface
      when number?(s) && number?(prev)
        result.pop
        result.push prev.merge(s)
      when s.surface=='・'
        join_to_next=true
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
          break if words[i+j]!=other.words[j]
          j+=1
        end
        return true if j==ol
        i+=1
      end
      return false
    end

    def eql?(other)
      self.words.eql? other.words
    end

    def hash
      self.words.hash
    end

    def surface
      @words.join('')
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