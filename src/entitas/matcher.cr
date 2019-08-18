require "./matcher/*"

module Entitas
  class Matcher
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    class Error < Exception
      def initialize(@length : Int32); end

      def to_s
        "matcher.indices.size must be 1 but was #{@length}"
      end
    end

    getter all_of_indices : Array(Entitas::Component::Index)
    getter any_of_indices : Array(Entitas::Component::Index)
    getter none_of_indices : Array(Entitas::Component::Index)

    property component_names : Array(String) = Array(String).new

    protected setter all_of_indices : Array(Entitas::Component::Index) = Array(Entitas::Component::Index).new
    protected setter any_of_indices : Array(Entitas::Component::Index) = Array(Entitas::Component::Index).new
    protected setter none_of_indices : Array(Entitas::Component::Index) = Array(Entitas::Component::Index).new
    protected setter indices : Array(Entitas::Component::Index)? = nil

    def indices : Array(Entitas::Component::Index)
      @indices ||= (self.all_of_indices + self.any_of_indices + self.none_of_indices).uniq.sort
    end

    def matches?(entity : ::Entitas::Entity)
      {% if !flag?(:disable_logging) %}
        logger.debug("matches_all_of? #{matches_all_of?(entity)}" \
                     " && matches_any_of? #{matches_any_of?(entity)}" \
                     " && matches_none_of? #{matches_none_of?(entity)}", self)
      {% end %}
      matches_all_of?(entity) && matches_any_of?(entity) && matches_none_of?(entity)
    end

    private def matches_all_of?(entity : ::Entitas::Entity)
      self.all_of_indices.empty? || entity.has_components?(self.all_of_indices)
    end

    private def matches_any_of?(entity : ::Entitas::Entity)
      self.any_of_indices.empty? || entity.has_any_component?(self.any_of_indices)
    end

    private def matches_none_of?(entity : ::Entitas::Entity)
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
    # Chainables
    ####################

    macro finished
      {% begin %}{% for match in ["all", "any", "none"] %}

      # Create a matcher to match entities with {{match.upcase}} of the provided `Entitas::Component` classes
      #
      # ```
      # Entitas::Matcher.new.{{match.id}}_of(A, B)
      # ```
      def {{match.id}}_of(*comps : Entitas::Component.class) : Matcher
        self.{{match.id}}_of_indices = comps.map { |c| c.index }.to_a.uniq.sort
        self
      end

      # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
      # in the provided `Int32` indices to merge
      #
      # ```
      # Entitas::Matcher.new.{{match.id}}_of(0)
      # ```
      def {{match.id}}_of(*indices : Int32) : Matcher
        self.{{match.id}}_of_indices = indices.map { |i| ::Entitas::Component::Index.new(i) }.to_a.uniq.sort
        self
      end

      # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
      # in the provided `::Entitas::Component::Index` indices to merge
      #
      # ```
      # Entitas::Matcher.new.{{match.id}}_of(Entitas::Component::Index::A)
      # ```
      def {{match.id}}_of(*indices : Entitas::Component::Index) : Matcher
        self.{{match.id}}_of_indices = indices.to_a.uniq.sort
        self
      end

      # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
      # in the provided `Entitas::Matcher` instances to merge
      #
      # ```
      # m1 = Entitas::Matcher.new.{{match.id}}_of(A)
      # m2 = Entitas::Matcher.new.{{match.id}}_of(B)
      # matcher = Entitas::Matcher.new.{{match.id}}_of(m1, m2)
      # ```
      def {{match.id}}_of(*matchers : Matcher) : Matcher
        self.{{match.id}}_of_indices = self.class.merge_indicies(*matchers)
        self.class.set_component_names(self, *matchers)
        self
      end
      {% end %}{% end %}
    end

    ####################
    # Class methods
    ####################

    macro finished
      {% begin %}{% for match in ["all", "any", "none"] %}
      # Create a matcher to match entities with {{match.upcase}} of the provided `Entitas::Component` classes
      #
      # ```
      # Entitas::Matcher.{{match.id}}_of(A, B)
      # ```
      def self.{{match.id}}_of(*comps : Entitas::Component.class) : Matcher
        Entitas::Matcher.new.{{match.id}}_of(*comps)
      end

      # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
      # in the provided `Int32` indexs to merge
      #
      # ```
      # Entitas::Matcher.{{match.id}}_of(0)
      # ```
      def self.{{match.id}}_of(*indices : Int32) : Matcher
        Entitas::Matcher.new.{{match.id}}_of(*indices)
      end

      # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
      # in the provided `Entitas::Component::Index` indices to merge
      #
      # ```
      # Entitas::Matcher.{{match.id}}_of(Entitas::Component::Index::A)
      # ```
      def self.{{match.id}}_of(*indices : Entitas::Component::Index) : Matcher
        Entitas::Matcher.new.{{match.id}}_of(*indices)
      end

      # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
      # in the provided `Entitas::Matcher` instances to merge
      #
      # ```
      # m1 = Entitas::Matcher.{{match.id}}_of(A)
      # m2 = Entitas::Matcher.{{match.id}}_of(B)
      # matcher = Entitas::Matcher.{{match.id}}_of(m1, m2)
      # ```
      def self.{{match.id}}_of(*matchers : Matcher) : Matcher
        Entitas::Matcher.new.{{match.id}}_of(*matchers)
      end
      {% end %}{% end %}
    end

    protected def self.merge(*matchers : Matcher) : Matcher
      matcher = Entitas::Matcher.new

      matchers.each do |m|
        matcher.all_of_indices += m.all_of_indices
        matcher.any_of_indices += m.any_of_indices
        matcher.none_of_indices += m.none_of_indices
      end
      set_component_names(matcher, *matchers)
      matcher
    end

    protected def self.merge_indicies(*matchers : Matcher) : Array(Entitas::Component::Index)
      indices = Array(Entitas::Component::Index).new
      matchers.each do |m|
        raise Error.new(m.indices.size) if m.indices.size != 1
        indices += m.indices
      end
      indices.uniq.sort
    end

    protected def self.get_component_names(*matchers : Matcher) : Array(String)?
      matchers.each do |m|
        return m.component_names unless m.component_names.empty?
      end
      nil
    end

    protected def self.set_component_names(matcher : Matcher, *matchers : Matcher) : Nil
      names = get_component_names(*matchers)
      unless names.nil?
        matcher.component_names = names
      end
    end

    private def comp_names_to_s(indices)
      if self.component_names.empty?
        (indices.map &.value).join(", ")
      else
        indices.map { |i| component_names[i.value] }.join(", ")
      end
    rescue
      (indices.map &.value).join(", ")
    end

    def to_s(io)
      unless self.all_of_indices.empty?
        io << "AllOf("
        io << comp_names_to_s(self.all_of_indices)
        io << ")"
      end

      unless self.any_of_indices.empty?
        io << "." if !self.all_of_indices.empty?
        io << "AnyOf("
        io << comp_names_to_s(self.any_of_indices)
        io << ")"
      end

      unless self.none_of_indices.empty?
        io << "." if !self.all_of_indices.empty? || !self.any_of_indices.empty?
        io << "NoneOf("
        io << comp_names_to_s(self.none_of_indices)
        io << ")"
      end
      io
    end
  end
end
