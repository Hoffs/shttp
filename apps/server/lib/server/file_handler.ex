defmodule Server.FileHandler do
  require Logger
  alias Http.Response
  @behaviour Server.RequestHandler

  def handle_request(socket, ctx) do
    # TODO: Should prevent path traversal
    Logger.debug("Trying to return file #{ctx.request.uri}")
    file_uri = ctx.request.uri

    content_type =
      cond do
        String.ends_with?(file_uri, ".svg") -> "image/svg+xml"
        true -> "text"
      end

    file_uri =
      if String.starts_with?(file_uri, "/") do
        String.slice(file_uri, 1..-1)
      else
        file_uri
      end

    case File.read(file_uri) do
      {:ok, data} ->
        %{
          ctx
          | response:
              %Response{status_code: "200", reason_phrase: "OK"}
              |> Response.add_header("Content-Type", content_type)
              |> Response.add_content(data)
        }

      {:error, reason} ->
        case String.contains?(file_uri, ".") do
          true ->
            %{
              ctx
              | response:
                  %Response{status_code: "404", reason_phrase: "Not Found"}
                  |> Response.add_content(:file.format_error(reason))
            }

          false ->
            file_uri = file_uri <> ".html"
            mod_request = %{ ctx.request | uri: file_uri }
            mod_ctx = %{ ctx | request: mod_request }
            handle_request(socket, mod_ctx)
        end
    end
  end
end
