defmodule Http.ResponseBuilder do
  alias Http.Response
  @crlf "\r\n"

  @doc """
  Creates intial response map.

  ## Examples

      iex> Http.ResponseBuilder.new(200, "OK")
      %Http.Response{:version => "HTTP/1.1", :status_code => "200", :reason_phrase => "OK", :headers => %{}, content: nil}

      iex> Http.ResponseBuilder.new(500, "Internal Server Error")
      %Http.Response{:version => "HTTP/1.1", :status_code => "500", :reason_phrase => "Internal Server Error", :headers => %{}, content: nil}
  """
  def new(status_code, reason_phrase) do
    %Response{:status_code => to_string(status_code), :reason_phrase => reason_phrase, :headers => %{}}
  end

  @doc """
  Adds header to the response.

  ## Examples

      iex> Http.ResponseBuilder.add_header(%{:headers => %{}}, "Accept", "application\\json")
      %{:headers => %{"accept" => ["application\\json"]}}

      iex> Http.ResponseBuilder.add_header(%{:headers => %{"accept" => ["application\\json"]}}, "Accept", "xml")
      %{:headers => %{"accept" => ["application\\json", "xml"]}}

      iex> Http.ResponseBuilder.add_header(%{:headers => %{"accept" => ["application\\json"]}}, "Content-Type", "xml")
      %{:headers => %{"accept" => ["application\\json"], "content-type" => ["xml"]}}
  """
  def add_header(response, key, value) do
    key = String.downcase(key)
    headers = response[:headers]
      |> Map.put_new(key, [])
      |> Map.update!(key, fn curr -> curr ++ [value] end)
    Map.put(response, :headers, headers)
  end

  @doc """
  Adds content to the response.

  ## Examples

      iex> Http.ResponseBuilder.add_content(%{:headers => %{}}, "example content")
      %{:headers => %{}, :content => "example content"}
  """
  def add_content(response, value) do
    Map.put(response, :content, value)
  end

  @doc ~S"""
  Builds response to a IO list.

  ## Examples

      iex>  Http.ResponseBuilder.build(%{
      ...>  :version => "HTTP/1.1",
      ...>  :status_code => "200",
      ...>  :reason_phrase => "OK",
      ...>  :headers => %{"accept" => ["text"]},
      ...>  :content => "Example content"})
      [["HTTP/1.1", " ", "200", " ", "OK", "\r\n"], [["Accept", ": ", "text", "\r\n"]], "\r\n", "Example content"]
  """
  def build(response) do
    res_list = [response[:version], " ", response[:status_code], " ", response[:reason_phrase], @crlf]

    headers_text = Enum.map(response[:headers], fn ({header_key, header_value}) ->
      [String.capitalize(header_key), ": ", Enum.join(header_value, ", "), @crlf]
    end)

    [res_list, headers_text, @crlf, response[:content]]
  end
end
