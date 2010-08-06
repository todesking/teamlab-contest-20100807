require File.join(File.dirname(__FILE__),'rmecab.rb')
require 'set'

class MCValue
  def initialize
    @mecab=RMeCab.new("-x 未知語")
  end

  def extract(text)
    # TODO: dummy
    word_stream=@mecab.
      parse(text).
      map{|x|
        if x.pos[0] == '名詞'
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
    collocations.unique_collocations.sort_by{|c|
      -mcvalue_of(collocations,c)
    }.map{|c|c.surface}[0,20]
  end

  def mcvalue_of collocations,c
    summary=collocations.summary_of(c)
    c.length*(summary[:count] - summary[:longer]/[summary[:longer_unique],1].max)
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
