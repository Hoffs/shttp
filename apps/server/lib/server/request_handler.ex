defmodule Server.RequestHandler do
  @callback handle_request(:gen_tcp.socket(), Server.RequestCtx.t()) :: Server.RequestCtx.t()

  @doc """
  Registers handler with specified method and uri.
  """
  defmacro handle_with(method, uri, handler_func) do
    quote do
      Module.put_attribute(unquote(__CALLER__.module), :route, Server.Route.new(unquote(method), unquote(uri), unquote(handler_func)))
    end
  end

  @doc """
  Registers handler with specified method and wildcard uri.
  """
  defmacro handle_with(method, handler_func) do
    quote do
      Module.put_attribute(unquote(__CALLER__.module), :route, Server.Route.new(unquote(method), "/*", unquote(handler_func)))
    end
  end
end
