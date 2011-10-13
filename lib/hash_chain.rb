class Hash::Chain
  # == Constants ============================================================

  # == Class Methods ========================================================

  def self.[](*hashes)
    new(*hashes)
  end

  # == Instance Methods =====================================================
  
  def initialize(*hashes)
    @hashes = hashes.flatten
  end
  
  def [](key)
    @hashes.each do |hash|
      if (hash.key?(key) or !hash[key].nil?)
        return hash[key]
      end
    end
    
    nil
  end
  
  def keys
    @hashes.inject([ ]) { |a, h| a += h.keys }.uniq
  end
  
  def values
    self.to_h.values
  end
  
  def key?(key)
    !!@hashes.find { |hash| hash.key?(key) }
  end
  
  def empty?
    !@hashes.find { |hash| !hash.empty? }
  end
  
  def length
    self.keys.length
  end
  
  def each
    self.keys.each do |key|
      yield(key, self[key])
    end
  end
  
  def to_h
    combined = { }
    
    @hashes.each do |hash|
      hash.each do |key, value|
        next if (combined.key?(key))

        combined[key] = value
      end
    end
    
    combined
  end
  
  def to_a
    self.to_h.to_a
  end
end
