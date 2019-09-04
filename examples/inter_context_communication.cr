require "../src/entitas"

annotation EntityIndex; end

@[Context(Input)]
class Click < Entitas::Component
  prop :state, Bool, default: false
end

@[Context(Input)]
class InputId < Entitas::Component
  prop :value, String
end

@[Context(Game)]
class Name < Entitas::Component
  prop :value, String
end

# @[Context(Game)]
# class ButtonState < Entitas::Component
#   @[EntityIndex]
#   prop :value, String
# end

annotation MyIvar; end

@[Component::Unique]
@[Context(Game)]
class ButtonState < Entitas::Component
  @[::Component::Index]
  prop :value, String, index: true

  @[Component::Index]
  @something = "stgg"

  getter no : String = "no"

  @[MyIvar]
  def poo
  end
end
