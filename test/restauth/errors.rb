require "restauth"
require "test/unit"

class TestErrors < Test::Unit::TestCase
  def setup
    ## Nothing really
  end
 
  def teardown
    ## Nothing really
  end
 
  def test_simple
    assert_equal(4, 2+2)
  end
end
