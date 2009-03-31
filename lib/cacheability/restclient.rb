require 'restclient'
require 'rack/cache'

module RestClient
  # A class that mocks the behaviour of a Net::HTTPResponse class.
  # It is required since RestClient::Response must be initialized with a class that responds to :code and :to_hash.
  class MockHTTPResponse
    attr_reader :code, :headers, :body
    def initialize(rack_response)
      @code, @headers, io = rack_response
      @body = ""
      io.each{ |block| @body << block }
      io.close if io.respond_to?(:close)
    end
    
    def to_hash
      @headers
    end    
  end
  
  class CacheableResource < Resource
    attr_reader :cache
    CACHE_DEFAULT_OPTIONS = {}.freeze
    
    def initialize(*args)
      super(*args)
      # rack-cache creates a singleton, so that there is only one instance of the cache at any time
      @cache = Rack::Cache.new(self, options[:cache] || CACHE_DEFAULT_OPTIONS)
    end
  
    def get(additional_headers = {}, pass_through_cache = true)
      if pass_through_cache && cache
        uri = URI.parse(url)
        uri_path_split = uri.path.split("/")
        path_info = (last_part = uri_path_split.pop) ? "/"+last_part : ""
        script_name = uri_path_split.join("/")
        # minimal rack spec
        env = { 
          "REQUEST_METHOD" => 'GET',
          "SCRIPT_NAME" => script_name,
          "PATH_INFO" => path_info,
          "QUERY_STRING" => uri.query,
          "SERVER_NAME" => uri.host,
          "SERVER_PORT" => uri.port.to_s,
          "rack.version" => Rack::VERSION,
          "rack.run_once" => false,
          "rack.multithread" => true,
          "rack.multiprocess" => true,
          "rack.url_scheme" => uri.scheme,
          "rack.input" => StringIO.new,
          "rack.errors" => StringIO.new   # Rack-Cache writes errors into this field
        }
        debeautify_headers(additional_headers).each do |key, value|
          env.merge!("HTTP_"+key.to_s.gsub("-", "_").upcase => value)
        end
        response = MockHTTPResponse.new(cache.call(env))
        RestClient::Response.new(response.body, response)
      else
        super(additional_headers)
      end
    end
  
    def debeautify_headers(headers = {})
      headers.inject({}) do |out, (key, value)|
  			out[key.to_s.gsub(/_/, '-')] = value
  			out
  		end
    end
  
    def call(env)
      http_headers = env.inject({}) do |out, (header, value)| 
        if header =~ /HTTP_/
          out[header.gsub("HTTP_", '')] = value unless value.nil? || value.empty?
        end
        out
      end
      response = get(debeautify_headers(http_headers), pass_through_cache=false)
      response.headers.delete(:x_content_digest) # don't know why, but it seems to make the validation fail if kept...
      [response.code, debeautify_headers( response.headers ), response.to_s]
    rescue RestClient::NotModified => e
      [304, e.response.to_hash, ""]
    end
  end
end