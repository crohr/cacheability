require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/cacheability/restclient'

describe "Cacheability for RestClient" do
    
  it "should enable the caching component" do
    Rack::Cache.should_receive(:new).with(RestClient::CACHING_PROC, :allow_reload => true, :allow_revalidate => true, :key => "value").and_return(mock_cache = mock("rack-cache"))
    RestClient.enable :caching, :key => "value"
    RestClient.enabled?(:caching).should be_true
    RestClient.components[:caching].should == mock_cache
  end
  
  describe "correctly instantiated" do
    before do
      RestClient.enable :caching
      # @mock_cache = mock('rack-cache singleton')
      # @mock_rack_errors = mock('string io')
      @mock_304_net_http_response = mock('http response', :code => 304, :to_s => "body", :to_hash => {"Date"=>["Mon, 04 Jan 2010 13:42:43 GMT"], 'header1' => ['value1', 'value2']})
      # Rack::Cache.stub!(:new).and_return(@mock_cache)
      @env = {
        'REQUEST_METHOD' => 'GET',
        "SCRIPT_NAME" => '/some/cacheable',
        "PATH_INFO" => '/resource',
        "QUERY_STRING" => 'q1=a&q2=b',
        "SERVER_NAME" => 'domain.tld',
        "SERVER_PORT" => '8888',
        "rack.version" => Rack::VERSION,
        "rack.run_once" => false,
        "rack.multithread" => true,
        "rack.multiprocess" => true,
        "rack.url_scheme" => "http",
        "rack.input" => StringIO.new,
        "rack.errors" => STDOUT
      }
    end
    
    it "should pass through the cache [using RestClient::Resource instance methods]" do
      resource = RestClient::Resource.new('http://domain.tld:8888/some/cacheable/resource?q1=a&q2=b')
      RestClient.components[:caching].should_receive(:call).with( 
        hash_including( {'HTTP_ADDITIONAL_HEADER' => 'whatever', "cacheability.args"=>{:url=>"http://domain.tld:8888/some/cacheable/resource?q1=a&q2=b", :method=>:get, :headers=>{:additional_header=>"whatever"}}}) 
      ).and_return([200, {"Content-Type" => "text/plain"}, "response body"])
      response = resource.get(:additional_header => 'whatever')
      response.should be_a(RestClient::Response)
      response.code.should == 200
      response.headers.should == {:content_type=>"text/plain", :content_length=>"13"}
      response.to_s.should == "response body"
    end
    
    it "should pass through the cache [using RestClient class methods]" do
      RestClient.components[:caching].should_receive(:call).with( 
        hash_including( {'HTTP_ADDITIONAL_HEADER' => 'whatever', "cacheability.args"=>{:url=>"http://domain.tld:8888/some/cacheable/resource?q1=a&q2=b", :method=>:get, :headers=>{:additional_header=>"whatever"}}}) 
      ).and_return([200, {"Content-Type" => "text/plain"}, "response body"])
      response = RestClient.get('http://domain.tld:8888/some/cacheable/resource?q1=a&q2=b', :additional_header => 'whatever')
      response.should be_a(RestClient::Response)
      response.code.should == 200
      response.headers.should == {:content_type=>"text/plain", :content_length=>"13"}
      response.to_s.should == "response body"
    end
  
    it "should call the backend (bypassing the cache) if the requested resource is not in the cache" do
      RestClient::Request.should_receive(:original_execute).with(
        :headers => {:additional_header => 'whatever'}, 
        :method => :get, 
        :url => 'http://domain.tld:8888/some/cacheable/resource'
      ).and_return(mock('rest-client response', :headers => {:content_type => "text/plain, */*", :date => "Mon, 04 Jan 2010 13:37:18 GMT"}, :code => 200, :to_s => 'body'))
      status, header, body = Rack::Lint.new(RestClient.components[:caching]).call(@env.merge(
        'cacheability.args' => {:headers => {:additional_header => 'whatever'}, :method => :get, :url => 'http://domain.tld:8888/some/cacheable/resource'}
      ))
      status.should == 200
      header.should == {"content-type"=>"text/plain, */*", "X-Rack-Cache"=>"miss", "date"=>"Mon, 04 Jan 2010 13:37:18 GMT"}
      content = ""
      body.each{|part| content << part}
      content.should == "body"
    end
    
    it "should return a 304 not modified response if the call to the backend returned a 304 not modified response" do
      RestClient::Request.should_receive(:original_execute).with(
        :headers => {:additional_header => 'whatever'}, 
        :method => :get, 
        :url => 'http://domain.tld:8888/some/cacheable/resource'
      ).and_raise(RestClient::NotModified.new(@mock_304_net_http_response))
      status, header, body = Rack::Lint.new(RestClient.components[:caching]).call(@env.merge(
        'cacheability.args' => {:headers => {:additional_header => 'whatever'}, :method => :get, :url => 'http://domain.tld:8888/some/cacheable/resource'}
      ))
      status.should == 304
      header.should == {"X-Rack-Cache"=>"miss", "date"=>"Mon, 04 Jan 2010 13:42:43 GMT", "header1"=>"value1"} # restclient only returns the first member of each header
      content = ""
      body.each{|part| content<<part}
      content.should == "body"
    end
  end
end
