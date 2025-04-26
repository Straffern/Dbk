defmodule Numeri.Search.Concept do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer

  alias Numeri.Search

  sqlite do
    table "concepts"
    repo Numeri.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :name, :string
    attribute :description, :string
    # later extend to: https://hexdocs.pm/ash/Ash.Type.Enum.html
    attribute :data_source, :atom, constraints: [one_of: [:dst]]
  end

  relationships do
    many_to_many :dimensions, Search.Dimension, through: Search.ConceptDimension
  end
end
