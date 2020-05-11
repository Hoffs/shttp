defmodule Http.ResponseTest do
  use ExUnit.Case
  doctest Http.Response

  test "builds valid html io list" do
    response =
      %Http.Response{status_code: "200", reason_phrase: "OK"}
      |> Http.Response.set_status("301", "Moved")
      |> Http.Response.add_header("Accept", "xml")
      |> Http.Response.add_header("Accept", "json")
      |> Http.Response.add_header("Content-Type", "binary")
      |> Http.Response.add_content("Example rest content")

    output = Http.Response.build(response)

    assert Enum.join(output) ==
             "HTTP/1.1 301 Moved\r\nAccept: xml, json\r\nContent-type: binary\r\n\r\nExample rest content"
  end
end
