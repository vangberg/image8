Gem::Specification.new do |s|
  s.name     = "image8"
  s.version  = "0.1"
  s.date     = "2010-06-01"
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
  s.add_dependency "async_sinatra", ">= 0.1.5"
  s.add_dependency "em-http-request", ">= 0.2.7"
  s.add_dependency "rmagick", ">= 2.13.1"
end
