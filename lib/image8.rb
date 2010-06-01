require "uri"
require "sinatra/async"
require "em-http"
require "RMagick"

class Image8 < Sinatra::Base
  set    :couchdb, "http://127.0.0.1:5984/image8"
  enable :raise_errors

  register Sinatra::Async

  aget %r|/([0-9x]+)/(.*)| do |format, uri|
    # This is retarded.
    if !request.query_string.empty?
      uri += "?#{request.query_string}"
    end

    doc_id   = encode_uri("#{format}/#{uri}")
    doc_uri  = settings.couchdb + "/#{doc_id}/image"
    doc_http = EventMachine::HttpRequest.new(doc_uri)

    request = doc_http.get(:timeout => 5)
    request.callback {
      expires 31_536_000 # 1 year
      if request.response_header.status == 200
        content_type request.response_header["CONTENT_TYPE"]
        body         request.response
      else
        resize_image(uri, format) {|img|
          doc_http.put(
            :head => {'Content-Type' => img.mime_type},
            :body => img.to_blob
          )
          content_type img.mime_type
          body         img.to_blob
        }
      end
    }
  end

  def encode_uri uri
    uri = URI.encode(uri)
    uri.gsub! "/", "%2F"
    uri
  end

  def resize_image uri, format, &block
    request = EventMachine::HttpRequest.new(uri).get 
    request.callback {
      EM.defer {
        img = Magick::Image.from_blob(request.response).first
        img.change_geometry!(format) {|width, height|
          img.resize! width, height
        }
        EM.next_tick {
          block.call(img) if block
        }
      }
    }
  end
end
