defmodule Http.RequestParserTest do
  use ExUnit.Case
  doctest Http.RequestParser

  test "parses http request line" do
    input = "GET / HTTP/1.1\r\nHost: developer.mozilla.org\r\n\r\nBody"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed, :method) == "GET"
    assert Map.get(parsed, :uri) == "/"
    assert Map.get(parsed, :version) == "HTTP/1.1"
  end

  test "parses http uri with query" do
    input = "GET /test?key1=value&key2 HTTP/1.1\r\nHost: developer.mozilla.org\r\n\r\nBody"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed, :method) == "GET"
    assert Map.get(parsed, :uri) == "/test?key1=value&key2"
    assert Map.get(parsed, :version) == "HTTP/1.1"
    assert get_in(parsed[:query], [Access.key("key1")]) == "value"
    assert get_in(parsed[:query], [Access.key("key2")]) == nil
  end

  test "parses http header first line" do
    input = "GET / HTTP/1.1\r\nHost: developer.mozilla.org\r\n\r\nBody"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed[:headers], "Host") == "developer.mozilla.org"
  end

  test "parses http header second line" do
    input = "GET / HTTP/1.1\r\nHost: developer.mozilla.org\r\nAccept: application\\json\r\n\r\nBody"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed[:headers], "Accept") == "application\\json"
  end

  test "parses http body multi line" do
    input = "GET / HTTP/1.1\r\nAccept: application\\json\r\n\r\nBody\r\nSecond\nThird"

    parsed = Http.RequestParser.parse(input)

    assert parsed[:body] == "Body\r\nSecond\nThird"
  end

  test "parses http no body" do
    input = "GET / HTTP/1.1\r\nAccept: application\\json\r\n"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed, :method) == "GET"
    assert Map.get(parsed, :uri) == "/"
    assert Map.get(parsed, :version) == "HTTP/1.1"
    assert Map.get(parsed[:headers], "Accept") == "application\\json"
  end

  test "parses http no headers" do
    input = "GET / HTTP/1.1\r\n"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed, :method) == "GET"
    assert Map.get(parsed, :uri) == "/"
    assert Map.get(parsed, :version) == "HTTP/1.1"
  end

  test "parses http preceeding crlf" do
    input = "\r\nGET / HTTP/1.1\r\n"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed, :method) == "GET"
    assert Map.get(parsed, :uri) == "/"
    assert Map.get(parsed, :version) == "HTTP/1.1"
  end

  test "parses http body multi line no headers" do
    input = "GET / HTTP/1.1\r\n\r\nBody\r\nSecond\nThird"

    parsed = Http.RequestParser.parse(input)

    assert Map.get(parsed, :method) == "GET"
    assert Map.get(parsed, :uri) == "/"
    assert Map.get(parsed, :version) == "HTTP/1.1"
    assert parsed[:body] == "Body\r\nSecond\nThird"
  end
end
