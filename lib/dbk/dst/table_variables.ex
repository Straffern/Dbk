defmodule Dbk.Dst.TableVariables do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  alias Dbk.Dst.{Table, Variable}

  sqlite do
    table "table_variables"
    repo Dbk.Repo

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
    belongs_to :variable, Variable, primary_key?: true, allow_nil?: false
  end

  identities do
    identity :unique_table_variable, [:table_id, :variable_id]
  end
end
