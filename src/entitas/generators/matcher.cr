class ::Entitas::Matcher
  macro gen_functions
    # class ::Entitas::Matcher
      {% puts "### Generating matcher functions #{@type.id}" %}
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
        {% end %} # end for match in ["all", "any", "none"]

        ####################
        # Chainables
        ####################
        {% for match, interface in {"all"  => "IAllOfMatcher",
                                    "any"  => "IAnyOfMatcher",
                                    "none" => "INoneOfMatcher"} %}

          # Create a matcher to match entities with {{match.upcase}} of the provided `Entitas::Component` classes
          #
          # ```
          # Entitas::Matcher.new.{{match.id}}_of(A, B)
          # ```
          def {{match.id}}_of(*comps : Entitas::Component::ComponentTypes) : {{interface.id}}
            self.{{match.id}}_of_indices = Set(Entitas::Component::Index).new(comps.size)
            comps.each { |c| self.{{match.id}}_of_indices << c.index }
            self
          end

          # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
          # in the provided `Int32` indices to merge
          #
          # ```
          # Entitas::Matcher.new.{{match.id}}_of(0)
          # ```
          def {{match.id}}_of(*indices : Int32) : {{interface.id}}
            self.{{match.id}}_of_indices = Set(Entitas::Component::Index).new(indices.size)
            indices.each { |i| self.{{match.id}}_of_indices << Entitas::Component::Index.new(i) }
            self
          end

          # Create a matcher to match entities that have {{match.upcase}} of the `Entitas::Component` classes
          # in the provided `Entitas::Component::Index` indices to merge
          #
          # ```
          # Entitas::Matcher.new.{{match.id}}_of(Entitas::Component::Index::A)
          # ```
          def {{match.id}}_of(*indices : Entitas::Component::Index) : {{interface.id}}
            self.{{match.id}}_of_indices = Set(Entitas::Component::Index).new(indices)
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
          def {{match.id}}_of(*matchers : IMatcher) : {{interface.id}}
            self.{{match.id}}_of_indices.concat(self.class.merge_indicies(*matchers))
            self.class.set_component_names(self, *matchers)
            self
          end
        {% end %} # end for match, interface
      {% end %} # end begin
    # end
  end
end
