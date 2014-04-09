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
    parameters = self.new.method(method_sym).parameters
    LinearizerResolver.new method_sym, parameters, self
  end
end

class LinearizerResolver

  attr_accessor :method_name, :parameters, :ancestor_list, :klass, :overriden_ancestor

  def initialize(method_name, parameters, klass)
    self.method_name = method_name.is_a?(Symbol) ? method_name.to_s : method_name
    self.parameters = parameters
    self.klass = klass
    self
  end

  def overriden_ancestor
    @overriden_ancestor = @overriden_ancestor || []
  end

  def ancestor_list
    @ancestor_list = @ancestor_list || []
  end

  def add_method_to_list(ancestor)
    self.ancestor_list << ancestor
  end

  def method_from(ancestor, &blk)
    self.overriden_ancestor << self.klass.new.from_ancestor(ancestor)
    self.ancestor_list << ancestor.to_s
    self
  end

  def mix_them
    self.confirm
  end

  def confirm
    self.klass.class_eval %Q{
    attr_accessor :ancestor_list

    def #{self.method_name}(*args)
      result = nil
      self.ancestor_list = #{self.ancestor_list}
      self.ancestor_list.each do |ancestor|
       result= self.from_ancestor(eval(ancestor.capitalize)).#{self.method_name}.call *args
      end
      result
    end
    }
  end
end

class OverridenAncestor
  private *instance_methods.select { |m| m !~ /(^__|^\W|^binding$)/ }

  def initialize(subject, ancestor)
    @subject = subject
    @ancestor = ancestor
    @ancestor_method = nil
  end

  def set_ancestor_method(method_name)
    method= method_name.is_a?(Symbol) ? method_name : method_name.to_sym
    @ancestor_method = self.method_missing(method)
  end

  def method_missing(sym)
    @ancestor.instance_method(sym).bind(@subject)
  end

  def get_ancestor_method
    @ancestor_method
  end

end
