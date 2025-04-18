defmodule Dbk.Dst.Variable do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  require Ash.Resource.Change.Builtins
  alias Dbk.Dst.Value

  sqlite do
    table "variables"
    repo Dbk.Repo
  end

  actions do
    default_accept [:id, :text, :order, :elimination, :time]
    defaults [:read, :update, :destroy]

    create :create do
      primary? true
      upsert? true

      argument :values, {:array, :map}

      change after_action(fn
               changeset, record, context ->
                 with values <- changeset.arguments.values,
                      values_with_variable_id <-
                        Enum.map(values, &Map.put(&1, :variable_id, record.variable_id)),
                      _bulk_create <-
                        Ash.bulk_create(values_with_variable_id, Value, :create,
                          return_errors?: true
                        ) do
                   {:ok, record}
                 end
             end)
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true
    attribute :text, :string

    attribute :order, :integer
    attribute :elimination, :boolean
    attribute :time, :boolean
  end

  relationships do
    has_many :values, Value, source_attribute: :variable_id, destination_attribute: :variable_id
  end

  identities do
    identity :unique_variable, :variable_id
  end
end
