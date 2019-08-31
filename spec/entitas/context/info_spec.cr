require "../../spec_helper"

describe Entitas::Context::Info do
  describe "when created" do
    it "sets fields with constructor values" do
      name = "My Context"
      comp_names = ["Health", "Position", "View"]
      comp_types = [A, B, C] of Entitas::Component::ComponentTypes
      info = Entitas::Context::Info.new(name, comp_names, comp_types)
      info.name.should eq name
      info.component_names.should eq comp_names
      info.component_types.should eq comp_types
    end
  end
end
