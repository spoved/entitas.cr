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

@[Context(Test, Test2)]
class NameAge < Entitas::Component
  prop :name, String
  prop :age, Int32, default: 0
end
