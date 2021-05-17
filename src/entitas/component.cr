require "./interfaces/i_component"
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
  #
  # Conmponets can also be declared using existing classes without inheritance.
  # The special macro `property_alias` will need to be used to alias any pre-existing methods as
  # component values
  #
  # ```
  # @[Context(Test3)]
  # class Vector3 < Array(Int32)
  #   property_alias :size, Int32, default: 0
  #   define_property :age, Int32, default: 0
  # end
  # ```
  abstract class Component
    include Entitas::IComponent

    macro inherited
      include Entitas::IComponent
    end
  end
end
