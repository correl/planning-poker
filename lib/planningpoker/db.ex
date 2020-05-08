defmodule Planningpoker.Db do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(:users, [:named_table, :public])
    :ets.new(:votes, [:named_table, :public])
    {:ok, %{}}
  end

  def save_name(user, name) do
    Logger.debug("Storing user name (#{user} -> #{name})")
    :ets.insert(:users, {user, name})
  end

  def save_vote(user, room, value) do
    Logger.debug("Storing vote of #{value} for player #{user} in room #{room}")
    :ets.insert(:votes, {{user, room}, value})
  end

  def get_users(keys) do
    match = for key <- keys do
      {{key, :_}, [], [:"$_"]}
    end
    Logger.debug("Getting users: #{inspect match}")
    :ets.select(:users, match)
  end

  def get_votes(users, room) do
    match = for user <- users do
      {{{user, room}, :_}, [], [:"$_"]}
    end
    Logger.debug("Getting votes: #{inspect match}")
    :ets.select(:votes, match)
  end
end
