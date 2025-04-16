defmodule Dbk.Dst.Refresh do
  @moduledoc """
  Handles refreshing DST data by fetching from the external store and updating our local database.
  This includes subjects, tables, and variables with their relationships.
  """

  use Ash.Resource.Actions.Implementation

  alias Dbk.Dst.Store
  alias Dbk.Dst.{Subject, Table, Variable}

  @doc """
  Refreshes DST data based on the provided input parameters.
  """
  def run(input, _opts, _context) do
    with {:ok, params} <- build_params(input),
         {:ok, parsed_data} <- fetch_subjects(params),
         {:ok, tables_info} <- fetch_unique_tables_info(parsed_data),
         {:ok, new_tables} <- build_tables_with_variables(parsed_data, tables_info) do
      persist_data(tables_info, new_tables, parsed_data)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp build_params(input) do
    params =
      %{
        "subjects" => input.arguments[:subjects],
        "includeTables" => true,
        "recursive" => true,
        "omitInactiveSubjects" => input.arguments[:omit_inactive_subjects],
        "omitSubjectsWithoutTables" => true
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    {:ok, params}
  end

  defp fetch_subjects(params) do
    with {:ok, raw_subjects} <- Store.fetch_subjects(params),
         parsed_data <- Enum.map(raw_subjects, &Store.parse_subject/1) do
      {:ok, parsed_data}
    else
      {:error, _reason} = error -> error
    end
  end

  defp fetch_unique_tables_info(parsed_data) do
    table_ids =
      parsed_data
      |> extract_unique_tables()
      |> Enum.map(& &1.id)

    tables_info =
      table_ids
      |> Task.async_stream(
        &fetch_table_info/1,
        max_concurrency: 10,
        ordered: false,
        on_timeout: :kill_task
      )
      |> Enum.reduce([], &collect_table_info/2)

    {:ok, tables_info}
  end

  defp fetch_table_info(table_id) do
    case Store.fetch_table_info(%{"table" => table_id}) do
      {:ok, result} -> Store.parse_table_info(result)
      {:error, _} = error -> error
    end
  end

  defp collect_table_info({:ok, table_info}, acc), do: [table_info | acc]
  defp collect_table_info(_, acc), do: acc

  defp extract_unique_tables(parsed_data) do
    Enum.flat_map(parsed_data, & &1.tables)
    |> Enum.reduce({[], MapSet.new()}, fn map, {result, seen} ->
      if Enum.any?(map[:variables], fn var -> not MapSet.member?(seen, var) end) do
        new_seen = MapSet.union(seen, MapSet.new(map[:variables]))
        {[map | result], new_seen}
      else
        {result, seen}
      end
    end)
    |> elem(1)
  end

  defp build_tables_with_variables(parsed_data, tables_info) do
    new_tables =
      parsed_data
      |> Enum.flat_map(& &1.tables)
      |> Enum.map(&update_table_variables(&1, tables_info))

    {:ok, new_tables}
  end

  defp update_table_variables(table, tables_info) do
    Map.update!(table, "variables", fn vars ->
      Enum.map(vars, fn var ->
        Enum.find(tables_info, &(&1.text == var))
      end)
    end)
  end

  defp persist_data(tables_info, new_tables, parsed_data) do
    with {:ok, _variables} <- create_variables(tables_info),
         {:ok, _tables} <- create_tables(new_tables),
         {:ok, subjects} <- create_subjects(parsed_data) do
      {:ok, subjects}
    end
  end

  defp create_variables(tables_info) do
    try do
      result = Ash.bulk_create!(tables_info, Variable, :create, upsert_fields: [:order])
      {:ok, result}
    rescue
      e -> {:error, e}
    end
  end

  defp create_tables(new_tables) do
    try do
      result =
        Ash.bulk_create!(new_tables, Table, :create,
          upsert_fields: [:updated, :latest_period, :active]
        )

      {:ok, result}
    rescue
      e -> {:error, e}
    end
  end

  defp create_subjects(parsed_data) do
    try do
      result =
        parsed_data
        # |> Enum.map(&Store.parse_subject/1)
        |> Ash.bulk_create!(Subject, :create,
          upsert_fields: [:description, :children, :tables],
          return_errors?: true
        )

      {:ok, result}
    rescue
      e -> {:error, e}
    end
  end
end
