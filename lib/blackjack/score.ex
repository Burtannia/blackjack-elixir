defmodule Blackjack.Score do
    alias __MODULE__

    @type t :: %Score{
        total_score: integer,
        games_played: integer
    }

    defstruct [total_score: 0, games_played: 0]

    defimpl String.Chars, for: Score do
        def to_string(%{total_score: total, games_played: played}) do
            average = Float.round(total / played, 1)
            "Average score: #{average} Hands Played: #{played}"
        end
    end

    @spec update(Score.t, integer) :: Score.t
    def update(%{total_score: total, games_played: played}, to_add) do
        %Score{total_score: total + to_add, games_played: played + 1}
    end
end