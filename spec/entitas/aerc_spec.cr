require "../spec_helper"

describe Entitas::AERC do
  describe Entitas::SafeAERC do
    owner = "Owner"

    it "can retain owners" do
      aerc = Entitas::SafeAERC.new(new_entity)
      aerc.retain(owner)
      aerc.includes?(owner).should be_true
    end

    it "can release owners" do
      aerc = Entitas::SafeAERC.new(new_entity)
      aerc.retain(owner)
      aerc.includes?(owner).should be_true

      aerc.release(owner)
      aerc.includes?(owner).should be_false
    end
  end

  describe Entitas::UnsafeAERC do
  end
end
