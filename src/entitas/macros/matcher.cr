class Entitas::Matcher
  macro finished
    {% begin %}
      {% for match in ["all", "any", "none"] %}
        # Create a matcher to match entities with {{match.upcase}} of the provided `Entitas::Component` classes
        #
        # ```
        # Entitas::Matcher.{{match.id}}_of(A, B)
        # ```
        def self.{{match.id}}_of(*comps : Entitas::Component::ComponentTypes) : Matcher
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
      {% end %}
    {% end %}
  end
end
