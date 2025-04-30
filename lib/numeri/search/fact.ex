defmodule Numeri.Search.Fact do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer
  require Ash.Query

  alias Numeri.Search

  sqlite do
    table "facts"
    repo Numeri.Repo
  end

  @type t :: %__MODULE__{}
  attributes do
    integer_primary_key :id
    attribute :extra_attributes, :map, description: "Used by the data source fetching logic"
  end

  relationships do
    belongs_to :concept, Search.Concept, attribute_type: :integer
    many_to_many :dimension_values, Search.DimensionValue, through: Search.FactDimensionValue
  end

  validations do
    validate &check_dimension_values_belong_to_concept/2, on: [:create, :update]
    validate &check_fact_duplication/2, on: [:create]
  end

  defp check_dimension_values_belong_to_concept(changeset, _context) do
    concept = Ash.Changeset.get_argument_or_attribute(changeset, :concept)
    dimension_values = Ash.Changeset.get_argument_or_attribute(changeset, :dimension_values)

    if concept && dimension_values do
      concept_dimension_ids = concept.dimensions |> Enum.map(& &1.id)
      value_dimension_ids = dimension_values |> Enum.map(& &1.dimension_id)

      if Enum.all?(value_dimension_ids, &(&1 in concept_dimension_ids)) do
        :ok
      else
        {:error, "All dimension values must belong to dimensions of the fact's concept"}
      end
    else
      :ok
    end
  end

  defp check_fact_duplication(changeset, _context) do
    concept_id = Ash.Changeset.get_argument_or_attribute(changeset, :concept_id)

    dimension_values =
      Ash.Changeset.get_argument_or_attribute(changeset, :dimension_values)

    if concept_id && dimension_values && !Enum.empty?(dimension_values) do
      value_ids = dimension_values |> Enum.map(& &1.id) |> Enum.sort()
      value_ids_count = length(value_ids)

      existing_fact_count =
        Search.Fact
        |> Ash.Query.filter(concept_id == ^concept_id)
        |> Ash.Query.filter(
          fragment(
            """
            (SELECT COUNT(*) FROM fact_dimension_values WHERE fact_dimension_values.fact_id = facts.id) = ? AND
            (SELECT COUNT(*) FROM fact_dimension_values WHERE fact_dimension_values.fact_id = facts.id AND fact_dimension_values.dimension_value_id IN ?) = ?
            """,
            ^value_ids_count,
            ^value_ids,
            ^value_ids_count
          )
        )
        |> Ash.count()

      case existing_fact_count do
        {:ok, 0} ->
          :ok

        {:ok, _} ->
          {:error, "A fact with the same concept and dimension values already exists"}

        {:error, _} ->
          {:error, "Failed to check for existing facts"}
      end
    else
      :ok
    end
  end
end
