require File.dirname(__FILE__) + '/spec_helper'
require 'restclient'

describe RestClient::CacheableResource do
  require File.dirname(__FILE__) + '/../lib/cacheability/restclient'
  before do
    @cache_options = {:metastore => 'file:/tmp/cache/meta', :entitystore => 'file:/tmp/cache/body'}
  end
  
  it "should instantiate the cache at init" do
    mock_cache = mock('rack-cache instance')    
    Rack::Cache.should_receive(:new).with( 
      RestClient::CacheableResource.new('http://domain.tld:8888/some/cacheable/resource', :cache => @cache_options), 
      @cache_options
    ).and_return(mock_cache)
  end
  
  describe "correctly instantiated" do
    before do
      @mock_cache = mock('rack-cache singleton')
      Rack::Cache.stub!(:new).and_return(@mock_cache)
      @env = {
        'REQUEST_METHOD' => 'GET',
        "SCRIPT_NAME" => '/some/cacheable',
        "PATH_INFO" => '/resource',
        "QUERY_STRING" => 'q1=a&q2=b',
        "SERVER_NAME" => 'domain.tld',
        "SERVER_PORT" => '8888'
      }
      @resource = RestClient::CacheableResource.new('http://domain.tld:8888/some/cacheable/resource', :cache => @cache_options)
    end
    
    it "should pass through the cache" do
      @resource.cache.should_receive(:call).with( hash_including( @env.merge({'HTTP_ADDITIONAL_HEADER' => 'whatever'}) ) )
      @resource['/?q1=a&q2=b'].get(:additional_header => 'whatever')
    end
  
    it "should bypass the cache if pass_through_cache argument is false" do
      @resource = RestClient::CacheableResource.new('http://domain.tld:8888/some/cacheable/resource', :cache => @cache_options)
      @resource.cache.should_not_receive(:call)
      @resource.get({:additional_header => 'whatever'}, false) rescue nil # don't know how to spec the call to super()
    end
  
    it "should call the backend (bypassing the cache) if the requested resource is not in the cache" do
      @resource.should_receive(:get).with({'ADDITIONAL-HEADER' => 'whatever'}, false).and_return(mock('rest-client response', :headers => {}, :code => 200, :to_s => 'body'))
      response = @resource.call(@env.merge({'HTTP_ADDITIONAL_HEADER' => 'whatever'}))
      response.should == [200, {}, "body"]
    end
    
    it "should return a 304 not modified response if the call to the backend returned a 304 not modified response" do
      @resource.should_receive(:get).with({'ADDITIONAL-HEADER' => 'whatever'}, false).and_raise(RestClient::NotModified)
      response = @resource.call(@env.merge({'HTTP_ADDITIONAL_HEADER' => 'whatever'}))
      response.should == [304, {}, ""]
    end
    
    it "should render a RestClient::Response even when the data is coming from the cache" do
      @resource.cache.should_receive(:call).and_return([200, {'ADDITIONAL_HEADER' => 'whatever'}, "body"])
      response = @resource.get({'HTTP_ADDITIONAL_HEADER' => 'whatever'}, true)
      response.should be_is_a(RestClient::Response)
      response.code.should == 200
      response.headers.should == {:ADDITIONAL_HEADER => 'whatever'}
      response.to_s.should == "body"
    end
  end
end
