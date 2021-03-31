defmodule Blackjack.Server do
    alias __MODULE__
    alias Blackjack.Game, as: Game
    import Maybe

    use GenServer

    # Client API

    def start_link(opts) do
        GenServer.start_link(Server, :ok, opts)
    end

    # Games

    def new_game(server, g_name) do
        GenServer.cast(server, {:new_game, g_name})
    end

    def get_game(server, g_name) do
        GenServer.call(server, {:get_game, g_name})
    end

    def end_game(server, g_name) do
        GenServer.call(server, {:end_game, g_name})
    end

    # Hands

    def deal(server, g_name, p_name) do
        GenServer.call(server, {:deal, g_name, p_name})
    end

    def get_hand(server, g_name, p_name) do
        GenServer.call(server, {:get_hand, g_name, p_name})
    end

    def hit(server, g_name, p_name) do
        GenServer.call(server, {:hit, g_name, p_name})
    end

    def stick(server, g_name, p_name) do
        GenServer.call(server, {:stick, g_name, p_name})
    end

    # Server Callbacks

    @impl true
    def init(:ok) do
        {:ok, %{}}
    end

    @impl true
    def handle_call({:get_game, g_name}, _from, games) do
        mgame =  Map.fetch(games, g_name)
        {:reply, fmap_maybe(mgame, &to_string(&1)), games}
    end

    @impl true
    def handle_call({:end_game, g_name}, _from, games) do
        mgame = Map.fetch(games, g_name)
        mscore = fmap_maybe(mgame, &Game.to_string_scores(&1))
        {:reply, mscore, Map.delete(games, g_name)} # maybe expand later to collect score from game and update a "global" table
    end

    @impl true
    def handle_call({:get_hand, g_name, p_name}, _from, games) do
        mgame = Map.fetch(games, g_name)
        mhand = bind_maybe(mgame, &Game.get_hand(&1, p_name))
        mhand_string = fmap_maybe(mhand, &Game.to_string_hand(&1))
        {:reply, mhand_string, games}
    end

    @impl true
    def handle_call({:deal, g_name, p_name}, _from, games) do
        mgame = Map.fetch(games, g_name)
        mgh = fmap_maybe(mgame, &Game.new_hand(&1, p_name))
        case mgh do
            {:ok, {new_game, hand}} ->
                {:reply, {:ok, hand}, %{games | g_name => new_game}}
            :error ->
                {:reply, :error, games}
        end
    end

    @impl true
    def handle_call({:hit, g_name, p_name}, _from, games) do
        mgame = Map.fetch(games, g_name)
        mgh = fmap_maybe(mgame, &Game.hit_hand(&1, p_name))
        case mgh do
            {:ok, {new_game, hand}} ->
                {:reply, {:ok, hand}, %{games | g_name => new_game}}
            :error ->
                {:reply, :error, games}
        end
    end

    @impl true
    def handle_call({:stick, g_name, p_name}, _from, games) do
        mgame = Map.fetch(games, g_name)
        mgs = fmap_maybe(mgame, &Game.end_hand(&1, p_name))
        case mgs do
            {:ok, {new_game, score}} ->
                {:reply, {:ok, to_string(score)}, %{games | g_name => new_game}}
            :error ->
                {:reply, :error, games}
        end
    end

    @impl true
    def handle_cast({:new_game, g_name}, games) do
        if Map.has_key?(games, g_name) do
            {:noreply, games}
        else
            {:noreply, Map.put(games, g_name, Game.new())}
        end
    end
end