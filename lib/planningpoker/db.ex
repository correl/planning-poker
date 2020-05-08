defmodule Planningpoker.Db do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(:players, [:named_table, :public])
    :ets.new(:votes, [:named_table, :public])
    {:ok, %{}}
  end

  def save_player(player, room, name) do
    :ets.insert(:players, {{player, room}, name})
  end

  def save_vote(player, room, value) do
    :ets.insert(:votes, {{player, room}, value})
  end


  def get_votes(players, room) do
    match = for player <- players do
      {{{player, room}, :_}, [], [:"$_"]}
    end
    :ets.select(:votes, match)
  end

  def get_players(players, room) do
    match = for player <- players do
      {{{player, room}, :_}, [], [:"$_"]}
    end
    :ets.select(:players, match)
  end
end
