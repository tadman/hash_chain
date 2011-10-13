require File.expand_path(File.join(*%w[ .. test_helper ]), File.dirname(__FILE__))

class TestHashChain < Test::Unit::TestCase
  def test_default_state
    hash_chain = Hash::Chain.new
    
    assert_equal true, hash_chain.empty?
    assert_equal [ ], hash_chain.keys
    assert_equal [ ], hash_chain.values
    assert_equal [ ], hash_chain.to_a
    assert_equal Hash.new, hash_chain.to_h
    assert_equal 0, hash_chain.length
  end

  def test_single_hash
    third = Class.new
    
    first = {
      :first => '1st',
      'second' => '2nd',
      third => '3rd',
      [ :fourth ] => '4th'
    }
    
    hash_chain = Hash::Chain[first]
    
    assert_equal false, hash_chain.empty?
    assert_equal first.keys, hash_chain.keys
    assert_equal first.values, hash_chain.values
    assert_equal first.to_a, hash_chain.to_a
    assert_equal first, hash_chain.to_h
    assert_equal 4, hash_chain.length
    
    assert_equal '1st', hash_chain[:first]
    assert_equal '2nd', hash_chain['second']
    assert_equal '3rd', hash_chain[third]
    assert_equal '4th', hash_chain[[ :fourth ]]
    
    result = [ ]
    hash_chain.each do |key, value|
      result << [ key, value ]
    end
    
    assert_equal hash_chain.to_a, result
  end

  def test_two_hashes
    first = {
      :first => '1st',
      :third => nil
    }
    
    second = {
      :second => '2nd',
      :third => '3rd'
    }
    
    hash_chain = Hash::Chain.new(first, second)
    
    assert_equal [ :first, :third, :second ], hash_chain.keys
    assert_equal [ '1st', nil, '2nd' ], hash_chain.values
    assert_equal [ [ :first, '1st' ], [ :third, nil ], [ :second, '2nd' ] ], hash_chain.to_a
    assert_equal 3, hash_chain.length
    assert_equal false, hash_chain.empty?
    
    assert_equal '1st', hash_chain[:first]
    assert_equal true, hash_chain.key?(:first)
    assert_equal '2nd', hash_chain[:second]
    assert_equal true, hash_chain.key?(:second)
    assert_equal nil, hash_chain[:third]
    assert_equal true, hash_chain.key?(:third)
    
    first.delete(:third)

    assert_equal '3rd', hash_chain[:third]

    result = [ ]
    hash_chain.each do |key, value|
      result << [ key, value ]
    end
    
    assert_equal hash_chain.to_a, result
  end
  
  def test_two_hashes_packed_in_arrays
    first = {
      :first => '1st',
      :third => nil
    }
    
    second = [
      {
        :second => '2nd'
      },
      {
        :third => '3rd'
      }
    ]

    hash_chain = Hash::Chain.new([ first, [ second ] ])
    
    assert_equal [ :first, :third, :second ], hash_chain.keys
  end

  def test_chained_chain
    first = {
      :first => '1st',
      :third => nil
    }
    
    second = {
      :second => '2nd',
      :third => '3rd'
    }
    
    third = {
      :fourth => '4th'
    }
    
    hash_chain = Hash::Chain.new(first, Hash::Chain.new(second, third))
    
    assert_equal [ :first, :third, :second, :fourth ], hash_chain.keys
    assert_equal [ [ :first, '1st' ], [ :third, nil ], [ :second, '2nd' ], [ :fourth, "4th" ] ], hash_chain.to_a
    assert_equal 4, hash_chain.length
    assert_equal false, hash_chain.empty?
    
    assert_equal '1st', hash_chain[:first]
    assert_equal '2nd', hash_chain[:second]
    assert_equal nil, hash_chain[:third]
    assert_equal '4th', hash_chain[:fourth]
    
    first.delete(:third)

    assert_equal '3rd', hash_chain[:third]
  end
  
  def test_large_chain
    # Due to the nature of how this is implemented, performance will degrade
    # rapidly past 1000 entries. The retrieval time ends up being, worst-case,
    # around O(N*log(N)) per entry, or O(N^2*log(N)) to retrieve all keys.
    
    hashes = [ ]
    count = 1000
    count.times do |i|
      hashes << { i => i.to_s }
    end
    
    hash_chain = Hash::Chain.new(hashes)
    
    count.times do |i|
      assert_equal i.to_s, hash_chain[i]
    end
  end
  
  def test_hash_default
    first = {
      1 => '1st',
      2 => '2nd',
      3 => '3rd'
    }
    
    second = Hash.new { |h, k| h[k] = "#{k}th" }

    # The order is important here, as a non-nil default will block access
    # to subsequent hashes in the chain.
    hash_chain = Hash::Chain.new(first, second)
    
    assert_equal '1st', hash_chain[1]
    assert_equal '2nd', hash_chain[2]
    assert_equal '3rd', hash_chain[3]
    assert_equal '4th', hash_chain[4]
    assert_equal '109th', hash_chain[109]

    # Reversing the order blocks access to the other hash.
    hash_chain = Hash::Chain.new(second, first)

    assert_equal '1th', hash_chain[1]
    assert_equal '2th', hash_chain[2]
    assert_equal '3th', hash_chain[3]
    assert_equal '4th', hash_chain[4]
    assert_equal '109th', hash_chain[109]
  end

  def test_hash_follow_through_on_nil_and_false
    first = Hash.new { |h, k| h[k] = false }
    second = {
      :test => 'test',
      :false => false,
      :nil => nil
    }
    
    hash_chain = Hash::Chain.new(first, second)
    
    assert_equal false, hash_chain[:test]
    assert_equal false, hash_chain[:false]
    assert_equal false, hash_chain[:nil]

    hash_chain = Hash::Chain.new(second, first)
    
    assert_equal 'test', hash_chain[:test]
    assert_equal false, hash_chain[:false]
    assert_equal nil, hash_chain[:nil]
  end
end
