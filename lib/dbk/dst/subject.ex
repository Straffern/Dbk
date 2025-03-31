defmodule Dbk.Dst.Subject do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Authorizer.Always]

  require Ash.Query

  alias Dbk.Dst
  alias Dbk.Dst.Store

  actions do
    defaults([:create, :read, :update, :destroy])

    create :refresh do
      argument(:subjects, {:array, :string}, allow_nil?: true, description: "list of ids")
      argument(:include_tables, :boolean, allow_nil?: false, default: false)
      argument(:recursive, :boolean, allow_nil?: false, default: false)
      argument(:omit_inactive_subjects, :boolean, allow_nil?: false, default: false)

      change(fn changeset, _context ->
        # Clean up existing records
        __MODULE__.read!(paginated: true) |> Enum.each(&__MODULE__.destroy!(&1))

        # Build API params
        params =
          %{
            "subjects" => changeset.arguments[:subjects],
            "includeTables" => changeset.arguments[:include_tables],
            "recursive" => changeset.arguments[:recursive],
            "omitInactiveSubjects" => changeset.arguments[:omit_inactive_subjects]
          }
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()

        # Fetch and parse data
        {:ok, data} = Store.fetch_subjects(params)
        top_level_subjects = Enum.map(data, &Store.parse_subject/1)

        # Create records for all subjects
        Enum.each(top_level_subjects, &__MODULE__.create!(&1))

        changeset
      end)
    end
  end

  attributes do
    # Primary identifier - using string as per API docs
    attribute(:id, :integer, primary_key?: true, allow_nil?: false)
    attribute(:description, :string, allow_nil?: false)
    attribute(:active, :boolean, default: true)
    attribute(:has_subjects, :boolean, default: false)
  end

  relationships do
    belongs_to :parent, __MODULE__ do
      attribute_type(:integer)
      attribute_writable?(true)
      allow_nil?(true)
      source_attribute(:parent_id)
    end

    has_many :children, __MODULE__ do
      destination_attribute(:parent_id)
      relationship_context(%{on_delete: :delete})
    end

    has_many :tables, Dst.Table do
      destination_attribute(:subject_id)
      relationship_context(%{on_delete: :delete})
    end
  end
end
