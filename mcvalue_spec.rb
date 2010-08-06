require File.join(File.dirname(__FILE__),'mcvalue.rb')

def colloc(space_sepalated_words)
  MCValue::Collocation.new(space_sepalated_words.split(' '))
end

describe MCValue::Collocation do
  it '#contains' do
    colloc('a b c').should be_contains(colloc('a'))
    colloc('a b c').should_not be_contains(colloc('d'))
    colloc('a b c').should be_contains(colloc('a b c'))
    colloc('a b c').should_not be_contains(colloc('a b c d e f'))
  end
  it '#length' do
    colloc('a b').length.should == 2
    colloc('a').length.should == 1
  end
  it '#eql?' do
    colloc('a b').should be_eql(colloc('a b'))
    colloc('a b').should_not be_eql(colloc('a b c'))
  end
end

describe MCValue::Collocations do
  it '#summary_of' do
    cs=MCValue::Collocations.new
    cs.summary_of(colloc('a')).should == {:count=>0,:longer=>0,:longer_unique=>0}
    cs.add colloc('a')
    cs.summary_of(colloc('a')).should == {:count=>1,:longer=>0,:longer_unique=>0}
    cs.add colloc('a b')
    cs.summary_of(colloc('a')).should == {:count=>1,:longer=>1,:longer_unique=>1}
    cs.add colloc('a b')
    cs.summary_of(colloc('a')).should == {:count=>1,:longer=>2,:longer_unique=>1}
    cs.add colloc('x a')
    cs.summary_of(colloc('a')).should == {:count=>1,:longer=>3,:longer_unique=>2}
  end
end
