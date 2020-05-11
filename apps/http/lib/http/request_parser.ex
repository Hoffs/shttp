defmodule Http.RequestParser do
  alias Http.Request
  @crlf "\r\n"

  @spec parse(String.t()) :: %Request{}
  def parse(content) do
    {content, %Request{}}
    |> parse_start
    |> parse_headers
    |> parse_body
    |> post_parse_uri_query
  end

  defp parse_start({content, parsed}) do
    [line | rest] = String.split(content, @crlf, parts: 2)
    parse_request_line({line, Enum.at(rest, 0), parsed})
  end

  defp parse_request_line({"", rest, parsed}) do
    parse_start({rest, parsed})
  end

  defp parse_request_line({line, rest, parsed}) do
    request_split = String.split(line, " ")

    parsed =
      parsed
      |> Map.put(:method, Enum.at(request_split, 0))
      |> Map.put(:uri, Enum.at(request_split, 1))
      |> Map.put(:version, Enum.at(request_split, 2))

    {rest, parsed}
  end

  defp parse_headers({content, parsed}) do
    [line | rest] = String.split(content, @crlf, parts: 2)

    parse_header_line({line, Enum.at(rest, 0), parsed})
  end

  defp parse_header_line({"", rest, parsed}) do
    {rest, parsed}
  end

  defp parse_header_line({line, rest, parsed}) do
    [key, values] = String.split(line, ":", parts: 2)

    parsed = Map.update!(parsed, :headers, &Map.put(&1, String.trim(key), String.trim(values)))

    parse_headers({rest, parsed})
  end

  defp parse_body({content, parsed}) do
    Map.put(parsed, :body, content)
  end

  defp post_parse_uri_query(request) do
    [_ | query] = String.split(request.uri, "?", parts: 2)
    q = parse_uri_query(%{}, Enum.at(query, 0))
    %{request | query: q}
  end

  defp parse_uri_query(parsed, nil) do
    parsed
  end

  defp parse_uri_query(parsed, "") do
    parsed
  end

  defp parse_uri_query(parsed, query_part) do
    [kv | query_part] = String.split(query_part, "&", parts: 2)
    [key | value] = String.split(kv, "=", parts: 2)
    parsed = if key != nil and value != nil and String.length(key) > 0 do
      Map.put(parsed, key, Enum.at(value, 0))
    end

    parse_uri_query(parsed, Enum.at(query_part, 0))
  end
end
