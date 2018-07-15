module Entitas
  abstract class IMatcher(T)
    @_indicies : Array(Int32) = Array(Int32).new
    def indices
      @_indices
    end

    abstract def matches?(entity : T) : Bool
  end

  abstract class ICompoundMatcher(T) < IMatcher(T)
    @_all_of_indicies : Array(Int32) = Array(Int32).new
    @_any_of_indicies : Array(Int32) = Array(Int32).new
    @_none_of_indicies : Array(Int32) = Array(Int32).new

    def all_of_indicies
      @_all_of_indicies
    end

    def any_of_indicies
      @_any_of_indicies
    end

    def none_of_indicies
      @_none_of_indicies
    end
  end

  abstract class INoneOfMatcher(T) < ICompoundMatcher(T)
  end

  abstract class IAnyOfMatcher(T) < INoneOfMatcher(T)
    abstract def none_of(indices : Array(Int32)) : INoneOfMatcher(T)
    abstract def none_of(matchers : Array(IMatcher(T))) : INoneOfMatcher(T)
  end

  abstract class IAllOfMatcher(T) < IAnyOfMatcher(T)
    abstract def any_of(indices : Array(Int32)) : IAnyOfMatcher(T)
    abstract def any_of(matchers : Array(IMatcher(T))) : IAnyOfMatcher(T)
  end

  class Matcher(T) < IAllOfMatcher(T)
    @_indicies : Array(Int32) = Array(Int32).new
    @_all_of_indicies : Array(Int32) = Array(Int32).new
    @_any_of_indicies : Array(Int32) = Array(Int32).new
    @_none_of_indicies : Array(Int32) = Array(Int32).new
    @component_names : Array(String) = Array(String).new

    property component_names : Array(String)

    def all_of_indicies
      @_all_of_indicies
    end

    def any_of_indicies
      @_any_of_indicies
    end

    def none_of_indicies
      @_none_of_indicies
    end

    def indices
      if @_indices.empty?
        @_indices = @_all_of_indicies + @_any_of_indicies + @_none_of_indicies
      end
      return @_indices
    end

    def matches?(entity : T) : Bool
      return (
        @_all_of_indicies.empty? || entity.has_components?(@_all_of_indicies)
      ) && (
        @_any_of_indicies.empty? || entity.has_any_component?(@_any_of_indicies)
      ) && (
        @_none_of_indicies.empty? || !entity.has_any_component?(@_none_of_indicies)
      )
    end

    def none_of(indices : Array(Int32)) : INoneOfMatcher(T)
      @_none_of_indicies = indices.unique
      @_indices.clear
      @_is_hash_cached = false
      self
    end

    def none_of(matchers : Array(IMatcher(T))) : INoneOfMatcher(T)
      matchers.map { |matcher| none_of(matcher) }
    end

    def any_of(indices : Array(Int32)) : IAnyOfMatcher(T)
      @_any_of_indicies = indices.unique
      @_indices.clear
      @_is_hash_cached = false
      self
    end

    def any_of(matchers : Array(IMatcher(T))) : IAnyOfMatcher(T)
      matchers.map { |matcher| any_of(matcher) }
    end
  end
end
