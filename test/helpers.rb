ENV["RACK_ENV"] = "test"
$:.unshift "lib"
require "test/unit"
require "rack/test"
require "sinatra/async/test"
require "em-spec/test"
require "rmagick"
require "json"
require "image8"

class Test::Unit::TestCase
  include Sinatra::Async::Test::Methods

  def image_from_last_response
    Magick::Image.from_blob(last_response.body).first
  end
end
