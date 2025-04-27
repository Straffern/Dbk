defmodule Numeri.Repo.Migrations.AddMunicipalities do
  use Ecto.Migration
  alias Numeri.Repo

  @json_path Path.join(__DIR__, "/20250426221052_add_municipalities/kommuner.json")

  def change do
    # Create dimension for municipalities
    {_count, [ dimension ]} = 
      Repo.insert_all("dimensions",
        [ %{
          name: "municipality",
          description: "Municipalities"
        } ], returning: [:id]
      )

    # Load and parse JSON data
    json_data = 
      @json_path
      |> File.read!()
      |> JSON.decode!()

    # Insert each municipality as a value
    rows =
      Enum.map(json_data, fn municipality ->
        %{
          value: JSON.encode!(%{type: :string, value: municipality["navn"]}),
          metadata: JSON.encode!(%{
            "kode" => municipality["kode"],
            "region" => municipality["region"]["navn"],
            "bbox" => municipality["bbox"],
            "centerPoint" => municipality["visueltcenter"]
          }),
          dimension_id: dimension.id
        }
      end)
    Repo.insert_all("values", rows)
  end
end
