require "./interfaces"

module Entitas
  class Matcher(T) < IAllOfMatcher(T)
    @_indicies : Array(Int32) = Array(Int32).new
    @_all_of_indicies : Array(Int32) = Array(Int32).new
    @_any_of_indicies : Array(Int32) = Array(Int32).new
    @_none_of_indicies : Array(Int32) = Array(Int32).new
    @component_names : Array(String) = Array(String).new
    @_hash : Int32 = 0
    @_is_hash_cached : Bool = false

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

    def ==(matcher : Matcher(T)) : Bool
      if matcher.all_of_indicies != @_all_of_indicies
          return false
      end
      if matcher.any_of_indicies != @_any_of_indicies
          return false
      end
      if matcher.none_of_indicies != @_none_of_indicies
          return false
      end
      true;
    end

    def get_hash_code : Int32
      unless @_is_hash_cached
          # FIXME: GetType().GetHashCode();
          hash = get_hash_code
          hash = apply_hash(hash, @_all_of_indicies, 3, 53);
          hash = apply_hash(hash, @_any_of_indicies, 307, 367);
          hash = apply_hash(hash, @_none_of_indicies, 647, 683);
          @_hash = hash;
          @_is_hash_cached = true;
      end

      @_hash;
    end

    def self.apply_hash(hash : Int32, indices : Array(Int32) | Nil, i1 : Int32, i2 : Int32) : Int32
      unless indicies.nil?
        indicies.each_index do |i|
          hash ^= indices[i] * i1;
        end
        hash ^= indices.size * i2;
      end
      hash
    end
  end
end
