require 'rspec'
require_relative 'a'

describe 'test from_ancestor modules' do

  it 'get module 2' do
    B.new.m.should == 'module 2'
  end

  it 'get m from B1' do
    b= B.new
    puts b.from_ancestor(M1).m.call.should == 'module 1'
  end

  it 'get m from B2' do
    b= B.new
    puts b.from_ancestor(A).m.call.should == 'bleh'
  end

end

describe 'test resolver of linearization' do

  it 'test redefinement of methods' do
    1.should == 2
  end


end
