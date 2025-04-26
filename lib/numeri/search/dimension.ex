defmodule Numeri.Search.Dimension do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer
  alias Numeri.Search

  sqlite do
    table "dimensions"
    repo Numeri.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :name, :string
    attribute :description, :string
  end

  relationships do
    many_to_many :concepts, Search.Concept, through: Search.ConceptDimension
    has_many :values, Search.Value
  end
end
