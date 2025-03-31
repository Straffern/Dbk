defmodule Dbk.Http.Client do
  @callback request(
              method :: :get | :post,
              url :: String.t(),
              headers :: list(),
              body :: term(),
              opts :: keyword()
            ) ::
              {:ok, %{status: integer(), body: term()}} | {:error, term()}
end

