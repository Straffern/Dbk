defmodule Dbk.Dst.Refresh do
  use Ash.Resource.Actions.Implementation

  alias Dbk.Dst.Store

  def run(input, _opts, _context) do
    # currently we don't need to delete, since we take advantage of upsert
    # delete all subjects, tables, variables and units
    # Ash.bulk_destroy!(Dst.Subject, :destroy, %{})
    # Ash.bulk_destroy!(Dst.Variable, :destroy, %{})

    params =
      %{
        "subjects" => input.arguments[:subjects],
        "includeTables" => input.arguments[:include_tables],
        "recursive" => input.arguments[:recursive],
        "omitInactiveSubjects" => input.arguments[:omit_inactive_subjects],
        "omitSubjectsWithoutTables" => input.arguments[:omit_subjects_without_tables]
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    # Fetch and parse data
    {:ok, result} = Store.fetch_subjects(params)

    data =
      result
      |> Enum.map(&Store.parse_subject/1)

    tables =
      Enum.flat_map(data, & &1.tables)

    # Collect all unique variables from all tables
    all_variables =
      tables
      |> Enum.flat_map(& &1.variables)
      |> Enum.uniq()

    # Filter tables to retain only those with at least one unique variable
    table_ids =
      tables
      |> Enum.filter(fn table ->
        Enum.any?(table.variables, &(&1 in all_variables))
      end)
      |> Enum.map(& &1.id)

    # fetch_table_info, this we need to bulk insert (create)
    tables_info =
      table_ids
      |> Task.async_stream(&Store.fetch_table_info(%{"table" => &1}), max_concurrency: 10)
      |> Enum.map(fn {:ok, result} ->
        Store.parse_table_info(result)
      end)

    # create new tables list, with list of variable ids, instead of list of variable names, for table.variables
    new_tables =
      tables
      |> Enum.map(fn table ->
        Map.update!(table, "variables", fn vars ->
          Enum.map(vars, fn var ->
            Enum.find(tables_info, &(&1.text == var)).id
          end)
        end)
      end)

    # bulk_create variables & values
    tables_info
    |> Ash.bulk_create!(Dst.Variable, :create, upsert_fields: [:order])

    # bulk_create tables
    new_tables
    |> Ash.bulk_create!(Dst.Table, :create, upsert_fields: [:updated, :latest_period, :active])

    data
    |> Enum.map(&Store.parse_subject/1)
    |> Ash.bulk_create!(__MODULE__, :create,
      upsert_fields: [:description, :children, :tables],
      return_errors?: true
    )
  end
end
