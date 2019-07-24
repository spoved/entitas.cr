module Entitas
  class Matcher
    spoved_logger

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

    def matches?(entity : ::Entitas::Entity)
      logger.debug("matches_all_of? #{matches_all_of?(entity)}" \
                   " && matches_any_of? #{matches_any_of?(entity)}" \
                   " && matches_none_of? #{matches_none_of?(entity)}", self)
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

    def all_of(*comps : Entitas::Component.class) : Matcher
      self.all_of_indices = comps.to_a.map { |c| ::Entitas::Component::COMPONENT_TO_INDEX_MAP[c] }.uniq.sort
      self
    end

    def all_of(*matchers : Matcher) : Matcher
      self.all_of_indices = self.class.merge_indicies(*matchers)
      self.class.set_component_names(self, *matchers)
      self
    end

    def any_of(*comps : Entitas::Component.class) : Matcher
      self.any_of_indices = comps.to_a.map { |c| ::Entitas::Component::COMPONENT_TO_INDEX_MAP[c] }.uniq.sort
      self
    end

    def any_of(*matchers : Matcher) : Matcher
      self.any_of_indices = self.class.merge_indicies(*matchers)
      self.class.set_component_names(self, *matchers)
      self
    end

    def none_of(*comps : Entitas::Component.class) : Matcher
      self.none_of_indices = comps.to_a.map { |c| ::Entitas::Component::COMPONENT_TO_INDEX_MAP[c] }.uniq.sort
      self
    end

    def none_of(*matchers : Matcher) : Matcher
      self.none_of_indices = self.class.merge_indicies(*matchers)
      self.class.set_component_names(self, *matchers)
      self
    end

    ####################
    # Class methods
    ####################

    # Create a matcher to match entities with ALL of the provided `Entitas::Component` classes
    #
    # ```
    # Entitas::Matcher(TestEntity).all_of(A, B)
    # ```
    def self.all_of(*comps : Entitas::Component.class) : Matcher
      Entitas::Matcher.new.all_of(*comps)
    end

    # Create a matcher to match entities that have ALL of the `Entitas::Component` classes
    # in the provided `Entitas::Matcher` instances to merge
    #
    # ```
    # m1 = Entitas::Matcher(TestEntity).all_of(A)
    # m2 = Entitas::Matcher(TestEntity).all_of(B)
    # matcher = Entitas::Matcher(TestEntity).all_of(m1, m2)
    # ```
    def self.all_of(*matchers : Matcher) : Matcher
      Entitas::Matcher.new.all_of(*matchers)
    end

    # Create a matcher to match entities that have ANY of the provided `Entitas::Component` classes
    #
    # ```
    # Entitas::Matcher(TestEntity).any_of(A, B)
    # ```
    def self.any_of(*comps : Entitas::Component.class) : Matcher
      Entitas::Matcher.new.any_of(*comps)
    end

    # Create a matcher to match entities that have ANY of the `Entitas::Component` classes
    # in the provided `Entitas::Matcher` instances to merge
    #
    # ```
    # m1 = Entitas::Matcher(TestEntity).any_of(A)
    # m2 = Entitas::Matcher(TestEntity).any_of(B)
    # matcher = Entitas::Matcher(TestEntity).any_of(m1, m2)
    # ```
    def self.any_of(*matchers : Matcher) : Matcher
      Entitas::Matcher.new.any_of(*matchers)
    end

    # Create a matcher to match entities that have NONE of the provided `Entitas::Component` classes
    #
    # ```
    # Entitas::Matcher(TestEntity).none_of(A, B)
    # ```
    def self.none_of(*comps : Entitas::Component.class) : Matcher
      Entitas::Matcher.new.none_of(*comps)
    end

    # Create a matcher to match entities that have NONE of the `Entitas::Component` classes
    # in the provided `Entitas::Matcher` instances to merge
    #
    # ```
    # m1 = Entitas::Matcher(TestEntity).none_of(A)
    # m2 = Entitas::Matcher(TestEntity).none_of(B)
    # matcher = Entitas::Matcher(TestEntity).none_of(m1, m2)
    # ```
    def self.none_of(*matchers : Matcher) : Matcher
      Entitas::Matcher.new.none_of(*matchers)
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

    def indices : Array(Entitas::Component::Index)
      @indices ||= (self.all_of_indices + self.any_of_indices + self.none_of_indices).uniq
    end

    private def comp_names_to_s(indices)
      if self.component_names.empty?
        (indices.map &.value).join(", ")
      else
        indices.map { |i| component_names[i.value] }.join(", ")
      end
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
