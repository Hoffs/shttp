# SHttp (SimpleHttp)

Simple Http web server/framework implementation
that has static and dynamic routing using macros/dsl.

It is capable of displaying basic Html pages with referenced
CSS/JS/etc files.

Routing with dynamic paths should accomade basic API needs
as well.

## Configuration

Routes can be configured with minimal DSL/macros:

```elixir
handle_with("GET", "/hello/:id", &Server.WebApp.handle_hello_dyn/2)
handle_with("GET", "/hello/static", &Server.WebApp.handle_hello_static/2)
handle_with("GET", "/test", &Server.TestHandler.handle_request/2)
```

Full example/implementation can be seen here: [/apps/server/lib/server/web_app.ex](https://github.com/Hoffs/shttp/blob/master/apps/server/lib/server/web_app.ex)

## Request/Response

Request gets parsed and passed as context to the function along side the
socket:
```text
Echo back from 'dyn' at dynamic /hello/dyn?with=query&data=b
%Server.RequestCtx{
  path_vars: %{":id" => "dyn"},
  request: %Http.Request{
    body: "",
    headers: %{"Accept" => "text/html,a...", ...},
    method: "GET",
    query: %{"data" => "b", "with" => "query"},
    uri: "/hello/dyn?with=query&data=b",
    version: "HTTP/1.1"
  },
  # Filled/updated by handler.
  response: %Http.Response{
    content: nil,
    headers: %{},
    reason_phrase: "",
    status_code: "",
    version: "HTTP/1.1"
  }
}
```
```elixir
def handle_hello_dyn(_socket, context) do
  response =
    %Response{status_code: "200", reason_phrase: "OK"}
    |> Response.add_content("Echo back from '#{context.path_vars[":id"]}' at dynamic #{context.request.uri} \n" <> Kernel.inspect(context))
  %{context | response: response}
end
```

Full example/implementation can be seen here (in this case file handler responsible for serving static content): [/apps/server/lib/server/file_handler.ex](https://github.com/Hoffs/shttp/blob/master/apps/server/lib/server/file_handler.ex)
