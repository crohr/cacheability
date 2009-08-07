# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cacheability}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cyril Rohr"]
  s.date = %q{2009-03-31}
  s.description = %q{Transparent caching of HTTP requests, based on rack-cache. Built-in support for RestClient.}
  s.email = %q{cyril.rohr@gmail.com}
  s.files = ["VERSION.yml", "lib/cacheability", "lib/cacheability/restclient.rb", "lib/cacheability.rb", "spec/cacheability_spec.rb", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/cryx/cacheability}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A gem that makes client-side caching of HTTP requests a no-brainer. It is built upon the Rack:Cache gem from Ryan Tomayko. For instance, use RestClient::CacheableResource.new(...) for transparent caching with RestClient.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack-cache>, [">= 0"])
    else
      s.add_dependency(%q<rack-cache>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack-cache>, [">= 0"])
  end
end
