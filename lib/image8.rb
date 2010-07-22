require "uri"
require "sinatra/async"
require "em-synchrony"
require "em-synchrony/em-http"
require "fiber"
require "json"
require "RMagick"

class Image8 < Sinatra::Base
  set    :couchdb, "http://127.0.0.1:5984/image8"
  enable :raise_errors

  register Sinatra::Async

  aget %r[/(resize|crop|max)/([0-9x]+)/(.*)] do |action, format, uri|
    EM.synchrony do
      puts "uri: #{uri.inspect} - #{uri.class}"

      if uri.strip.empty?
        status 404
        body "No such image."
      else
        # This is retarded.
        uri = append_query_string(uri)
        doc = doc_uri(uri, format, action)

        expires 31_536_000 # 1 year
        request = EM::HttpRequest.new(doc).get(:timeout => 5)
        if request.response_header.status == 200
          puts "Serving straight from cache.."
          content_type request.response_header["CONTENT_TYPE"]
          body         request.response
        else
          original, rev = download_original(uri)
          image         = transform_image(original, action, format)

          http = EM::HttpRequest.new "#{doc}?rev=#{rev}"
          http.aput(
            :head   => {'Content-Type' => image.mime_type},
            :body   => image.to_blob,
            :params => {:rev => rev}
          )
          content_type image.mime_type
          body         image.to_blob
        end
      end
    end
  end

  def append_query_string uri
    if !request.query_string.empty?
      uri += "?#{request.query_string}"
    end
    uri
  end

  def doc_id uri
    uri = URI.encode(uri)
    uri.gsub! "/", "%2F"
    uri
  end

  def doc_uri uri, format=nil, action=nil
    format = "#{action}/#{format}" if action
    [settings.couchdb, doc_id(uri), format].compact.join("/")
  end

  def download_original uri
    cache = EM::HttpRequest.new doc_uri(uri, "full")
    request = cache.get

    if request.response_header.status == 200
      puts "Serving original from cache.."
      blob = request.response
      rev  = request.response_header["ETAG"][1..-2]
    else
      puts "Downloading original.."
      original = EM::HttpRequest.new(uri).get
      request = cache.put(
        :head => {'Content-Type' => original.response_header["CONTENT_TYPE"]},
        :body => original.response
      )
      blob = original.response
      rev  = JSON.parse(request.response)["rev"]
    end

    [blob, rev]
  end

  def format_response request
    rev  = etag[1..-2]
    [blob, rev]
  end

  def transform_image blob, action, format
    puts "#{action} image.."
    image = Magick::Image.from_blob(blob).first
    case action
    when "resize" then
      image.change_geometry!(format) {|width, height|
        image.resize! width, height
      }
    when "crop" then
      width, height = format.split("x").map {|x| x.to_i}
      image.resize_to_fill! width, height
    when "max" then
      width, height = format.split("x").map {|x| x.to_i}
      actual_width = image.rows
      actual_height = image.columns
      
      if( actual_width > width || actual_height > height )
        image.change_geometry!(format) {|width, height|
          image.resize! width, height
        }
      end
    end
    image
  end
end
