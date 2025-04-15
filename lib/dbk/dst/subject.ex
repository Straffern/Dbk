defmodule Dbk.Dst.Subject do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: AshSqlite.DataLayer

  require Ash.Query

  alias Dbk.Dst
  alias Dbk.Dst.Store

  sqlite do
    table "subjects"
    repo Dbk.Repo

    references do
      reference :parent, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :update, :destroy]
    default_accept [:id, :description, :has_subjects, :parent_id, :active]

    create :create do
      primary? true

      argument :children, {:array, :map}
      argument :tables, {:array, :map}

      upsert? true
      upsert_identity :id

      change manage_relationship(:children,
               on_lookup: :relate,
               on_no_match: :create
             )

      change manage_relationship(:tables,
               on_lookup: :relate,
               on_no_match: :create
             )
    end
  end

  attributes do
    # Primary identifier - using string as per API docs
    attribute :id, :integer, primary_key?: true, allow_nil?: false
    attribute :description, :string, allow_nil?: false
    attribute :active, :boolean, default: true
    attribute :has_subjects, :boolean, default: false
  end

  relationships do
    belongs_to :parent, __MODULE__ do
      attribute_type :integer
      attribute_writable? true
      allow_nil? true
      source_attribute :parent_id
    end

    has_many :children, __MODULE__ do
      destination_attribute :parent_id
    end

    has_many :tables, Dst.Table do
      destination_attribute :subject_id
    end
  end

  identities do
    identity :id, :id
  end
end
