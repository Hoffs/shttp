defmodule Server.Route do
  @enforce_keys [:method, :path, :function, :path_parts]
  defstruct [:method, :path, :function, :path_parts]

  def new(method, path, function) do
    if not String.starts_with?(path, "/") and not path == "*" do
      raise ArgumentError, message: "path should start with /"
    end

    parts = get_parts(path)
    %Server.Route{method: method, path: path, function: function, path_parts: parts}
  end

  @doc """
  Splits route into part array.

  iex> Server.Route.get_parts("/some/new/:id/route?some=var&and=1")
  ["some", "new", ":id", "route"]
  """
  def get_parts(uri) do
    String.split(uri, "?", parts: 2)
    |> List.first
    |> String.split("/")
    |> Enum.filter(fn part -> String.length(part) > 0 end)
  end

  @doc """
  Tries match provided uri to route. Match is considered true
  when the parts are identical or the mismatched parts are path
  variables.

  iex> Server.Route.matches(Server.Route.new("GET", "/user/:id/stats", nil), Server.Route.get_parts("/user/1/stats?some=var"))
  true
  iex> Server.Route.matches(Server.Route.new("GET", "/user/:id/stats", nil), Server.Route.get_parts("/user/1/status"))
  false
  iex> Server.Route.matches(Server.Route.new("GET", "/user/:id/stats", nil), Server.Route.get_parts("/stats/1/user"))
  false
  """
  def matches(route, uri_parts) do
    matches_parts(route.path_parts, uri_parts)
  end

  defp matches_parts([], []) do
    true
  end

  defp matches_parts(_route_parts, []) do
    false
  end

  defp matches_parts([], _uri_parts) do
    false
  end

  defp matches_parts(route_parts, uri_parts) do
    [route_part | route_parts] = route_parts
    [uri_part | uri_parts] = uri_parts
    case String.starts_with?(route_part, ":") or route_part == uri_part  do
      true -> matches_parts(route_parts, uri_parts)
      false -> false
    end
  end

  @doc """
  Parses uri parts to a map based on
  route path variables. If route has no variables
  empty map is returned.

  iex> Server.Route.parse_vars(Server.Route.new("GET", "/user/:id/stats", nil), Server.Route.get_parts("/user/5/stats"))
  %{":id" => "5"}
  iex> Server.Route.parse_vars(Server.Route.new("GET", "/user/:id/:action", nil), Server.Route.get_parts("/user/5/delete"))
  %{":id" => "5", ":action" => "delete"}
  """
  def parse_vars(route, uri_parts) do
    if String.contains?(route.path, "/:") do
      Enum.reduce(Enum.with_index(route.path_parts), %{}, fn {part, idx}, vars ->
        case String.starts_with?(part, ":") do
          true -> Map.put(vars, part, Enum.at(uri_parts, idx))
          false -> vars
        end
      end)
    else
        %{}
    end
  end
end
