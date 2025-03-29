defmodule Dbk.Dst.Table.ManualRead do
  use Ash.Resource.ManualRead
  require Logger
  alias Finch

  def read(ash_query, _data_layer_query, _opts, _context) do
    # Extract arguments from the query
    arguments = Ash.Query.get_argument(ash_query, :arguments) || %{}

    # Build URL with query params
    params =
      [
        subjects_param(Map.get(arguments, :subjects)),
        pastdays_param(Map.get(arguments, :pastdays)),
        "includeinactive=#{Map.get(arguments, :includeinactive, false)}"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("&")

    # Get the API URL from the resource calculation
    api_url = "https://api.statbank.dk/v1/tables"
    url = api_url <> if(params != "", do: "?#{params}", else: "")

    Logger.debug("Fetching tables from #{url}")

    case make_api_request(url) do
      {:ok, tables} ->
        # Transform API response into resource format
        formatted_tables = format_tables(tables)
        {:ok, formatted_tables}

      {:error, _} = error ->
        error
    end
  end

  # Private helpers

  defp make_api_request(url) do
    headers = [{"Content-Type", "application/json"}]
    request_body = Jason.encode!(%{})

    case Finch.build(:post, url, headers, request_body)
         |> Finch.request(Dbk.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} = error -> error
        end

      {:ok, %Finch.Response{status: status_code, body: body}} ->
        {:error, "API request failed with status #{status_code}: #{body}"}

      {:error, reason} ->
        {:error, "API request failed: #{inspect(reason)}"}
    end
  end

  defp format_tables(tables) do
    Enum.map(tables, fn table ->
      %{
        id: table["id"],
        text: table["text"],
        unit: table["unit"],
        updated: parse_datetime(table["updated"]),
        first_period: table["firstPeriod"],
        latest_period: table["latestPeriod"],
        active: table["active"],
        variables: table["variables"] || []
      }
    end)
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end

  defp subjects_param(nil), do: nil
  defp subjects_param([]), do: nil

  defp subjects_param(subjects) do
    subjects_str = subjects |> Enum.map(&"\"#{&1}\"") |> Enum.join(",")
    "subjects=[#{subjects_str}]"
  end

  defp pastdays_param(nil), do: nil
  defp pastdays_param(days) when is_integer(days) and days > 0, do: "pastdays=#{days}"
  defp pastdays_param(_), do: nil
end
