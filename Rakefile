require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "cacheability"
    s.summary = %Q{A gem that makes client-side caching of HTTP requests a no-brainer. Replace your calls to RestClient::Resource.new with RestClient::CacheableResource.new and the caching is taken care of for you ! Supports heap, file and memcache storage.}
    s.email = "cyril.rohr@irisa.fr"
    s.homepage = "http://github.com/cryx/cacheability"
    s.description = "Transparent caching for your HTTP requests (heap, file, memcache). Built-in support for RestClient. Built upon Rack::Cache."
    s.authors = ["Cyril Rohr"]
    s.add_dependency "rack-cache"
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

Spec::Rake::SpecTask.new(:rcov) do |t|
  t.libs << 'lib' << 'spec'
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  puts "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
end

task :default => :spec
