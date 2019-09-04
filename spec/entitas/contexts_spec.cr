require "../spec_helper"

describe Contexts do
  it "should return the same shared instance" do
    ctxs = Contexts.shared_instance
    ctxs.shared_instance.should_not be_nil
    ctxs.should be Contexts.shared_instance
    Contexts.new.shared_instance.should be Contexts.shared_instance
  end

  it "should build entity indexs" do
    ctxs = Contexts.shared_instance
    # puts ctxs.test.get_entity_index(Contexts::NAME_AGE_ENTITY_INDICES_NAME)
  end
end
