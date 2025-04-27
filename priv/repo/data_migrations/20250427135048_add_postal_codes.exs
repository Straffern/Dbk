defmodule Numeri.Repo.Migrations.AddPostalCodes do
  use Ecto.Migration
  alias Numeri.Repo

  @json_path Path.join(__DIR__, "/20250427135048_add_postal_codes/postnumre.json")

  def change do
    # Create dimension for postal_code
    {_count, [ dimension ]} = 
      Repo.insert_all("dimensions",
        [ %{
          name: "Postal codes",
          description: "Postal codes"
        } ], returning: [:id]
      )

    # Load and parse JSON data
    json_data = 
      @json_path
      |> File.read!()
      |> JSON.decode!()

    # Insert each postal_code as a value
    rows =
      Enum.map(json_data, fn postal_code ->
        %{
          value: JSON.encode!(%{type: :string, value: postal_code["navn"]}),
          metadata: JSON.encode!(%{
            "nr" => postal_code["nr"],
            "municipals" => Enum.map(postal_code["kommuner"], & Map.get(&1, "navn")),
            "bbox" => postal_code["bbox"],
            "centerPoint" => postal_code["visueltcenter"]
          }),
          dimension_id: dimension.id
        }
      end)
    Repo.insert_all("values", rows)
  end
end
