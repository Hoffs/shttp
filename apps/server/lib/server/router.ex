defmodule Server.Router do
  require Logger
  defmacro __using__(_opts) do
    quote do
      import Server.Router
      Module.register_attribute(__MODULE__, :route, accumulate: true)
    end
  end

  @doc """
  Gets parsed registered routes.
  """
  defmacro get_routes() do
    quote do
      Server.Router.parse_routes(@route)
    end
  end

  def invoke_route(ctx, socket, routes) do
    Logger.debug("Trying to invoke route for #{ctx.request.uri} from #{Kernel.inspect(routes)}")
    size = Server.Router.get_route_size(ctx.request.uri)
    uri_parts = Server.Route.get_parts(ctx.request.uri)

    matched_routes =
      get_in(routes, [Access.key(ctx.request.method, %{}), Access.key(size, [])])
      |> Enum.filter(&Server.Route.matches(&1, uri_parts))

    matched_route = case Enum.count(matched_routes) do
      0 -> nil
      1 -> List.first(matched_routes)
      2 -> case Enum.filter(matched_routes, &(not String.contains?(&1.path, "/:"))) do
        [route] -> route
        _ -> raise ArgumentError, message: "found 2 routes, but neither of them is static"
      end
      _ -> raise ArgumentError, message: "found more than 2 applicable routes"
    end

    # Match fallback route /* for method
    matched_route = case matched_route do
      nil -> get_in(routes, [Access.key(ctx.request.method, %{}), Access.key(1, [])]) |> Enum.find(nil, &(&1.path == "/*"))
      route -> route
    end

    if matched_route == nil do
      raise "no route found"
    end

    path_vars = Server.Route.parse_vars(matched_route, uri_parts)

    ctx = %{ctx | path_vars: Map.merge(ctx.path_vars, path_vars)}

    Logger.debug("Matched route #{Kernel.inspect(matched_route)} for #{ctx.request.uri}")
    matched_route.function.(socket, ctx)
  end

  @doc """
  Parses :route attributes to a routing dictionary.
  Routes use :key to indicate a route parameter.
  Routing dictionary is based on multiple levels:
  { method: concretePath: { componentCount: [ %Route{} ] }}

  iex> Server.Router.parse_routes([Server.Route.new("GET", "/users/status", nil)])
  %{"GET" => %{ 2 => [%Server.Route{ path: "/users/status", method: "GET", function: nil, path_parts: ["users", "status"] }]}}

  iex> Server.Router.parse_routes([Server.Route.new("GET", "/users/status", nil), Server.Route.new("GET", "/user/:id/stat", nil)])
  %{"GET" => %{ 2 => [%Server.Route{ path: "/users/status", method: "GET", function: nil, path_parts: ["users", "status"] }], 3 => [%Server.Route{ path: "/user/:id/stat", method: "GET", function: nil, path_parts: ["user", ":id", "stat"] }]}}
  """
  def parse_routes(unparsed_routes) when is_list(unparsed_routes) do
    parse_routes(%{}, unparsed_routes)
  end

  def parse_routes(unparsed_routes) when not is_list(unparsed_routes) do
    parse_routes(%{}, [unparsed_routes])
  end

  defp parse_routes(parsed, []) do
    parsed
  end

  defp parse_routes(parsed, unparsed_routes) do
    [route | unparsed_routes] = unparsed_routes
    parts = get_route_size(route.path)

    parsed =
      update_in(
        parsed,
        [Access.key(route.method, %{}), Access.key(parts, [])],
        fn routes -> routes ++ [route] end
      )

    parse_routes(parsed, unparsed_routes)
  end

  @doc """
  Parses route size based on component/path count.

  ## Examples

  iex> Server.Router.get_route_size("/user/:userId/status")
  3
  iex> Server.Router.get_route_size("/user")
  1
  iex> Server.Router.get_route_size("/")
  1
  iex> Server.Router.get_route_size("/api/data/user/:userId")
  4
  """
  def get_route_size(path) do
    if not String.starts_with?(path, "/") do
      raise ArgumentError, message: "path should start with /"
    end

    String.graphemes(path)
    |> Enum.count(fn e -> e == "/" end)
  end
end
