defmodule Blackjack.Game do
    alias __MODULE__
    alias Blackjack.Card, as: Card
    alias Blackjack.Score, as: Score
    import Maybe, only: [from_maybe: 2, fmap_maybe: 2]

    @type player :: String.t

    @type t :: %Game{
        deck: Enumerable.t,
        scores: %{player => Score.t},
        hands: %{player => [Card.t]}
    }

    @enforce_keys [:deck]
    defstruct [:deck, scores: %{}, hands: %{}]

    @spec new() :: Game.t
    def new() do
        %Game{deck: Card.deck()}
    end

    defimpl String.Chars, for: Game do
        def to_string(game) do
            "Player Scores:" <>
            Game.to_string_scores(game) <>
            "\n" <>
            "Current Hands:" <>
            Game.to_string_hands(game)
        end
    end

    @spec to_string_hand([Card.t]) :: String.t
    def to_string_hand(cards) do
        score = Card.score_string(Card.calc_score(cards))
        card_string = for c <- cards, into: "", do: " " <> to_string(c)
        String.strip(card_string) <> " #{score}"
    end

    @spec to_string_scores(Game.t) :: String.t
    def to_string_scores(game), do: to_string_players(game.scores, &to_string/1)

    @spec to_string_hands(Game.t) :: String.t
    def to_string_hands(game), do: to_string_players(game.hands, &to_string_hand/1)

    @spec to_string_players(%{player => term}, (term -> String.t)) :: String.t
    defp to_string_players(m, f) do
        for {player, x} <- m, into: "" do
            "\n#{player}: " <> f.(x)
        end
    end

    @spec new_hand(Game.t, player) :: {Game.t, String.t}
    def new_hand(game, player) do
        if Map.has_key?(game.hands, player) do
            {:ok, hand} = get_hand(game, player)
            {game, to_string_hand(hand)}
        else
            cards = Enum.take(game.deck, 2)
            new_deck = Stream.drop(game.deck, 2)
            hs = Map.put(game.hands, player, cards)
            {
                %{game | deck: new_deck, hands: hs},
                to_string_hand(cards)
            }
        end
    end

    @spec get_hand(Game.t, player) :: Maybe.t
    def get_hand(game, player) do
        Map.fetch(game.hands, player)
    end

    @spec hit_hand(Game.t, player) :: {Game.t, String.t}
    def hit_hand(game, player) do
        card = Enum.take(game.deck, 1)
        new_deck = Stream.drop(game.deck, 1)
        hs = Map.update!(game.hands, player, fn xs -> xs ++ card end) # need to expand this to check if it exists first
        { 
            %{game | deck: new_deck, hands: hs},
            to_string_hand(Map.fetch!(hs, player))
        }
    end
    
    @spec end_hand(Game.t, player) :: {Game.t, Score.t}
    def end_hand(%{deck: d, scores: ss, hands: hs}, player) do
        {cards, new_hs} = Map.pop!(hs, player) # need to handle this, maybe have entire function return a maybe type?
        score_raw = Card.calc_score(cards)
        score_val = if score_raw > 21, do: 0, else: score_raw
        mscore = fmap_maybe(Map.fetch(ss, player), &Score.update(&1, score_val))
        score = from_maybe(mscore, %Score{total_score: score_val, games_played: 1})
        new_ss = Map.put(ss, player, score)
        { 
            %Game{deck: d, scores: new_ss, hands: new_hs},
            score
        }  
    end
end