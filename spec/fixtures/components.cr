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
