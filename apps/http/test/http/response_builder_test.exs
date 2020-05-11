defmodule Http.ResponseBuilderTest do
  use ExUnit.Case
  doctest Http.ResponseBuilder

  test "builds valid html io list" do
    response = Http.ResponseBuilder.new(200, "OK")
      |> Http.ResponseBuilder.add_header("Accept", "xml")
      |> Http.ResponseBuilder.add_header("Accept", "json")
      |> Http.ResponseBuilder.add_header("Content-Type", "binary")
      |> Http.ResponseBuilder.add_content("Example rest content")

    output = Http.ResponseBuilder.build(response)

    assert Enum.join(output)
      == "HTTP/1.1 200 OK\r\nAccept: xml, json\r\nContent-type: binary\r\n\r\nExample rest content"
  end
end
