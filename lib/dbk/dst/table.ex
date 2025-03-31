defmodule Dbk.Dst.Table do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Authorizer.Always]

  alias Dbk.Dst

  actions do
    defaults([:create, :read, :update, :destroy])
  end

  attributes do
    attribute(:id, :string, primary_key?: true, allow_nil?: false)
    attribute(:text, :string, allow_nil?: false)
    attribute(:unit, :string)
    attribute(:updated, :utc_datetime)
    attribute(:first_period, :string)
    attribute(:latest_period, :string)
    attribute(:active, :boolean, allow_nil?: false, default: true)
    attribute(:variables, :integer, default: 0)
  end

  relationships do
    belongs_to :subject, Dst.Subject do
      attribute_type(:integer)
      attribute_writable?(true)
      allow_nil?(true)
    end
  end

  # calculations do
  #   calculate(:api_url, :string, expr("https://api.statbank.dk/v1/tables"))
  # end
end
