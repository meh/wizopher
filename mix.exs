defmodule Wizopher.Mixfile do
  use Mix.Project

  def project do
    [ app: :wizopher,
      version: "0.0.1",
      elixir: "~> 0.10.2-dev",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:socket],
      mod: { Wizopher, [port: 8080] } ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ { :prairie, github: "meh/prairie" },
      { :httprot, github: "meh/httprot" } ]
  end
end
