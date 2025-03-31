defmodule Dbk.Http.FinchClient do
  @behaviour Dbk.Http.Client

  require Logger

  def request(:get, url, headers, _body, _opts) do
    case Finch.build(:get, url, headers) |> Finch.request(Dbk.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} ->
        {:ok, %{status: status, body: decode_body(body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def request(:post, url, headers, body, _opts) do
    headers = [{"content-type", "application/json"} | headers]
    encoded_body = Jason.encode!(body)

    Logger.debug("Making POST request to #{url} with body: #{inspect(body)}")

    case Finch.build(:post, url, headers, encoded_body) |> Finch.request(Dbk.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} ->
        {:ok, %{status: status, body: decode_body(body)}}

      {:error, reason} ->
        Logger.error("Request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp decode_body(""), do: nil

  defp decode_body(body) when is_binary(body) do
    Jason.decode!(body)
  rescue
    e ->
      Logger.warning("Failed to decode JSON response: #{inspect(e)}")
      body
  end
end

