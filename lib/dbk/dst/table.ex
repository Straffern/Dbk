defmodule Dbk.Dst.Table do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: AshSqlite.DataLayer

  import Ash.Changeset

  alias Dbk.Dst
  alias Dbk.Dst.Store

  sqlite do
    table "tables"
    repo Dbk.Repo

    references do
      reference :subject, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :update, :destroy]

    default_accept [
      :id,
      :text,
      :unit,
      :updated,
      :first_period,
      :latest_period,
      :active,
      :subject_id
    ]

    create :create do
      primary? true

      upsert? true
      upsert_identity :id
      upsert_fields [:latest_period, :active, :updated]

      change fn changeset, _context ->
        with {:ok, response} <- Store.fetch_table_info(%{"table" => changeset.attributes.id}),
             metadata <- Store.parse_table_info(response) do
          dbg(metadata)

          changeset
          |> manage_relationship(:variables, metadata.variables,
            on_lookup: :relate,
            on_no_match: :create,
            use_identities: [:unique_variable]
          )
        end
      end
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :text, :string, allow_nil?: false
    attribute :unit, :string
    attribute :updated, :utc_datetime
    attribute :first_period, :string
    attribute :latest_period, :string
    attribute :active, :boolean, allow_nil?: false, default: true
  end

  relationships do
    belongs_to :subject, Dst.Subject do
      attribute_type :integer
      attribute_writable? true
      allow_nil? true
    end

    many_to_many :variables, Dst.Variable, through: Dst.TableVariables
  end

  identities do
    identity :id, :id
  end

  # calculations do
  #   calculate(:api_url, :string, expr("https://api.statbank.dk/v1/tables"))
  # end
end
