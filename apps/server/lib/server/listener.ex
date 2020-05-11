defmodule Server.Listener do
  use Server.Router
  alias Server.RequestCtx
  alias Http.Response
  require Logger

  @doc """
  Adds listen entry point for listening
  to connections.
  """
  defmacro __using__(_opts) do
    quote do
      require Logger
      import Server.Listener

      def listen(port) do
        {:ok, socket} =
          :gen_tcp.listen(
            port,
            [:binary, packet: :raw, active: false, reuseaddr: true]
          )

        Logger.info("Accepting connections on port #{port}")
        Logger.info("Working directory: #{File.cwd!()}")
        connection_acceptor(socket)
      end
    end
  end

  @doc """
  Placed at the end of request pipeline configuration
  which adds a function for handling connections with
  configured routes.
  """
  defmacro end_pipeline(supervisor) do
    quote do
      defp connection_acceptor(socket) do
        routes = get_routes()
        Logger.debug("Loaded routes: #{Kernel.inspect(routes)}")

        {:ok, client_socket} = :gen_tcp.accept(socket)

        {:ok, pid} =
          Task.Supervisor.start_child(unquote(supervisor), fn -> Server.Listener.serve(client_socket, routes) end)

        :ok = :gen_tcp.controlling_process(client_socket, pid)
        connection_acceptor(socket)
      end
    end
  end

  @doc """
  Reads request from the socket and tries
  to invoke appropriate route from given
  routes. Should not be used directly.
  """
  def serve(socket, routes) do
    parsed = read_request(socket)

    ctx = %RequestCtx{request: parsed, response: %Response{}}

    invoke_route(ctx, socket, routes)
    |> write_response(socket)

    :gen_tcp.close(socket)
  end

  defp read_request(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    Logger.debug(data)
    data
    |> Http.RequestParser.parse()
  end

  defp write_response(context, socket) do
    res = Response.build(context[:response])
    Logger.debug(res)
    :gen_tcp.send(socket, res)
    socket
  end
end
