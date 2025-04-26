defmodule Numeri.Http.Client do
  @moduledoc """
  Behaviour for HTTP clients used in the application.
  """

  @callback request(
    method :: :get | :post | :put | :delete,
    url :: String.t(),
    headers :: list(),
    body :: term(),
    opts :: keyword()
  ) :: {:ok, map()} | {:error, term()}
end