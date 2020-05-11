defmodule SHttp.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        shttp: [
          version: "0.0.1",
          applications: [http: :permanent, server: :permanent]
        ]
      ]
    ]
  end

  defp deps do
    []
  end
end
