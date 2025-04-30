defmodule Numeri.Repo.Migrations.AddGenericDimensions do
  use Ecto.Migration

  alias Numeri.Repo

  def change do
    # Create dimensions first
    dimensions = [
      %{
        name: "Age",
        description: "Age in years from 0 to 125",
      },
      %{
        name: "Year",
        description: "Year from 1985 to 2025",
      },
      %{
        name: "Sex",
        description: "Biological sex options",
      }
    ]

    # Insert dimensions and get their IDs
    {_count, [age_dim, year_dim, sex_dim]} = 
      Repo.insert_all("dimensions", dimensions, 
        returning: [:id], 
        on_conflict: :nothing
      )

    # Generate values for each dimension
    age_values = Enum.map(0..125, fn age ->
      %{
        value: JSON.encode!(%{type: :integer, value: age}),
        dimension_id: age_dim.id,
      }
    end)

    year_values = Enum.map(1985..2025, fn year ->
      %{
        value: JSON.encode!(%{type: :integer, value: year}),
        dimension_id: year_dim.id,
      }
    end)

    sex_values = ["Male", "Female", "Unknown"]
      |> Enum.map(fn sex ->
        %{
          value: JSON.encode!( %{type: :string, value: sex} ),
          dimension_id: sex_dim.id,
        }
      end)

    # Insert all values in batches
    Repo.insert_all("dimension_values", age_values)
    Repo.insert_all("dimension_values", year_values)
    Repo.insert_all("dimension_values", sex_values)
  end
end
