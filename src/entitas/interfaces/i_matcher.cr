module Entitas
  module IMatcher
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    getter indices : Set(Entitas::Component::Index)

    abstract def matches?(entity : Entitas::Entity) : Bool
  end

  module ICompoundMatcher
    include IMatcher

    getter all_of_indices : Set(Entitas::Component::Index)
    getter any_of_indices : Set(Entitas::Component::Index)
    getter none_of_indices : Set(Entitas::Component::Index)
  end

  module INoneOfMatcher
    include ICompoundMatcher
  end

  module IAnyOfMatcher
    include INoneOfMatcher

    abstract def none_of(*comps : Entitas::Component::ComponentTypes) : INoneOfMatcher
    abstract def none_of(*indices : Int32) : INoneOfMatcher
    abstract def none_of(*indices : Entitas::Component::Index) : INoneOfMatcher
    abstract def none_of(*matchers : IMatcher) : INoneOfMatcher
  end

  module IAllOfMatcher
    include IAnyOfMatcher

    abstract def any_of(*comps : Entitas::Component::ComponentTypes) : IAnyOfMatcher
    abstract def any_of(*indices : Int32) : IAnyOfMatcher
    abstract def any_of(*indices : Entitas::Component::Index) : IAnyOfMatcher
    abstract def any_of(*matchers : IMatcher) : IAnyOfMatcher
  end
end
