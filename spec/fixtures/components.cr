require "../../src/entitas"

@[Context(Test, Test2, MyTest)]
class A < Entitas::Component
end

@[Context(Test, Test2, MyTest)]
class B < Entitas::Component
end

@[Context(Test, MyTest)]
class C < Entitas::Component
end

@[Context(Test, MyTest, Input)]
class D < Entitas::Component
end

@[Component::Unique]
@[Context(Test, MyTest, Input)]
class UniqueComp < Entitas::Component
  prop :size, Int32
  prop :default, String, default: "foo"
end

@[Context(Test)]
@[Context(Test2)]
class NameAge < Entitas::Component
  prop :name, String, index: true
  prop :age, Int32, default: 0, index: true
end

@[Context(Test3)]
class Vector3 < Array(Int32)
  property size : Int32

  # Add existing property
  property_alias :size, Int32, default: 0

  # New property
  prop :angle, Int32, default: 0, index: true

  # A property with a constructor method
  prop :custom, String, not_nil: true, method: custom_constructor

  private def custom_constructor
    "Hello im a constructor"
  end
end

@[Component::Unique]
@[Context(Test3)]
class Test::NameSpace
end

##########
# Events
##########

@[Context(Test4)]
@[Entitas::Event(EventTarget::Self, EventType::Added, priority: 1)]
class FlagEntityEvent < Entitas::Component
end

@[Context(Test4)]
@[Entitas::Event(EventTarget::Any, EventType::Removed)]
class FlagEvent
end

@[Context(Test4)]
@[Entitas::Event(EventTarget::Any)]
@[Entitas::Event(EventTarget::Self)]
class MixedEvent < Entitas::Component
  prop :value, String
end

@[Context(Test3, Test4)]
@[Entitas::Event(EventTarget::Any)]
class MultipleContextStandardEvent < Entitas::Component
  prop :value, String
end

@[Context(Test3, Test4)]
@[Entitas::Event(EventTarget::Any, EventType::Added, priority: 1)]
@[Entitas::Event(EventTarget::Any, EventType::Removed, priority: 2)]
class Test::MultipleEventsStandardEvent < Entitas::Component
  prop :value, String
end

@[Context(Test4)]
@[Entitas::Event(EventTarget::Any)]
class StandardEvent < Entitas::Component
  prop :value, String
end

@[Context(Test4)]
@[Entitas::Event(EventTarget::Self, EventType::Removed, priority: 1)]
class StandardEntityEvent < Entitas::Component
  prop :value, String
end

@[Component::Unique]
@[Context(Test4)]
@[Entitas::Event(EventTarget::Any)]
class Test::UniqueEvent < Entitas::Component
  prop :value, String
end

#################
# EntityIndex
#################

@[Context(Test5)]
class Test::NameIndex < Entitas::Component
  @[EntityIndex]
  prop :value, String
end
