defmodule BlackjackServer.Command do
    alias Blackjack.Registry, as: Registry
    alias Blackjack.Game, as: Game
    import Maybe, only: [fmap_maybe: 2, bind_maybe: 2]

    def parse(line) do
        case String.split(line) do
            ["NEW", game] -> {:ok, {:new, game}}
            ["TABLE", game] -> {:ok, {:table, game}}
            ["END", game] -> {:ok, {:end, game}}

            ["DEAL", player, game] -> {:ok, {:deal, player, game}}
            ["HIT", player, game] -> {:ok, {:hit, player, game}}
            ["STICK", player, game] -> {:ok, {:stick, player, game}}
            ["HAND", player, game] -> {:ok, {:hand, player, game}}
            ["SCORE", player, game] -> {:ok, {:score, player, game}}

            _ -> {:error, :unknown_command}
        end
    end

    def run({:new, game}) do
        Registry.new_game(Registry, game)
        {:ok, "OK\r\n"}
    end

    def run({:table, game}) do
        fmap(game, &Game.table(&1))
    end

    def run({:end, game}) do
        Registry.end_game(Registry, game)
        {:ok, "OK\r\n"}
    end

    def run({:deal, player, game}) do
        fmap(game, &Game.deal(&1, player))
    end

    def run({:hit, player, game}) do
        fmap(game, &Game.hit(&1, player))
    end

    def run({:stick, player, game}) do
        fmap(game, &Game.stick(&1, player))
    end

    def run({:hand, player, game}) do
        bind(game, &Game.hand(&1, player))
    end

    def run({:score, player, game}) do
        bind(game, &Game.score(&1, player))
    end

    defp fmap(game, f) do
        Registry.get_game(Registry, game)
        |> fmap_maybe(f)
    end

    defp bind(game, f) do
        Registry.get_game(Registry, game)
        |> bind_maybe(f)
    end

end