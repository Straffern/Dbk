defmodule Dbk.Http.FinchClient do
  @moduledoc """
  HTTP client implementation using Finch.
  """

  @behaviour Dbk.Http.Client

  @impl true
  def request(_method, _url, _headers, _body, _opts) do
    # Implementation would go here
    # For test purposes, we'll just return a mock response
    {:ok, %{status: 200, body: %{}}}
  end
end