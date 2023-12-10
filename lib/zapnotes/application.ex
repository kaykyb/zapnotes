defmodule Zapnotes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ZapnotesWeb.Telemetry,
      Zapnotes.Repo,
      {Oban, Application.fetch_env!(:zapnotes, Oban)},
      {DNSCluster, query: Application.get_env(:zapnotes, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Zapnotes.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Zapnotes.Finch},
      # Start a worker by calling: Zapnotes.Worker.start_link(arg)
      # {Zapnotes.Worker, arg},
      # Start to serve requests, typically the last entry
      ZapnotesWeb.Endpoint,
      {Redix, name: :redix},
      Zapnotes.ProcessRegistry,
      Zapnotes.Chats.ChatManagerSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Zapnotes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ZapnotesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
