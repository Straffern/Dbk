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
    defaults [:read, :update, :destroy]

    create :create do
      primary? true

      argument :values, {:array, :map}
      manage_relationship(:values, type: :create)
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :variable_id, :string
    attribute :text, :string
  end

  relationships do
    has_many :values, Value
  end

  identities do
    identity :unique_variable, :variable_id
  end
end
