defmodule Dbk.Dst.Subject do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: Ash.DataLayer.Ets

  alias Dbg.Dst
  alias Dbk.Dst.Store

  actions do
    defaults([:create, :read, :update, :destroy])

    action :refresh do
      run(fn input, _ ->
        __MODULE__.read!(paginated: true) |> Enum.each(&Subject.destroy!(&1))
        data = Store.fetch_subjects()
        top_level_subjects = Enum.map(data, &Store.parse_subject/1)

        Enum.each(top_level_subjects, fn subject_data ->
          Subject.create!(subject_data, authorize?: false)
        end)

        :ok
      end)
    end
  end

  attributes do
    # Primary identifier - using string as per API docs, never prepended with 0
    attribute(:id, :integer, primary_key?: true, allow_nil?: false)

    # Basic attributes from API
    attribute(:description, :string, allow_nil?: false)
    attribute(:active, :boolean, default: true)
    attribute(:has_subjects, :boolean, default: false)
  end

  relationships do
    # Self-referential relationship for hierarchy
    belongs_to :parent, __MODULE__ do
      attribute_type(:integer)
      attribute_writable?(true)
      # Root subjects don't have a parent
      allow_nil?(true)
    end

    has_many :children, __MODULE__ do
      destination_attribute(:parent_id)
      relationship_context(%{on_delete: :delete})
    end

    # Relationship to tables within this subject
    has_many :tables, Dst.Table do
      destination_attribute(:subject_id)
      relationship_context(%{on_delete: :delete})
    end
  end

  # calculations do
  #   calculate(:api_url, :string, expr("https://api.statbank.dk/v1/subjects"))
  # end
end
