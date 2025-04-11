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

    action :refresh do
      argument :subjects, {:array, :string}, allow_nil?: true, description: "list of ids"
      argument :include_tables, :boolean, allow_nil?: false, default: true
      argument :recursive, :boolean, allow_nil?: false, default: true
      argument :omit_subjects_without_tables, :boolean, allow_nil?: false, default: true
      argument :omit_inactive_subjects, :boolean, allow_nil?: false, default: true

      run fn input, _context ->
        # Build API params
        params =
          %{
            "subjects" => input.arguments[:subjects],
            "includeTables" => input.arguments[:include_tables],
            "recursive" => input.arguments[:recursive],
            "omitInactiveSubjects" => input.arguments[:omit_inactive_subjects],
            "omitSubjectsWithoutTables" => input.arguments[:omit_subjects_without_tables]
          }
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()

        # Fetch and parse data
        {:ok, data} = Store.fetch_subjects(params)

        data
        |> Enum.map(&Store.parse_subject/1)
        |> Enum.take_random(5)
        |> Ash.bulk_create!(__MODULE__, :create,
          upsert_fields: [:description, :children, :tables],
          return_errors?: true
        )

        :ok
      end
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
