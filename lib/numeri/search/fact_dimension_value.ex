defmodule Numeri.Search.FactDimensionValue do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer

  sqlite do
    table "fact_dimension_values"
    repo Numeri.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :fact_id, :integer
    attribute :dimension_value_id, :integer
  end
end
