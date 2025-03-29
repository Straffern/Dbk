defmodule Dbk.Dst.Subject do
  use Ash.Resource,
    domain: Dbk.Dst,
    data_layer: Ash.DataLayer.Simple

  alias Dbk.Dst

  actions do
    read :list_subjects do
      argument(:subjects, {:array, :integer}, allow_nil?: true, description: "list of ids")
      argument(:include_tables, :boolean, allow_nil?: false, default: false)
      argument(:recursive, :boolean, allow_nil?: false, default: false)
      argument(:omit_inactive_subjects, :boolean, allow_nil?: false, default: false)

      manual(__MODULE__.ManualRead)
    end
  end

  attributes do
    # Primary identifier - using string as per API docs, never prepended with 0
    attribute(:id, :integer, primary_key?: true, allow_nil?: false)

    # Basic attributes from API
    attribute(:description, :string, allow_nil?: false)
    attribute(:active, :boolean, allow_nil?: false, default: true)
    attribute(:has_subjects, :boolean, allow_nil?: false, default: false)
  end

  relationships do
    # Self-referential relationship for hierarchy
    belongs_to :parent, __MODULE__ do
      attribute_type(:integer)
      attribute_writable?(true)
      # Root subjects don't have a parent
      allow_nil?(true)
    end

    has_many :subsubjects, __MODULE__ do
      destination_attribute(:parent_id)
    end

    # Relationship to tables within this subject
    has_many :tables, Dst.Table do
      destination_attribute(:subject_id)
    end
  end

  calculations do
    calculate(:api_url, :string, expr("https://api.statbank.dk/v1/subjects"))
  end
end