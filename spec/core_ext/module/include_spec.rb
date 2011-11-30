# class IncludeAnonymousTest < Test::Unit::TestCase
#   def teardown
#     self.class.send(:remove_const, :A)
#   end
#
#   test 'anonymous include on a class' do
#     class A
#       include { def foo; 'foo' end }
#     end
#     assert_equal 'foo', A.new.foo
#   end
# end
