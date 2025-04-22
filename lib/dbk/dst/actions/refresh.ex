defmodule Dbk.Dst.Refresh do
  @moduledoc """
  Handles refreshing DST data by fetching from the external store and updating our local database.
  This includes subjects, tables, and variables with their relationships.
  """

  use Ash.Resource.Actions.Implementation

  require Logger
  alias Dbk.Dst.Store
  alias Dbk.Dst.{Subject, Table, Variable}

  @doc """
  Refreshes DST data based on the provided input parameters.
  """
  def run(input, _opts, _context) do
    with {:ok, params} <- build_params(input),
         {:ok, parsed_data} <- fetch_subjects(params),
         {:ok, tables_info} <- fetch_unique_tables_info(parsed_data),
         {:ok, new_tables} <- build_tables_with_variables(parsed_data, tables_info),
         {:ok, _subjects, _tables, _variables} <-
           persist_data(tables_info, new_tables, parsed_data) do
      Logger.info("Refreshed subjects, tables and vairables")
      :ok
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
        ordered: false,
        max_concurrency: 10,
        on_timeout: :kill_task,
        timeout: 30_000
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
    Enum.flat_map(parsed_data, &collect_tables_recursive/1)
    |> Enum.reduce({[], MapSet.new()}, fn map, {result, seen} ->
      if Enum.any?(map[:variables], fn var -> not MapSet.member?(seen, var) end) do
        new_seen = MapSet.union(seen, MapSet.new(map[:variables]))
        {[map | result], new_seen}
      else
        {result, seen}
      end
    end)
    |> elem(0)
  end

  defp collect_tables_recursive(%{tables: tables, children: children}) do
    tables ++ Enum.flat_map(children, &collect_tables_recursive/1)
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
    enriched_subjects = enrich_subjects_with_variables(parsed_data, tables_info)

    with {:ok, variables} <- create_variables(tables_info),
         {:ok, tables} <- create_tables(new_tables),
         {:ok, subjects} <- create_subjects(enriched_subjects) do
      {:ok, subjects, tables, variables}
    end
  end

  defp enrich_subjects_with_variables(subjects, tables_info) do
    variable_lookup =
      tables_info
      |> Enum.flat_map(fn table ->
        Enum.map(table.variables || [], fn var -> {var.text, var} end)
      end)
      |> Map.new()

    Enum.map(subjects, fn subject ->
      update_subject_tables_and_children(subject, variable_lookup)
    end)
  end

  defp update_subject_tables_and_children(subject, variable_lookup) do
    %{
      subject
      | tables: Enum.map(subject.tables, &update_table_variables_full(&1, variable_lookup)),
        children:
          Enum.map(subject.children, &update_subject_tables_and_children(&1, variable_lookup))
    }
  end

  defp update_table_variables_full(table, variable_lookup) do
    Map.update!(table, :variables, fn vars ->
      Enum.map(vars, fn var_text ->
        Map.get(variable_lookup, var_text, var_text)
      end)
    end)
  end

  defp create_variables(tables_info) do
    try do
      result =
        tables_info
        |> Enum.flat_map(& &1.variables)
        |> Ash.bulk_create!(Variable, :create,
          upsert_fields: [:order, :values],
          return_errors?: true
        )

      {:ok, result}
    rescue
      e -> {:error, e}
    end
  end

  defp create_tables(new_tables) do
    try do
      result =
        Ash.bulk_create!(new_tables, Table, :create,
          upsert_fields: [:updated, :latest_period, :active, :variables]
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
