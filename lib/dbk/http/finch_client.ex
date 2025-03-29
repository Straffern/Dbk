defmodule Dbk.Http.FinchClient do
  @behaviour Dbk.Http.Client

  def request(:get, url, headers, _body, _opts) do
    case Finch.build(:get, url, headers) |> Finch.request(Dbk.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} ->
        {:ok, %{status: status, data: body}}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
end