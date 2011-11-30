Class.class_eval do
  def include(*args, &block)
    block_given? ? super(Module.new(&block)) : super(*args)
  end
end
