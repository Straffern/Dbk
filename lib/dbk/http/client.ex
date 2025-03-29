defmodule Dbk.Http.Client do
  @callback request(method :: :get, url :: String.t(), headers :: list(), body :: String.t(), opts :: keyword()) ::
    {:ok, %{status: integer(), data: String.t()}} | {:error, term()}
end