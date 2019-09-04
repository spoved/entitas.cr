# Used to define the context(s) of the component
#
# You can add a single context:
# ```
# @[Context(Game)]
# class MyComponent < Entitas::Component
# end
# ```
#
# Or multiple:
# ```
# @[Context(Game)]
# @[Context(UI)]
# class MyComponent < Entitas::Component
# end
# ```
annotation ::Context; end

# Used to declare a component unique to a context
#
# ```
# @[Component::Unique]
# @[Context(Game)]
# class UniqueComp < Entitas::Component
#   prop :size, Int32
#   prop :default, String, default: "foo"
# end
# ```
annotation ::Component::Unique; end

# Used to declare if a method should be called at the end of
# initializing a new `Entitas::Contexts`, `Entitas::Context` or
# `Entitas::Entity`
#
# ```
# def Entitas::Contexts
#   @[Entitas::PostConstructor]
#   def call_me_after_init
#     # do something
#   end
# end
# ```
annotation Entitas::PostConstructor; end
