defmodule Blackjack.Registry do
    alias Blackjack.Game, as: Game
    import Maybe

    use GenServer

    # Client API

    def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    # Games

    def new_game(registry, g_name) do
        GenServer.cast(registry, {:new_game, g_name})
    end

    def get_game(registry, g_name) do
        GenServer.call(registry, {:get_game, g_name})
    end

    def end_game(registry, g_name) do
        GenServer.call(registry, {:end_game, g_name})
    end

    # Hands

    def deal(registry, g_name, p_name) do
        GenServer.call(registry, {:deal, g_name, p_name})
    end

    def get_hand(registry, g_name, p_name) do
        GenServer.call(registry, {:get_hand, g_name, p_name})
    end

    def hit(registry, g_name, p_name) do
        GenServer.call(registry, {:hit, g_name, p_name})
    end

    def stick(registry, g_name, p_name) do
        GenServer.call(registry, {:stick, g_name, p_name})
    end

    #Combination of 'new_game' and 'deal' for convenience
    def connect(registry, g_name, p_name) do
        new_game(registry, g_name)
        deal(registry, g_name, p_name)
    end

    # Server Callbacks

    @impl true
    def init(:ok) do
        {:ok, {%{}, %{}}}
    end

    @impl true
    def handle_call({:get_game, g_name}, _from, state) do
        {games, _} = state
        mgame = Map.fetch(games, g_name)
        {:reply, mgame, state}
    end

    @impl true
    def handle_call({:end_game, g_name}, _from, state) do
        {games, _} = state
        mgame = Map.fetch(games, g_name)
        _ = fmap_maybe(mgame, &Agent.stop(&1))
        # would like to pop games and refs here rather than leaving it to :DOWN
        # but I don't see a way to efficiently acquire the ref in order to delete it
        {:reply, mgame, state}
    end

    @impl true
    def handle_call({:get_hand, g_name, p_name}, _from, state) do
        {games, _} = state
        mgame = Map.fetch(games, g_name)
        mhand = bind_maybe(mgame, &Game.hand(&1, p_name))
        {:reply, mhand, games}
    end

    @impl true
    def handle_call({:deal, g_name, p_name}, _from, state) do
        {games, _} = state
        mgame = Map.fetch(games, g_name)
        mhand = fmap_maybe(mgame, &Game.deal(&1, p_name))
        {:reply, mhand, state}
    end

    @impl true
    def handle_call({:hit, g_name, p_name}, _from, state) do
        {games, _} = state
        mgame = Map.fetch(games, g_name)
        mhand = fmap_maybe(mgame, &Game.hit(&1, p_name))
        {:reply, mhand, state}
    end

    @impl true
    def handle_call({:stick, g_name, p_name}, _from, state) do
        {games, _} = state
        mgame = Map.fetch(games, g_name)
        mscore = fmap_maybe(mgame, &Game.stick(&1, p_name))
        {:reply, mscore, state}
    end

    # change this to call
    @impl true
    def handle_cast({:new_game, g_name}, {games, refs}) do
        if Map.has_key?(games, g_name) do
            {:noreply, {games, refs}}
        else
            {:ok, game} = Blackjack.Game.start_link([])
            new_games = Map.put(games, g_name, game)
            ref = Process.monitor(game)
            new_refs = Map.put(refs, ref, g_name)
            {:noreply, {new_games, new_refs}}
        end
    end

    @impl true
    def handle_info({:DOWN, ref, :process, _pid, _reason}, {games, refs}) do
        {g_name, new_refs} = Map.pop(refs, ref)
        new_games = Map.delete(games, g_name)
        {:noreply, {new_games, new_refs}}
    end

    @impl true
    def handle_info(_msg, state) do
        {:noreply, state}
    end
end