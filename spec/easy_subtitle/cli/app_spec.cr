require "../../spec_helper"

describe EasySubtitle::CLI::App do
  it "can be instantiated" do
    app = EasySubtitle::CLI::App.new
    app.should_not be_nil
  end
end
