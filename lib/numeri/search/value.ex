defmodule Numeri.Search.Value do
  use Ash.Resource, otp_app: :numeri, domain: Numeri.Search, data_layer: AshSqlite.DataLayer
  alias Numeri.Search

  sqlite do
    table "values"
    repo Numeri.Repo
  end

  attributes do
    integer_primary_key :id

    attribute :value, :union do
      constraints types: [
                    int: [
                      type: :integer
                    ],
                    string: [type: :string]
                  ]
    end

    attribute :metadata, :map
  end

  relationships do
    belongs_to :dimension, Search.Dimension, attribute_type: :integer
  end
end
