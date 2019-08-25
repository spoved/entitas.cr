require "./macros/component"

module Entitas
  # Inherit this class if you want to create a component which
  # you can add to an entity.
  # Optionally, you can add these attributes:
  # @[Component::Unique]: the code generator will generate additional methods for
  # the context to ensure that only one entity with this component exists.
  # E.g. context.is_animating = true or context.SetResources();
  # @[Context(MyContextName), Context(MyOtherContextName)]: You can make this component to be
  # available only in the specified contexts.
  #
  # ```
  # @[Component::Unique, Context(Game), Context(User)]
  # class Foo < Entitas::Component
  #   prop :size, Int32
  #   prop :default, String, default: "foo"
  # end
  # ```
  abstract class Component
    {% if !flag?(:disable_logging) %}spoved_logger{% end %}

    # Will return true if the class is a unique component for a context
    def component_is_unique?
      self.class.is_unique?
    end
  end
end
