defmodule Numeri.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NumeriWeb.Telemetry,
      Numeri.Repo,
      {Ecto.Migrator, repos: Application.fetch_env!(:numeri, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:numeri, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Numeri.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Numeri.Finch},
      # Start a worker by calling: Numeri.Worker.start_link(arg)
      # {Numeri.Worker, arg},
      # Start to serve requests, typically the last entry
      NumeriWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :numeri]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Numeri.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NumeriWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
