require 'rubygems'
require 'uri'
require 'net/http'
require 'nokogiri'

class YahooKeyphraseAPI
  def initialize(appid)
    @appid=appid
  end
  def extract(text)
    resp=request(API_URI,{:appid=>@appid,:sentence=>text})
    doc=Nokogiri(resp)
    result=[]
    (doc/'Result').each{|r|
      result.push({
        :keyphrase=>(r/'Keyphrase').first.text ,
        :score=>(r/'Score').first.text.to_f
      })
    }
    return result
  end
  API_URI=URI.parse 'http://jlp.yahooapis.jp/KeyphraseService/V1/extract'

  private

  def request(uri,params)
    res=Net::HTTP.post_form(uri,params)
    if res.code != '200'
      puts res
      raise 'error!!!'
    end
    return res.body
  end

end
