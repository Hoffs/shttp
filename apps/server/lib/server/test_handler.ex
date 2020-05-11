defmodule Server.TestHandler do
  @behaviour Server.RequestHandler
  alias Http.Response

  def handle_request(_socket, context) do
    test_res = %Response{status_code: "200", reason_phrase: "OK"}
    |> Response.add_content("HI FROM #{Server.TestHandler}\n" <> inspect(context))
    %{context | response: test_res}
  end
end
