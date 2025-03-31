defmodule Dbk.Dst.Store do
  @moduledoc """
  Client for interacting with the Statistics Denmark (DST) API.

  API Documentation: https://api.statbank.dk/
  """

  require Logger

  @client Application.compile_env(:dbk, :http_client, Dbk.Http.FinchClient)
  @base_url "https://api.statbank.dk/v1"

  @doc """
  Fetches subjects from the DST API.

  ## Endpoints
  POST #{@base_url}/subjects

  Payload parameters will be documented when specified.
  """
  @spec fetch_subjects(map()) :: {:ok, map()} | {:error, any()}
  def fetch_subjects(params \\ %{}) do
    "#{@base_url}/subjects"
    |> post(params)
    |> handle_response()
  end

  @doc """
  Fetches tables from the DST API.

  ## Endpoints
  POST #{@base_url}/tables

  Payload parameters will be documented when specified.
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

  Payload parameters will be documented when specified.
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

  Payload parameters will be documented when specified.
  """
  @spec fetch_data(map()) :: {:ok, map()} | {:error, any()}
  def fetch_data(params \\ %{}) do
    "#{@base_url}/data"
    |> post(params)
    |> handle_response()
  end

  def parse_subject(json, parent_id \\ nil) do
    %{
      id: json["id"],
      description: json["description"],
      active: json["active"],
      has_subjects: json["hasSubjects"],
      parent_id: parent_id,
      children: Enum.map(json["subjects"], &parse_subject(&1, json["id"])),
      tables: Enum.map(json["tables"], &parse_table(&1, json["id"]))
    }
  end

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
