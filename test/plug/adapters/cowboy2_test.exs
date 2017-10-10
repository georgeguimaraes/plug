defmodule Plug.Adapters.Cowboy2Test do
  use ExUnit.Case, async: true

  import Plug.Adapters.Cowboy2

  @moduletag :cowboy2

  def init([]) do
    [foo: :bar]
  end

  @dispatch [{:_, [], [
              {:_, [], Plug.Adapters.Cowboy2.Handler, {Plug.Adapters.Cowboy2Test, [foo: :bar]}}
            ]}]

  if function_exported?(Supervisor, :child_spec, 2) do
    test "supports Elixir v1.5 child specs" do
      spec = {Plug.Adapters.Cowboy2, [scheme: :http, plug: __MODULE__, options: [port: 4040]]}
      assert %{id: {:ranch_listener_sup, Plug.Adapters.Cowboy2Test.HTTP},
               modules: [:ranch_listener_sup],
               restart: :permanent,
               shutdown: :infinity,
               start: {:ranch_listener_sup, :start_link, _},
               type: :supervisor} = Supervisor.child_spec(spec, [])
    end
  end

  test "builds args for cowboy dispatch" do
    assert [Plug.Adapters.Cowboy2Test.HTTP,
            [port: 4000, max_connections: 16_384],
            %{env: %{dispatch: @dispatch}}] =
           args(:http, __MODULE__, [], [])
  end

  test "builds args with custom options" do
    assert [Plug.Adapters.Cowboy2Test.HTTP,
            [max_connections: 16_384, port: 3000, other: true],
            %{env: %{dispatch: @dispatch}}] =
           args(:http, __MODULE__, [], [port: 3000, other: true])
  end

  test "builds args with non 2-element tuple options" do
    assert [Plug.Adapters.Cowboy2Test.HTTP,
            [:inet6, {:raw, 1, 2, 3}, max_connections: 16_384, port: 3000, other: true],
            %{env: %{dispatch: @dispatch}}] =
           args(:http, __MODULE__, [], [:inet6, {:raw, 1, 2, 3}, port: 3000, other: true])
  end

  test "builds args with protocol option" do
    assert [Plug.Adapters.Cowboy2Test.HTTP,
            [max_connections: 16_384, port: 3000],
            %{env: %{dispatch: @dispatch}, compress: true, timeout: 30_000}] =
           args(:http, __MODULE__, [], [port: 3000, compress: true, timeout: 30_000])

    assert [Plug.Adapters.Cowboy2Test.HTTP,
            [max_connections: 16_384, port: 3000],
            %{env: %{dispatch: @dispatch}, timeout: 30_000}] =
           args(:http, __MODULE__, [], [port: 3000, protocol_options: [timeout: 30_000]])
  end

  test "builds args with single-atom protocol option" do
    assert [Plug.Adapters.Cowboy2Test.HTTP,
            [:inet6, max_connections: 16_384, port: 3000],
            %{env: %{dispatch: @dispatch}}] =
           args(:http, __MODULE__, [], [:inet6, port: 3000])
  end

  test "builds child specs" do
    assert {{:ranch_listener_sup, Plug.Adapters.Cowboy2Test.HTTP},
            {:cowboy, :start_clear, _},
            :permanent,
            :infinity,
            :supervisor,
            [:ranch_listener_sup]} = child_spec(:http, __MODULE__, [], [])
  end

  defmodule MyPlug do
    def init(opts), do: opts
  end

  test "errors when trying to run on https" do
    assert_raise ArgumentError, ~r/missing option :key\/:keyfile/, fn ->
      Plug.Adapters.Cowboy2.https MyPlug, [], []
    end

    assert_raise ArgumentError, ~r/ssl\/key\.pem required by SSL's :keyfile either does not exist/, fn ->
      Plug.Adapters.Cowboy2.https MyPlug, [],
        keyfile: "priv/ssl/key.pem",
        certfile: "priv/ssl/cert.pem",
        otp_app: :plug
    end
  end
end
