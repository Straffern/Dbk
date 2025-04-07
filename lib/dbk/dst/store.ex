defmodule Dbk.Dst.Store do
  @moduledoc """
  Client for interacting with the Statistics Denmark (DST) API.

  API Documentation: https://api.statbank.dk/
  """

  require Logger

  # Get the HTTP client to use, defaulting to FinchClient in non-test environments
  @client Application.compile_env(:dbk, :http_client, Dbk.Http.FinchClient)

  @base_url "https://api.statbank.dk/v1"

  @doc """
  Fetches subjects from the DST API.

  ## Endpoints
  POST #{@base_url}/subjects

  ## Parameters
  - subjects: Optional list of subject IDs to fetch
  - includeTables: Boolean, whether to include tables in the response
  - recursive: Boolean, whether to fetch subjects recursively
  - omitInactiveSubjects: Boolean, whether to exclude inactive subjects
  """
  @spec fetch_subjects(map()) :: {:ok, list(map())} | {:error, any()}
  def fetch_subjects(params \\ %{}) do
    "#{@base_url}/subjects"
    |> post(params)
    |> handle_response()
  end

  @doc """
  Fetches tables from the DST API.

  ## Endpoints
  POST #{@base_url}/tables

  ## Parameters
  - subjects: Optional list of subject IDs to limit tables by subject
  - pastDays: Optional integer, number of days to look back for updates
  - includeInactive: Boolean, whether to include inactive tables
  - format: Result format (JSON, CSV, etc)
  """
  @spec fetch_tables(map()) :: {:ok, map()} | {:error, any()}
  def fetch_tables(params \\ %{}) do
    "#{@base_url}/tables"
    |> post(params)
    |> handle_response()
  end

  @doc """
  Fetches detailed information about a specific table.

  ## Endpoints
  POST #{@base_url}/tableinfo

  ## Parameters
  - table: Table ID to fetch information for
  - language: Optional language code (default: da)
  """
  @spec fetch_table_info(map()) :: {:ok, map()} | {:error, any()}
  def fetch_table_info(params \\ %{}) do
    "#{@base_url}/tableinfo"
    |> post(params)
    |> handle_response()
  end

  @doc """
  Fetches data from a specific table.

  ## Endpoints
  POST #{@base_url}/data

  ## Parameters
  - table: Table ID to fetch data from
  - format: Result format (required, e.g. "json")
  - variables: List of variable selections
  - valuePresentation: Optional value presentation format
  - timeOrder: Optional time sort order
  """
  @spec fetch_data(map()) :: {:ok, map()} | {:error, any()}
  def fetch_data(params \\ %{}) do
    params = Map.put_new(params, "format", "json")

    "#{@base_url}/data"
    |> post(params)
    |> handle_response()
  end

  @doc """
  Parses a subject response into a structured map.
  Handles nested subjects recursively, assigning parent IDs as needed.
  """
  def parse_subject(json, parent_id \\ nil) do
    %{
      id: json["id"],
      description: json["description"],
      active: json["active"],
      has_subjects: json["hasSubjects"],
      parent_id: parent_id,
      children: Enum.map(json["subjects"] || [], &parse_subject(&1, json["id"])),
      tables: Enum.map(json["tables"] || [], &parse_table(&1, json["id"]))
    }
  end

  @doc """
  Parses a table response into a structured map.
  Associates the table with a subject via subject_id.
  """
  def parse_table(json, subject_id) do
    %{
      id: json["id"],
      text: json["text"],
      unit: json["unit"],
      updated: json["updated"],
      first_period: json["firstPeriod"],
      latest_period: json["latestPeriod"],
      active: json["active"],
      variables: json["variables"],
      subject_id: subject_id
    }
  end

  # Private helper functions

  defp post(url, params) do
    @client.request(:post, url, [], params, [])
  end

  defp handle_response({:ok, %{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    Logger.warning("API request failed with status #{status}: #{inspect(body)}")
    {:error, %{status: status, body: body}}
  end

  defp handle_response({:error, _} = error), do: error
end
