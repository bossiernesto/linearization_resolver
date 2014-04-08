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

module Kernel
  def from_ancestor(ancestor, &blk)
    @__from_ancestor ||= {}
    unless r = @__from_ancestor[ancestor]
      r = (@__from_ancestor[ancestor] = OverridenAncestor.new(self, ancestor))
    end
    r.instance_eval(&blk) if block_given?
    r
  end

  def resolve_linearization(method_sym)
    raise 'Method not implemented in ancestors' unless self.new.respond_to? method_sym
    method = self.new.method(method_sym)
    parameters = method.parameters
    LinearizerResolver.new method_sym, parameters, self
  end
end

class LinearizerResolver

  attr_accessor :method_name, :parameters, :methods_list, :klass

  def initialize(method_name, parameters, klass)
    self.method_name = method_name.is_a?(Symbol) ? method_name.to_s : method_name
    self.parameters = parameters
    self.klass = klass
    self.methods_list = []
    self
  end

  def add_method_to_list(method)
    self.methods_list << method
  end

  def method_from(ancestor, &blk)
    ancestor_overriden = self.klass.new.from_ancestor(ancestor)
    ancestor_method = ancestor_overriden.method_missing(self.method_name.to_sym)
    puts ancestor_method
    self.add_method_to_list ancestor_method
    self
  end

  def mix_them
    self.confirm
  end

  def confirm
    self.klass.class_eval %Q(
      @@methods_list = #{self.methods_list}
      define_method(#{self.method_name.to_sym}) { |*args|
        @@methods_list.each do |method|
          method.call *args
        end
      }
    )
  end
end

class OverridenAncestor
  private *instance_methods.select { |m| m !~ /(^__|^\W|^binding$)/ }

  def initialize(subject, ancestor)
    @subject = subject
    @ancestor = ancestor
  end

  def method_missing(sym)
    @ancestor.instance_method(sym).bind(@subject)
  end
end

class B1 < A
  include M2, M1
  resolve_linearization(:m).method_from(M2).method_from(M1).mix_them
end
