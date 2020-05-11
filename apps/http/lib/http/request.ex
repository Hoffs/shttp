defmodule Http.Request do
  @behaviour Access

  defstruct uri: "",
            method: "",
            version: "",
            headers: %{},
            query: %{},
            body: ""

  @type t :: %Http.Request{
          uri: String.t(),
          method: String.t(),
          version: String.t(),
          headers: %{},
          query: %{},
          body: String.t()
        }

  defdelegate fetch(term, key), to: Map
  defdelegate get(term, key, default), to: Map
  defdelegate get_and_update(term, key, fun), to: Map
  defdelegate pop(term, key), to: Map
end
