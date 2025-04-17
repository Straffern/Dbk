defmodule Dbk.Dst.Variable do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  alias Dbk.Dst.Value

  sqlite do
    table "variables"
    repo Dbk.Repo
  end

  actions do
    default_accept [:variable_id, :text, :order, :elimination, :time]
    defaults [:read, :update, :destroy]

    create :create do
      primary? true
      upsert? true
      upsert_identity :unique_variable

      argument :values, {:array, :map}

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.after_action(fn changeset, _ ->
          changeset.arguments.values
          |> Enum.map(&Map.put(&1, :variable_id, changeset.attributes.variable_id))
          |> Ash.bulk_create!(Value, :create, return_errors?: true)

          # Ash.Changeset.manage_relationship(changeset, :values, values, type: :append)
        end)
      end
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :variable_id, :string
    attribute :text, :string

    attribute :order, :integer
    attribute :elimination, :boolean
    attribute :time, :boolean
  end

  relationships do
    has_many :values, Value, source_attribute: :variable_id
  end

  identities do
    identity :unique_variable, :variable_id
  end
end
