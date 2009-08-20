require 'rubygems'
require 'spec'
require "mongrel_heartbeat_plugin"

describe "MongrelPortManager#mongrel_ports" do
  before do
    @port_manager = MongrelPortManager.new
    YAML.stub!(:load_file).and_return([])
  end

  it "should return an array of ports the mongrel cluster is using with size equal to servers" do
     YAML.should_receive(:load_file).with(CONFIG_FILE).and_return(
        { "port" => "5000" , "servers" => "3" }
     )

     @port_manager.mongrel_ports.length.should be(3)
  end

  it "should return an array of ports the mongrel cluster is using with size equal to servers" do
     YAML.should_receive(:load_file).with(CONFIG_FILE).and_return(
        { "port" => "5000" , "servers" => "3" }
     )
     @port_manager.mongrel_ports[2].should be(5002)
  end
end

