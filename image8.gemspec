Gem::Specification.new do |s|
  s.name     = "image8"
  s.version  = "0.3.7"
  s.date     = "2010-08-14"
  s.summary  = "dynamic image resizing."
  s.email    = "harry@vangberg.name"
  s.homepage = "http://github.com/ichverstehe/image8"
  s.description = "dynamic image resizing."
  s.authors  = ["Harry Vangberg"]
  s.files    = [
    "README",
    "Gemfile",
		"image8.gemspec", 
		"lib/image8.rb",
  ]
  s.add_dependency "sinatra", ">= 1.0"
  s.add_dependency "async_sinatra", ">= 0.2.1"
  s.add_dependency "em-http-request", ">= 0.2.10"
  s.add_dependency "em-synchrony", ">= 0.1.5"
  s.add_dependency "json", ">= 1.2.4"
  s.add_dependency "rmagick", ">= 2.13.1"
end

