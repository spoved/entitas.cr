class Entitas::Stack(T)
  include Enumerable(T)

  @_array : Array(T)
  @_version = 0

  def initialize
    @_array = Array(T).new
  end

  def initialize(collection : Enumerable(T))
    @_array = collection.to_a
  end

  def count
    @_array.size
  end

  def size
    @_array.size
  end

  def clear
    @_array.clear
    increment_version
  end

  def each
    @_array.reverse.each do |obj|
      yield obj
    end
  end

  def contains?(obj : T) : Bool
    includes?(obj)
  end

  def copy_to(array : Indexable(T), array_index : Int32)
    if array_index < 0 || array_index > size
      raise ArgumentError.new("Index was out of range. Must be non-negative and less than the size of the collection.")
    end
    if @_array.size - array_index < size
      raise ArgumentError.new("Offset and length were out of bounds for the array or count is greater than the number" \
                              " of elements from index to the end of the source collection.")
    end

    num1 = 0
    num2 = array_index + size
    while (num1 < size)
      num2 -= 1
      array[num2] = array[num1]
      num1 += 1
    end
  end

  def peak
    @_array.last
  end

  def peek?
    @_array.last?
  end

  def pop
    @_array.pop
    increment_version
  end

  def pop?
    item = @_array.pop?
    increment_version unless item.nil?
    item
  end

  def push(obj : T)
    @_array.push(obj)
    increment_version
  end

  private def increment_version
    @_version += 1
  end
end
