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

    doc_id   = encode_uri(uri)
    doc_uri  = settings.couchdb + "/#{doc_id}"
    doc_http = EventMachine::HttpRequest.new(doc_uri + "/" + format)

    request = doc_http.get(:timeout => 5)
    request.callback {
      expires 31_536_000 # 1 year
      if request.response_header.status == 200
        p "Serving straight from cache.."
        content_type request.response_header["CONTENT_TYPE"]
        body         request.response
      else
        download_original(uri, doc_uri) {|blob|
          resize_image(blob, format) {|img|
            doc_http.put(
              :head => {'Content-Type' => img.mime_type},
              :body => img.to_blob
            )
            content_type img.mime_type
            body         img.to_blob
          }
        }
      end
    }
  end

  def encode_uri uri
    uri = URI.encode(uri)
    uri.gsub! "/", "%2F"
    uri
  end

  def download_original uri, doc_uri
    cache = EventMachine::HttpRequest.new(doc_uri + "/full")
    request = cache.get
    request.callback {
      if request.response_header.status == 200
        p "Serving original from cache.."
        yield request.response if block_given?
      else
        p "Downloading original.."
        original = EventMachine::HttpRequest.new(uri).get
        original.callback {
          req = cache.put(
            :head => {'Content-Type' => original.response_header["CONTENT_TYPE"]},
            :body => original.response
          )
          req.callback { yield original.response if block_given? }
        }
      end
    }
  end

  def resize_image blob, format, &block
    p "Resizing image.."
    t1 = Time.now
    img = Magick::Image.from_blob(blob).first
    img.change_geometry!(format) {|width, height|
      img.resize! width, height
    }
    t2 = Time.now
    p t2 - t1
    block.call(img) if block
  end
end
