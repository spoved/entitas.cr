struct Set(T)
  def pop
    obj = first
    delete(obj)
    obj
  end

  # Removes the *object* from the set and returns and returns `true` on success
  # and `false` if the value was not already in the set.
  #
  # ```
  # s = Set{1, 5}
  # s.includes? 5 # => true
  # s.delete 5
  # s.includes? 5 # => false
  # s.delete? 5   # => false
  # ```
  def delete?(object) : Bool
    # TODO: optimize the hash lookup call
    !!(delete(object) if includes?(object))
  end
end
