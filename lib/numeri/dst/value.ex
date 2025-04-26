defmodule Numeri.Dst.Value do
  use Ash.Resource,
    domain: Numeri.Dst,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  alias Numeri.Dst.Variable

  sqlite do
    table "variable_values"
    repo Numeri.Repo

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
      upsert_identity :unique_value
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :value_id, :string
    attribute :text, :string
  end

  relationships do
    belongs_to :variable, Variable,
      allow_nil?: false,
      attribute_type: :string
  end

  identities do
    identity :unique_value, [:value_id, :variable_id]
  end
end
