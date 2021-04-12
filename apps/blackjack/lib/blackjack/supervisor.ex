defmodule Blackjack.Supervisor do
    use Supervisor

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, :ok, opts)
    end

    @impl true
    def init(:ok) do
        children = [
            {DynamicSupervisor, name: Blackjack.GameSupervisor, strategy: :one_for_one},
            {Blackjack.Registry, name: Blackjack.Registry}
        ]

        Supervisor.init(children, strategy: :one_for_all)
    end
end