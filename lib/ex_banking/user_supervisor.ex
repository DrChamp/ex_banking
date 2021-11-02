defmodule ExBanking.UserSupervisor do
  @moduledoc """
  This is dynamic supervisor which will create user process dynamically
  """

  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 10, max_seconds: 5)
  end

  def new_user(user) do
    child_spec = {ExBanking.User, user}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
