defmodule Blackjack.Registry do
    alias Blackjack.Game, as: Game
    import Maybe

    use GenServer

    # Client API

    def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    def new_game(registry, g_name) do
        GenServer.call(registry, {:new_game, g_name})
    end

    def get_game(registry, g_name) do
        GenServer.call(registry, {:get_game, g_name})
    end

    def end_game(registry, g_name) do
        GenServer.call(registry, {:end_game, g_name})
    end

    # Server Callbacks

    @impl true
    def init(:ok) do
        {:ok, {%{}, %{}}}
    end

    @impl true
    def handle_call({:new_game, g_name}, _from, {games, refs}) do
        case Map.fetch(games, g_name) do
            {:ok, pid} ->
                {:reply, pid, {games, refs}}
            :error ->
                {:ok, pid} = DynamicSupervisor.start_child(Blackjack.GameSupervisor, Blackjack.Game)
                ref = Process.monitor(pid)
                new_refs = Map.put(refs, ref, g_name)
                new_games = Map.put(games, g_name, pid)
                {:reply, pid, {new_games, new_refs}}
        end
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
        # but I don't see a way to efficiently acquire the ref in order to delete it.
        # maybe we should use a "dummy" call here to force the :DOWN message to be handled before this returns?
        {:reply, mgame, state}
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