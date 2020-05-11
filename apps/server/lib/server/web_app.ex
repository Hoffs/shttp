defmodule Server.WebApp do
  use Server.Listener
  use Server.Router
  import Server.RequestHandler
  alias Http.Response

  def handle_hello_dyn(_socket, context) do
    response =
      %Response{status_code: "200", reason_phrase: "OK"}
      |> Response.add_content("Echo back from '#{context.path_vars[":id"]}' at dynamic #{context.request.uri} \n" <> Kernel.inspect(context))
    %{context | response: response}
  end

  def handle_hello_static(_socket, context) do
    response =
      %Response{status_code: "200", reason_phrase: "OK"}
      |> Response.add_content("Echo back from static #{context.request.uri} \n" <> Kernel.inspect(context))
    %{context | response: response}
  end

  def echo_request(_socket, context) do
    %{context | response: %Response{status_code: "200", reason_phrase: "OK"}
    |> Response.add_content(Kernel.inspect(context))}
  end

  handle_with("GET", "/hello/:id", &Server.WebApp.handle_hello_dyn/2)
  handle_with("GET", "/hello/static", &Server.WebApp.handle_hello_static/2)
  handle_with("GET", "/test", &Server.TestHandler.handle_request/2)

  # Fallback handler that tries to search for files.
  handle_with("GET", &Server.FileHandler.handle_request/2)

  handle_with("GET", "/echo", &Server.WebApp.echo_request/2)
  handle_with("OPTIONS", "/echo", &Server.WebApp.echo_request/2)
  handle_with("POST", "/echo", &Server.WebApp.echo_request/2)
  handle_with("HEAD", "/echo", &Server.WebApp.echo_request/2)

  end_pipeline Server.TaskSupervisor
end
