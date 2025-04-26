defmodule Numeri.Http.FinchClient do
  @moduledoc """
  Finch-based implementation of the HTTP client behaviour.
  """
  @behaviour Numeri.Http.Client

  @impl true
  def request(method, url, headers, body, _opts) do
    body = Jason.encode!(body)
    headers = [{"content-type", "application/json"} | headers]

    Finch.build(method, url, headers, body)
    |> Finch.request(Numeri.Finch)
    |> case do
      {:ok, %Finch.Response{status: status, body: body}} ->
        {:ok, %{status: status, body: Jason.decode!(body)}}

      {:error, _} = error ->
        error
    end
  end
end
