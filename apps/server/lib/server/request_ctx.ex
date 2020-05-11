defmodule Server.RequestCtx do
  @behaviour Access
  defstruct request: %Http.Request{}, query: %{}, path_vars: %{}, response: %Http.Response{}

  @type t :: %Server.RequestCtx{
          request: Http.Request.t(),
          query: map(),
          path_vars: map(),
          response: Http.Response.t()
        }

  defdelegate fetch(term, key), to: Map
  defdelegate get(term, key, default), to: Map
  defdelegate get_and_update(term, key, fun), to: Map
  defdelegate pop(term, key), to: Map
end
