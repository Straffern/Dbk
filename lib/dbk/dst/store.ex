defmodule Dbk.Dst.Store do
  @moduledoc """
  Client for interacting with the Statistics Denmark (DST) API.

  API Documentation: https://api.statbank.dk/
  """
  use Ash.Resource,
    domain: Dbk.Dst

  require Logger

  alias Dbk.Dst

  # Get the HTTP client to use, defaulting to FinchClient in non-test environments
  @client Application.compile_env(:dbk, :http_client, Dbk.Http.FinchClient)

  @base_url "https://api.statbank.dk/v1"

  actions do
    action :refresh do
      argument :subjects, {:array, :string}, allow_nil?: true, description: "list of ids"
      argument :omit_inactive_subjects, :boolean, allow_nil?: false, default: true

      run Dst.Refresh
    end
  end

  @doc """
  Fetches subjects from the DST API.

  ## Endpoints
  POST #{@base_url}/subjects

  ## Parameters
  - subjects: Optional list of subject IDs to fetch
  - includeTables: Boolean, whether to include tables in the response
  - recursive: Boolean, whether to fetch subjects recursively
  - omitInactiveSubjects: Boolean, whether to exclude inactive subjects
  - format: Result format (JSON, XML)
  - language: Optional language code (default: da)
  """
  @spec fetch_subjects(map()) :: {:ok, list(map())} | {:error, any()}
  def fetch_subjects(params \\ %{}) do
    params =
      params
      |> Map.put_new("format", "JSON")
      |> Map.put_new("language", "da")

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
  - includeInactive: Boolean,        whether to include inactive tables
  - format: Result format (JSON, XML)
  - language: Optional language code (default: da)
  """
  @spec fetch_tables(map()) :: {:ok, list(map())} | {:error, any()}
  def fetch_tables(params \\ %{}) do
    params =
      params
      |> Map.put_new("format", "JSON")
      |> Map.put_new("language", "da")

    "#{@base_url}/tables"
    |> post(params)
    |> handle_response()
  end

  @doc """
  Fetches detailed information about a specific table.

  ## Endpoints
  POST #{@base_url}/tableinfo

  ## Parameters
  - table: Table ID to fetch information for (required)
  - format: Result format (JSON, XML)
  - language: Optional language code (default: da)
  """
  @spec fetch_table_info(map()) :: {:ok, map()} | {:error, any()}
  def fetch_table_info(params) do
    params =
      params
      |> Map.put_new("format", "JSON")
      |> Map.put_new("language", "da")

    "#{@base_url}/tableinfo"
    |> post(params)
    |> handle_response()
  end

  @doc """
  Fetches data from a specific table.

  ## Endpoints
  POST #{@base_url}/data

  ## Parameters
  - table: Table ID to fetch data from (required)
  - variables: List of variable selections
  - valuePresentation: Optional value presentation format
  - timeOrder: Optional time sort order
  - format: Result format (JSONSTAT, CSV, etc..)
  """
  @spec fetch_data(map()) :: {:ok, map()} | {:error, any()}
  def fetch_data(params) do
    params =
      params
      |> Map.put_new("format", "JSONSTAT")

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
  Parses a table response (from /tables endpoint) into a structured map.
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
      subject_id: subject_id,
      variables: json["variables"]
    }
  end

  @doc """
  Parses the detailed table information response (from /tableinfo endpoint)
  into a structured map.
  """
  def parse_table_info(json) when is_map(json) do
    %{
      id: json["id"],
      text: json["text"],
      description: json["description"],
      unit: json["unit"],
      suppressed_data_value: json["suppressedDataValue"],
      # Consider parsing to DateTime if needed
      updated: json["updated"],
      active: json["active"],
      documentation: parse_documentation(json["documentation"]),
      variables: parse_variables(json["variables"])
    }
  end

  # Handle non-map input gracefully
  def parse_table_info(_), do: nil

  defp parse_documentation(nil), do: nil

  defp parse_documentation(doc) when is_map(doc) do
    %{
      id: doc["id"],
      url: doc["url"]
    }
  end

  # Handle unexpected format
  defp parse_documentation(_), do: nil

  defp parse_variables(nil), do: []

  defp parse_variables(variables) when is_list(variables) do
    Enum.map(variables, fn variable ->
      %{
        variable_id: variable["id"],
        text: variable["text"],
        elimination: variable["elimination"],
        time: variable["time"],
        # May be nil
        map: variable["map"],
        values: parse_variable_values(variable["values"])
      }
    end)
  end

  # Handle unexpected format
  defp parse_variables(_), do: []

  defp parse_variable_values(nil), do: []

  defp parse_variable_values(values) when is_list(values) do
    Enum.map(values, fn value ->
      %{
        value_id: value["id"],
        text: value["text"]
      }
    end)
  end

  # Handle unexpected format
  defp parse_variable_values(_), do: []

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
