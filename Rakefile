require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "cacheability"
    s.summary = %Q{A gem that makes client-side caching of HTTP requests a no-brainer. Drop-in adapter for the rest-client gem with a single line: RestClient.enable(:caching) ! Supports heap, file and memcache storage, and cache invalidation on non-GET requests.}
    s.email = "cyril.rohr@gmail.com"
    s.homepage = "http://github.com/crohr/cacheability"
    s.description = "Transparent caching for your HTTP requests (heap, file, memcache). Cache invalidation on non-GET requests is supported. Built-in support for RestClient. Built upon Rack::Cache."
    s.authors = ["Cyril Rohr"]
    s.add_dependency "rack-cache", ">= 0.5.0"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'cacheability'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib' << 'spec'
  t.spec_files = FileList['spec/**/*_spec.rb']
end


task :default => :spec
