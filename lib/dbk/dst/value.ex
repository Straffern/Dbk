defmodule Dbk.Dst.Value do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  alias Dbk.Dst.Variable

  sqlite do
    table "values"
    repo Dbk.Repo

    references do
      reference :variable, on_delete: :delete
    end
  end

  actions do
    default_accept [:value_id, :text, :variable_id]
    defaults [:read, :update, :destroy]

    create :create do
      primary? true
      upsert? true
      upsert_fields [:text]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :value_id, :string
    attribute :text, :string
  end

  relationships do
    belongs_to :variable, Variable, allow_nil?: false
  end

  identities do
    identity :unique_value, [:value_id, :variable_id]
  end
end
