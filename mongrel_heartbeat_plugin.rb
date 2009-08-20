require 'rubygems'
require 'yaml'
require 'net/http'
require 'uri'

CONFIG_FILE = "/data/honk/shared/config/mongrel_cluster.yml"

if defined?(Scout::Plugin)

  class MongrelHeartbeatPlugin < Scout::Plugin
    def build_report
      results = MongrelProcessMonitor.new.process_status
      is_up = true
      results.each_pair do |key,value|
         unless value
           alert("Mongrel On Port #{key} Not Responding")
           remember(:down_at => Time.now)
           is_up = false
         end
      end

      report(:up => is_up)
      remember(:was_up => is_up)    
    rescue Exception => e
      error("Error monitoring mongrels", "#{e.message}<br><br>#{e.backtrace.join('<br>')}")
    end
  end

end


class MongrelPortManager
  def mongrel_ports(mongrel_config = CONFIG_FILE)
    # read YAML file and get ports...
  	config = YAML.load_file(mongrel_config)
  	@port = config["port"].to_i
    @servers = config["servers"].to_i
    @ports = []
    @port.upto(@port+@servers-1) { |port| @ports << port}
    @ports
  end
end


#based on url_monitor by Andre Lewis
#http://www.highgroove.com

class MongrelProcessMonitor
   TIMEOUT_LENGTH = 50

  #returns a hash of ports and whether or not its up 
  def process_status(mongrel_config = CONFIG_FILE)
     mongrel_ports = MongrelPortManager.new.mongrel_ports(mongrel_config)
      return [] if mongrel_ports.empty? || mongrel_ports.nil?
      response_summary = Hash.new
      mongrel_ports.each do |port|
        response = self.http_response("http://localhost:#{port}/")
        response_summary[port] = self.valid_http_response?(response)
      end
      response_summary
  end

  def valid_http_response?(result)
    [Net::HTTPOK,Net::HTTPFound].include?(result.class)
  end

  # returns the http response (string) from a url
  def http_response(url)
    uri = URI.parse(url)

    response = nil
    retry_url_trailing_slash = true
    retry_url_execution_expired = true
    begin
      Net::HTTP.start(uri.host,uri.port) {|http|
            http.open_timeout = TIMEOUT_LENGTH
            req = Net::HTTP::Get.new(uri.path)     
            response = http.request(req)     
      }
    rescue Exception => e

      # forgot the trailing slash...add and retry
      if e.message == "HTTP request path is empty" and retry_url_trailing_slash
        url += '/'
        uri = URI.parse(url)
        h = Net::HTTP.new(uri.host)
        retry_url_trailing_slash = false
        retry
      elsif e.message =~ /execution expired/ and retry_url_execution_expired
        retry_url_execution_expired = false
        retry
      else
        response = e.to_s
      end
    end

    return response
  end
end
