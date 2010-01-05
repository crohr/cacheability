require 'restclient'
require 'rack/cache'

module RestClient
  # hash of the enabled components 
  @components = {}

  class <<self
    attr_reader :components
  end
  
  # Enable a component.
  #   RestClient.enable :caching, 
  #                       :verbose     => true,
  #                       :metastore   => 'file:/var/cache/rack/meta'
  #                       :entitystore => 'file:/var/cache/rack/body'
  # 
  # See http://tomayko.com/src/rack-cache/configuration for the list of available options
  def self.enable(component, options = {})
    case component
    when :caching
      @components[component] = Rack::Cache.new(CACHING_PROC, {:allow_reload => true, :allow_revalidate => true}.merge(options))
    end
  end
  
  # Disable a component
  #   RestClient.disable :caching
  def self.disable(component)
    @components.delete(component)
  end
  
  # Returns true if the given component is enabled, false otherwise
  #   RestClient.enable :caching
  #   RestClient.enabled?(:caching)
  #   => true
  def self.enabled?(component)
    @components.has_key?(component) && !@components[component].nil?
  end
  
  
  def self.debeautify_headers(headers = {})   # :nodoc:
    headers.inject({}) do |out, (key, value)|
			out[key.to_s.gsub(/_/, '-').downcase] = value.to_s
			out
		end
  end
  
	
	class Request
	  class <<self
  	  alias_method :original_execute, :execute
  	  def execute(args)
  	    if RestClient.enabled?(:caching)
    	    request = new(args)
  	      uri = URI.parse(request.url)
          uri_path_split = uri.path.split("/")
          path_info = (last_part = uri_path_split.pop) ? "/"+last_part : ""
          script_name = uri_path_split.join("/")
          # minimal rack spec
          env = { 
            "cacheability.args" => args,
            "REQUEST_METHOD" => request.method.to_s.upcase,
            "SCRIPT_NAME" => script_name,
            "PATH_INFO" => path_info,
            "QUERY_STRING" => uri.query || "",
            "SERVER_NAME" => uri.host,
            "SERVER_PORT" => uri.port.to_s,
            "rack.version" => Rack::VERSION,
            "rack.run_once" => false,
            "rack.multithread" => true,
            "rack.multiprocess" => true,
            "rack.url_scheme" => uri.scheme,
            "rack.input" => StringIO.new,
            "rack.errors" => STDERR   # Rack-Cache writes errors into this field
          }
          RestClient.debeautify_headers(request.headers).each do |key, value|
            env.merge!("HTTP_"+key.to_s.gsub("-", "_").upcase => value)
          end
          status, headers, body = RestClient.components[:caching].call(env)
          response = MockNetHTTPResponse.new(body, status, headers)
          RestClient::Response.new(response.body.join, response)
        else
          # call original execute method
          # cache will be automatically invalidated on non-GET requests by Rack::Cache if needed
          original_execute(args)
        end
      end
    end

  end
	
  # A class that mocks the behaviour of a Net::HTTPResponse class.
  # It is required since RestClient::Response must be initialized with a class that responds to :code and :to_hash.
  class MockNetHTTPResponse
    attr_reader :body, :header, :status
    alias_method :code, :status
    
    def initialize(body, status, header)
      @body = body
      @status = status
      @header = header
    end

    def to_hash
      @header.inject({}) {|out, (key, value)|
        # In Net::HTTP, header values are arrays
        out[key.downcase] = [value]
        out
      }
    end    
  end
  
  CACHING_PROC = Proc.new { |env|
    begin
      # get the original args needed to execute the request
      response = Request.original_execute(env['cacheability.args']) 
      # to satisfy Rack::Lint
      response.headers.delete(:status)
      [response.code, RestClient.debeautify_headers( response.headers ), [response.to_s]]
    rescue RestClient::NotModified => e
       # e is a Net::HTTPResponse
      response = RestClient::Response.new(e.response.to_s, e.response)
      [304, RestClient.debeautify_headers( response.headers ), [response.to_s]]
    end
  }
end