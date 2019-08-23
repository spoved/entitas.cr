struct Set(T)
  def pop
    obj = first
    delete(obj)
    obj
  end
end
