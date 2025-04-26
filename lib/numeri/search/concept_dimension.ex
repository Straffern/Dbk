defmodule Numeri.Search.ConceptDimension do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer

  sqlite do
    table "concept_dimensions"
    repo Numeri.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :concept_id, :integer
    attribute :dimension_id, :integer
  end
end
