require "../spec_helper"

private def group_a
  Entitas::Group.new(Entitas::Matcher.all_of(A))
end

describe Entitas::Group do
  describe "initial state" do
    it "doesn't have entities which haven't been added" do
    end
  end
end
