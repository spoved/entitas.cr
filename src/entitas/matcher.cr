require "./interfaces/i_matcher"
require "./matcher/*"

module Entitas
  class Matcher
    Log = ::Log.for(self)

    include IAllOfMatcher

    property component_names : Array(String) = Array(String).new

    protected setter all_of_indices : Set(Entitas::Component::Index) = Set(Entitas::Component::Index).new
    protected setter any_of_indices : Set(Entitas::Component::Index) = Set(Entitas::Component::Index).new
    protected setter none_of_indices : Set(Entitas::Component::Index) = Set(Entitas::Component::Index).new

    protected setter indices : Set(Entitas::Component::Index)? = nil

    def initialize(@component_names : Array(String) = Array(String).new); end

    def indices : Set(Entitas::Component::Index)
      @indices ||= Set(Entitas::Component::Index).new.concat(
        self.all_of_indices
      ).concat(
        self.any_of_indices
      ).concat(
        self.none_of_indices
      )
    end

    def matches?(entity : Entitas::Entity) : Bool
      {% if flag?(:entitas_enable_logging) %}
        Log.debug { "matches_all_of? #{matches_all_of?(entity)}" \
                    " && matches_any_of? #{matches_any_of?(entity)}" \
                    " && matches_none_of? #{matches_none_of?(entity)}" }
      {% end %}
      matches_all_of?(entity) && matches_any_of?(entity) && matches_none_of?(entity)
    end

    private def matches_all_of?(entity : Entitas::Entity)
      self.all_of_indices.empty? || entity.has_components?(self.all_of_indices)
    end

    private def matches_any_of?(entity : Entitas::Entity)
      self.any_of_indices.empty? || entity.has_any_component?(self.any_of_indices)
    end

    private def matches_none_of?(entity : Entitas::Entity)
      self.none_of_indices.empty? || !entity.has_any_component?(self.none_of_indices)
    end

    # Equality. Returns `true` if each element in `self` is equal to each
    # corresponding element in *other*.
    def ==(other : Matcher)
      (self.all_of_indices == other.all_of_indices &&
        self.any_of_indices == other.any_of_indices &&
        self.none_of_indices == other.none_of_indices)
    end

    ####################
    # Class methods
    ####################

    protected def self.merge(*matchers : IMatcher) : IMatcher
      matcher = Entitas::Matcher.new

      matchers.each do |m|
        matcher.all_of_indices.concat(m.all_of_indices)
        matcher.any_of_indices.concat(m.any_of_indices)
        matcher.none_of_indices.concat(m.none_of_indices)
      end
      set_component_names(matcher, *matchers)
      matcher
    end

    protected def self.merge_indicies(*matchers : IMatcher) : Set(Entitas::Component::Index)
      indices_cache = Set(Entitas::Component::Index).new(matchers.size)
      matchers.each do |m|
        raise Error.new(m.indices.size) if m.indices.size != 1
        indices_cache.concat(m.indices)
      end
      indices_cache
    end

    protected def self.get_component_names(*matchers : IMatcher) : Enumerable(String)?
      matchers.each do |m|
        return m.component_names unless m.component_names.empty?
      end
      nil
    end

    protected def self.set_component_names(matcher : IMatcher, *matchers : IMatcher) : Nil
      names = get_component_names(*matchers)
      unless names.nil?
        matcher.component_names = names
      end
    end

    private def comp_names_to_s(indices, io)
      if self.component_names.empty?
        indices.each_with_index do |value, i|
          io << ", " if i > 0
          io << value.to_s
        end
      else
        indices.each_with_index do |value, i|
          io << ", " if i > 0
          io << component_names[value.value]
        end
      end
    rescue
      indices.each_with_index do |value, i|
        io << ", " if i > 0
        io << value
      end
    end

    def to_s(io)
      unless self.all_of_indices.empty?
        io << "AllOf("
        comp_names_to_s(self.all_of_indices, io)
        io << ")"
      end

      unless self.any_of_indices.empty?
        io << "." if !self.all_of_indices.empty?
        io << "AnyOf("
        comp_names_to_s(self.any_of_indices, io)
        io << ")"
      end

      unless self.none_of_indices.empty?
        io << "." if !self.all_of_indices.empty? || !self.any_of_indices.empty?
        io << "NoneOf("
        comp_names_to_s(self.none_of_indices, io)
        io << ")"
      end
      io
    end

    def to_json(json : JSON::Builder)
      json.string to_s
    end
  end
end
