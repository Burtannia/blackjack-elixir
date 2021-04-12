defmodule Blackjack.Game do
    use Agent, restart: :temporary

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
        %Game{deck: Card.inf_deck()}
    end

    defimpl String.Chars, for: Game do
        def to_string(game) do
            "\n" <>
            "Player Scores\n" <>
            "-------------\n" <>
            Game.to_string_scores(game) <>
            "\n" <>
            "Current Hands\n" <>
            "-------------\n" <>
            Game.to_string_hands(game) <>
            "\n"
        end
    end

    @spec to_string_hand([Card.t]) :: String.t
    def to_string_hand(cards) do
        score = cards
            |> Card.calc_score
            |> Card.score_string
        card_string = for c <- cards, into: "", do: " " <> to_string(c)
        String.trim(card_string) <> " #{score}\n"
    end

    @spec to_string_scores(Game.t) :: String.t
    def to_string_scores(game), do: to_string_players(game.scores, &to_string/1)

    @spec to_string_hands(Game.t) :: String.t
    def to_string_hands(game), do: to_string_players(game.hands, &to_string_hand/1)

    @spec to_string_players(%{player => term}, (term -> String.t)) :: String.t
    defp to_string_players(m, f) do
        for {player, x} <- m, into: "" do
            "#{player}: " <> f.(x)
        end
    end

    @spec new_hand(Game.t, player) :: {[Card.t], Game.t}
    def new_hand(game, player) do
        if Map.has_key?(game.hands, player) do
            {:ok, hand} = get_hand(game, player)
            {to_string_hand(hand), game}
        else
            {cards, new_deck} = Card.deal_cards(game.deck, 2)
            hs = Map.put(game.hands, player, cards)
            {cards, %{game | deck: new_deck, hands: hs}}
        end
    end

    @spec get_hand(Game.t, player) :: Maybe.t
    def get_hand(game, player) do
        Map.fetch(game.hands, player)
        |> fmap_maybe(&to_string_hand/1)
    end

    @spec get_score(Game.t, player) :: Maybe.t
    def get_score(game, player) do
        Map.fetch(game.scores, player)
        |> fmap_maybe(&to_string/1)
    end

    @spec hit_hand(Game.t, player) :: {[Card.t], Game.t}
    def hit_hand(game, player) do
        {cards, new_deck} = Card.deal_cards(game.deck, 1)
        hs = Map.update!(game.hands, player, fn xs -> xs ++ cards end) # need to expand this to check if it exists first
        {
            Map.fetch!(hs, player),
            %{game | deck: new_deck, hands: hs}
        }
    end
    
    @spec end_hand(Game.t, player) :: {Score.t, Game.t}
    def end_hand(%{deck: d, scores: ss, hands: hs}, player) do
        {cards, new_hs} = Map.pop!(hs, player) # need to handle this, maybe have entire function return a maybe type?

        score_val = cards
            |> Cards.calc_score
            |> (fn x -> if x > 21, do: 0, else: x end)
            
        score = Map.fetch(ss, player)
            |> fmap_maybe(&Score.update(&1, score_val))
            |> from_maybe(%Score{total_score: score_val, games_played: 1})

        new_ss = Map.put(ss, player, score)
        new_game = %Game{deck: d, scores: new_ss, hands: new_hs}

        {score, new_game}
    end

    # Agent Stuff

    def start_link(_opts) do
        Agent.start_link(&new/0)
    end

    def table(game) do
        Agent.get(game, &to_string(&1))
    end

    def hit(game, player) do
        hand = Agent.get_and_update(game, &hit_hand(&1, player))
        to_string_hand(hand)
    end

    def deal(game, player) do
        hand = Agent.get_and_update(game, &new_hand(&1, player))
        to_string_hand(hand)
    end

    def stick(game, player) do
        score = Agent.get_and_update(game, &end_hand(&1, player))
        to_string(score)
    end

    def hand(game, player) do
        Agent.get(game, &get_hand(&1, player))
    end

    def score(game, player) do
        Agent.get(game, &get_score(&1, player))
    end
end