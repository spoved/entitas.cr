require "./error"

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

annotation ::Component::Index; end

require "./macros/*"
