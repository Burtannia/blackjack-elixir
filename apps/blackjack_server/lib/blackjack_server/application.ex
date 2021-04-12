defmodule BlackjackServer.Application do
    use Application

    @impl true
    def start(_type, _args) do
        port = String.to_integer(System.get_env("PORT") || "4040")

        children = [
            {Task.Supervisor, name: BlackjackServer.TaskSupervisor},
            {Task, fn -> BlackjackServer.accept(port) end}
            |> Supervisor.child_spec(restart: :permanent)
        ]

        opts = [strategy: :one_for_one, name: BlackjackServer.Supervisor]
        Supervisor.start_link(children, opts)
    end
end
