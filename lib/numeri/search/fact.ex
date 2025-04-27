defmodule Numeri.Search.Fact do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer
  alias Numeri.Search

  sqlite do
    table "facts"
    repo Numeri.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :extra_attributes, :map, description: "Used by the data source fetching logic"
  end

  relationships do
    belongs_to :concept, Search.Concept, attribute_type: :integer
    many_to_many :values, Search.Value, through: Search.FactValue
  end
end
