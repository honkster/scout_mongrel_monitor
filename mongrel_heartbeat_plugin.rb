require 'mongrel_process_monitor'
class MongrelHeartbeatPlugin   < Scout::Plugin
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