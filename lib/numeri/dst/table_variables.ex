defmodule Numeri.Dst.TableVariables do
  use Ash.Resource,
    domain: Numeri.Dst,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  alias Numeri.Dst.{Table, Variable}

  sqlite do
    table "table_variables"
    repo Numeri.Repo

    references do
      reference :table, on_delete: :delete
      reference :variable, on_delete: :delete
    end
  end

  actions do
    default_accept [:table_id, :variable_id]
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id
  end

  relationships do
    belongs_to :table, Table, primary_key?: true, allow_nil?: false, attribute_type: :string
    belongs_to :variable, Variable, primary_key?: true, allow_nil?: false, attribute_type: :string
  end

  identities do
    identity :unique_table_variable, [:table_id, :variable_id]
  end
end
