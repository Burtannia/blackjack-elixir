defmodule Maybe do
    __MODULE__

    @type t :: {:ok, term} | :error
    # is it possible to replace this with a macro to properly parameterise "term"?

    # not perfect because this can't check whether the term inside
    # the maybe has the same type as the term on the LHS of f.
    @spec fmap_maybe(Maybe.t, (term -> term)) :: Maybe.t
    def fmap_maybe({:ok, x}, f), do: {:ok, f.(x)}
    def fmap_maybe(:error, _), do: :error

    @spec bind_maybe(Maybe.t, (term -> Maybe.t)) :: Maybe.t
    def bind_maybe(:error, _), do: :error
    def bind_maybe({:ok, x}, f), do: f.(x)

    @spec from_maybe(Maybe.t, term) :: term
    def from_maybe(:error, x), do: x
    def from_maybe({:ok, x}, _), do: x
end