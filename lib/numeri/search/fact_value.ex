defmodule Numeri.Search.FactValue do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer

  sqlite do
    table "fact_values"
    repo Numeri.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :fact_id, :integer
    attribute :value_id, :integer
  end
end
