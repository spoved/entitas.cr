module Entitas
  abstract class Matcher(T)
    @indices : Array(Int32)? = nil
    protected getter all_of_indices : Array(Int32) = Array(Int32).new
    protected getter any_of_indices : Array(Int32) = Array(Int32).new
    protected getter none_of_indices : Array(Int32) = Array(Int32).new

    property component_names : Array(String) = Array(String).new

    abstract def matches?(entity : T)
  end
end
