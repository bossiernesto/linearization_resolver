require 'rspec'
require_relative 'resolver'

module M1

  def m
    'module 1'
  end
end

module M2
  def m
    'module 2'
  end
end

class A
  def m
    'bleh'
  end
end

class B < A
  include M2, M1
  #will get m from M2 as it's the nearest ancestor
end

describe 'test from_ancestor modules' do

  it 'get module 2' do
    B.new.m.should == 'module 2'
  end

  it 'get m from B1' do
    b= B.new
    b.from_ancestor(eval(:M1.to_s.capitalize)).m.call.should == 'module 1'
  end

  it 'get m from B2' do
    b= B.new
    b.from_ancestor(A).m.call.should == 'bleh'
  end

end

class B1 < A
  include M2, M1
  resolve_linearization(:m).method_from(M2).method_from(M1).mix_them
end

#inverted linearization and thus ancestor and method lookup hierarchy, but same resolve_linearization compared to B1
class B2 < A
  include M1, M2
  resolve_linearization(:m).method_from(M2).method_from(M1).mix_them
end

#inverted both linearization and resolve_linearization comparing to B1
class B3 < A
  include M1, M2
  resolve_linearization(:m).method_from(M1).method_from(M2).mix_them
end

class B4 < B3
  resolve_linearization(:m).method_from(M2).method_from(M1).mix_them
end

describe 'test resolver of linearization' do

  before(:each) do
    @b1 = B1.new
    @b2 = B2.new
    @b3 = B3.new
  end

  it 'test normal redefinement of linearization' do
    @b1.m.should == 'module 1'
  end

  it 'inverted resolve_linearization from normal include of the modules' do
    @b2.m.should == 'module 1'
  end

  it 'inverted linearization compared to B1 and used same order for resolve_linearization.' do
    @b3.m.should == 'module 2'
  end

  it 'inherited from B3 and changed resolve linearization' do
    B4.new.m.should == 'module 1'
  end


end
