module Jasmine
  class SeleniumDriver
    def initialize(selenium_browser_start_command, http_address)
      require 'json/pure' unless defined?(JSON)
      require 'sauce'
      require 'uri'
      @driver = Sauce::Selenium.new(:browser => selenium_browser_start_command, :browser_url => "http://jasmine.test/", :job_name => "Jasmine", :'record-video' => false, :'record-screenshots' => false)
      @http_address = http_address
    end

    def tests_have_finished?
      @driver.get_eval("window.jasmine.getEnv().currentRunner.finished") == "true"
    end

    def connect
      uri = URI.parse(@http_address)
      puts "Setting up Sauce Connect..."
      @connection = Sauce::Connect.new(:domain => "jasmine.test", :host => uri.host, :port => uri.port, :quiet => true)
      @connection.wait_until_ready
      puts "Sauce Connect ready."
      @driver.start
      @driver.open("/")
    end

    def disconnect
      @driver.stop
      @connection.disconnect
    end

    def run
      until tests_have_finished? do
        sleep 0.1
      end

      puts @driver.get_eval("window.results()")
      failed_count = @driver.get_eval("window.jasmine.getEnv().currentRunner.results().failedCount").to_i
      failed_count == 0
    end

    def eval_js(script)
      escaped_script = "'" + script.gsub(/(['\\])/) { '\\' + $1 } + "'"

      result = @driver.get_eval("try { eval(#{escaped_script}, window); } catch(err) { window.eval(#{escaped_script}); }")
      JSON.parse("{\"result\":#{result}}")["result"]
    end

    def json_generate(obj)
      JSON.generate(obj)
    end
  end
end
