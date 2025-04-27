defmodule Numeri.Repo.Migrations.AddCountries do
  use Ecto.Migration
  alias Numeri.Repo

  # Path to the JSON file containing country data
  # To generate countries.json, fetch data from https://restcountries.com/v3.1/all
  # Extract fields: name.common (as "name"), cca2 (as "code"), region (as "continent"), latlng (as "centerPoint")
  # Save the result as countries.json in the migration directory
  @json_path Path.join(__DIR__, "/20250427210851_add_countries/countries.json")

  def change do
    # Create dimension for countries
    {_count, [dimension]} =
      Repo.insert_all("dimensions",
        [%{
          name: "Country",
          description: "Countries"
        }],
        returning: [:id]
      )

    # Load and parse JSON data
    json_data =
      @json_path
      |> File.read!()
      |> JSON.decode!()

    # Insert each country as a value
    rows =
      Enum.map(json_data, fn country ->
        %{
          value: JSON.encode!(%{type: :string, value: country["name"]["common"]}),
          dimension_id: dimension.id
        }
      end)

    Repo.insert_all("values", rows)
  end
end
