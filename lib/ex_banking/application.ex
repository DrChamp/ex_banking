defmodule ExBanking.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      ExBanking.UserSupervisor,
      {Registry, keys: :unique, name: Registry.Users}
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
