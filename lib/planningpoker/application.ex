defmodule Planningpoker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PlanningpokerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Planningpoker.PubSub},
      # Start the Endpoint (http/https)
      PlanningpokerWeb.Endpoint,
      # Start a worker by calling: Planningpoker.Worker.start_link(arg)
      # {Planningpoker.Worker, arg}
      PlanningpokerWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Planningpoker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PlanningpokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
