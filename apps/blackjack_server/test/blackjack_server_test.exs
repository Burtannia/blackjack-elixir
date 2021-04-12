defmodule BlackjackServerTest do
  use ExUnit.Case
  doctest BlackjackServer

  test "greets the world" do
    assert BlackjackServer.hello() == :world
  end
end
