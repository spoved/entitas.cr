require "../spec_helper"

class SpecTestController < Entitas::Controller
  def initialize(@contexts); end

  def create_systems(contexts : Contexts)
    sub_systems = Entitas::Feature.new("SubSystems")
    sub_systems.add(ExecuteSystemSpy.new)
    Entitas::Feature.new("Systems")
      .add(InitializeSystemSpy.new)
      .add(CleanupSystemSpy.new)
      .add(sub_systems)
  end
end

describe Entitas::Controller do
  describe "finds sub system" do
    controller = SpecTestController.new(Contexts.shared_instance)
    controller.start

    it "at first level" do
      rs = controller.find_system(InitializeSystemSpy)
      rs.should be_a InitializeSystemSpy
    end

    it "at nested levels" do
      rs = controller.find_system(ExecuteSystemSpy)
      rs.should be_a ExecuteSystemSpy
    end
  end

  it "finds sub systems" do
    controller = SpecTestController.new(Contexts.shared_instance)
    controller.start
    rs = controller.find_systems(Entitas::Feature)
    rs.size.should eq 2
    rs.each &.should be_a Entitas::Feature
  end
end
