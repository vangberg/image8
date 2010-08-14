require "test/helpers"

class TestResize < Test::Unit::TestCase
  def app
    Image8.new
  end

  def setup
    `curl -s -X DELETE http://127.0.0.1:5984/image8`
    `curl -s -X PUT http://127.0.0.1:5984/image8`
  end

  def test_resize
    get "/resize/200x400/http://localhost:8078/fixtures/matador.jpg"

    assert_async
    em_async_continue
    assert last_response.ok?

    image = Magick::Image.from_blob(last_response.body).first
    assert_equal 200, image.columns
    assert_equal 133, image.rows
  end

  def test_crop
    get "/crop/200x400/http://localhost:8078/fixtures/matador.jpg"

    assert_async
    em_async_continue
    assert last_response.ok?

    image = Magick::Image.from_blob(last_response.body).first
    assert_equal 200, image.columns
    assert_equal 400, image.rows
  end

  def test_max_with_smaller_image
    get "/max/1500x1500/http://localhost:8078/fixtures/matador.jpg"

    assert_async
    em_async_continue
    assert last_response.ok?

    image = Magick::Image.from_blob(last_response.body).first
    assert_equal 1024, image.columns
    assert_equal 683, image.rows
  end

  def test_max_with_larger_image
    get "/max/300x300/http://localhost:8078/fixtures/matador.jpg"

    assert_async
    em_async_continue
    assert last_response.ok?

    image = Magick::Image.from_blob(last_response.body).first
    assert_equal 300, image.columns
    assert_equal 200, image.rows
  end

  def test_image_with_whitespace_in_name
    get "/crop/200x400/http://localhost:8078/fixtures/white%20space.jpg"

    assert_async
    em_async_continue
    assert last_response.ok?

    image = Magick::Image.from_blob(last_response.body).first
    assert_equal 200, image.columns
    assert_equal 400, image.rows
  end
end
