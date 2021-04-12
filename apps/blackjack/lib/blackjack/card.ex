defmodule Blackjack.Card do
    alias __MODULE__

    @type suit :: :spades | :hearts | :clubs | :diamonds
    @type rank :: 1..13

    @spec suits() :: [suit] # confused about why this type causes problems
    def suits(), do: [:spades, :hearts, :diamonds, :clubs]

    @spec ranks() :: [rank]
    def ranks(), do:
        for x <- 1..13, do: x

    @type t :: %Card{
        suit: suit,
        rank: rank
    }

    @enforce_keys [:suit, :rank]
    defstruct [:suit, :rank]

    defimpl String.Chars, for: Card do
        def to_string(card) do
            Card.rank_to_string(card.rank)
            <> Card.suit_to_string(card.suit)
        end
    end

    @spec suit_to_string(suit) :: String.t
    def suit_to_string(:spades), do: "\u2660"
    def suit_to_string(:hearts), do: "\u2665"
    def suit_to_string(:diamonds), do: "\u2666"
    def suit_to_string(:clubs), do: "\u2663"

    @spec rank_to_string(rank) :: String.t
    def rank_to_string(1), do: "A"
    def rank_to_string(11), do: "J"
    def rank_to_string(12), do: "Q"
    def rank_to_string(13), do: "K"
    def rank_to_string(n), do: to_string(n)

    @spec is_ace?(Card.t) :: boolean
    def is_ace?(%{suit: _, rank: n}) when n == 1, do: true
    def is_ace?(_), do: false

    @spec card_score(Card.t, boolean) :: integer
    def card_score(%{suit: _, rank: 1}, aces_high?) when aces_high?, do: 11
    def card_score(%{suit: _, rank: n}, _) when n > 10, do: 10
    def card_score(%{suit: _, rank: n}, _), do: n

    @spec mk_card(rank, suit) :: Card.t
    def mk_card(rank, suit), do: %Card{suit: suit, rank: rank}

    @spec inf_deck() :: Enumerable.t # is there a way to make this more specific e.g. Stream.t(Card.t)?
    def inf_deck() do
        Stream.repeatedly(&single_deck/0)
        |> Stream.concat()
    end

    @spec deal_cards(Enumerable.t, integer) :: {[Card.t], Enumerable.t}
    def deal_cards(deck, n) do
        {Enum.take(deck, n), Stream.drop(deck, n)}
    end

    @spec single_deck() :: [Card.t]
    defp single_deck() do
        for rank <- ranks(), suit <- suits() do
            mk_card(rank, suit)
        end |> Enum.shuffle()
    end

    @spec calc_score([Card.t]) :: integer
    def calc_score(cards) do
        Enum.reduce(cards, [0],
            fn c, xs ->
                if is_ace?(c) do
                    for x <- xs, aces_high? <- [true, false], do: x + card_score(c, aces_high?)
                else
                    Enum.map(xs, fn x -> x + card_score(c, false) end)
                end
            end
        ) |>
        Enum.reduce(0,
            fn n, best ->
                if n > best or best > 21 do
                    n
                else
                    best
                end
            end
        )
    end

    @spec score_string(integer) :: String.t
    def score_string(n) when n > 21, do: "(#{n} - BUST!)"
    def score_string(21), do: "(21 - Blackjack!)"
    def score_string(n), do: "(#{n})"

    @spec bound_check(integer) :: integer
    def bound_check(n) do
        if n > 21, do: 0, else: n
    end
end