require 'yaml'

class MongrelPortManager
  def mongrel_ports(mongrel_config = "/data/honk/shared/config/mongrel_cluster.yml")
    # read YAML file and get ports...
  	config = YAML.load_file(mongrel_config)
  	@port = config["port"].to_i
    @servers = config["servers"].to_i
    @ports = []
    @port.upto(@port+@servers-1) { |port| @ports << port}
    @ports
  end
end
