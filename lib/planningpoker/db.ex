defmodule Planningpoker.Db do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(:users, [:named_table, :public])
    {:ok, %{}}
  end

  def save_name(user, name) do
    Logger.debug("Storing user name (#{user} -> #{name})")
    :ets.insert(:users, {user, name})
  end

  def get_users(keys) do
    :ets.select(:users, (for key <- keys, do: {{key, :_}, [], [:"$_"]}))
  end
end
