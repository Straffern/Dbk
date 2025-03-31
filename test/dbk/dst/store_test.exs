defmodule Dbk.Dst.StoreTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  alias Dbk.Dst.Store
  alias Dbk.Http.MockClient

  @subject_response %{
    "id" => "2",
    "description" => "Arbejde og indkomst",
    "active" => true,
    "hasSubjects" => true,
    "subjects" => [
      %{
        "id" => "21",
        "description" => "Befolkningens arbejdsmarkedsstatus",
        "active" => true,
        "hasSubjects" => false,
        "subjects" => [],
        "tables" => []
      }
    ],
    "tables" => []
  }

  @subject_with_tables_response %{
    "id" => "2",
    "description" => "Arbejde og indkomst",
    "active" => true,
    "hasSubjects" => true,
    "subjects" => [
      %{
        "id" => "21",
        "description" => "Befolkningens arbejdsmarkedsstatus",
        "active" => true,
        "hasSubjects" => false,
        "subjects" => [],
        "tables" => [
          %{
            "id" => "AKU100",
            "text" => "Arbejdskraftundersøgelsen",
            "unit" => "antal",
            "updated" => "2024-03-15T08:00:00",
            "firstPeriod" => "2007K1",
            "latestPeriod" => "2024K1",
            "active" => true,
            "variables" => 5
          }
        ]
      }
    ],
    "tables" => []
  }

  @table_response %{
    "id" => "AKU100",
    "text" => "Arbejdskraftundersøgelsen",
    "unit" => "antal",
    "updated" => "2024-03-15T08:00:00",
    "firstPeriod" => "2007K1",
    "latestPeriod" => "2024K1",
    "active" => true,
    "variables" => 5
  }

  @table_info_response %{
    "id" => "AKU100",
    "text" => "Arbejdskraftundersøgelsen",
    "description" => "Arbejdskraftundersøgelsen efter beskæftigelsesstatus og tid",
    "unit" => "antal",
    "variables" => [
      %{
        "id" => "tid",
        "text" => "Tid",
        "values" => ["2024K1", "2023K4"]
      }
    ]
  }

  @data_response %{
    "dataset" => [
      %{
        "tid" => "2024K1",
        "value" => "2500000"
      }
    ]
  }

  describe "fetch_subjects/1" do
    test "successfully fetches subjects" do
      MockClient
      |> expect(:request, fn :post, "https://api.statbank.dk/v1/subjects", [], %{}, [] ->
        {:ok, %{status: 200, body: [@subject_response]}}
      end)

      assert {:ok, response} = Store.fetch_subjects()
      assert is_list(response)
      subject = List.first(response)
      assert subject["id"] == "2"
      assert subject["description"] == "Arbejde og indkomst"
    end

    test "successfully fetches subjects with tables" do
      MockClient
      |> expect(:request, fn :post,
                             "https://api.statbank.dk/v1/subjects",
                             [],
                             %{"subjects" => ["2"], "includeTables" => true},
                             [] ->
        {:ok, %{status: 200, body: [@subject_with_tables_response]}}
      end)

      assert {:ok, response} =
               Store.fetch_subjects(%{"subjects" => ["2"], "includeTables" => true})

      assert is_list(response)
      subject = List.first(response)
      assert subject["id"] == "2"
      assert subject["subjects"] |> List.first() |> get_in(["tables"]) |> length() == 1
    end

    test "handles error responses" do
      MockClient
      |> expect(:request, fn :post,
                             "https://api.statbank.dk/v1/subjects",
                             [],
                             %{error: true},
                             [] ->
        {:ok, %{status: 400, body: %{"message" => "Bad Request"}}}
      end)

      assert {:error, %{status: 400}} = Store.fetch_subjects(%{error: true})
    end
  end

  describe "fetch_tables/1" do
    test "successfully fetches tables" do
      MockClient
      |> expect(:request, fn :post, "https://api.statbank.dk/v1/tables", [], %{}, [] ->
        {:ok, %{status: 200, body: %{"tables" => [@table_response]}}}
      end)

      assert {:ok, response} = Store.fetch_tables()
      assert match?(%{"tables" => [_]}, response)
      table = List.first(response["tables"])
      assert table["id"] == "AKU100"
    end
  end

  describe "fetch_table_info/1" do
    test "successfully fetches table info" do
      MockClient
      |> expect(:request, fn :post, "https://api.statbank.dk/v1/tableinfo", [], %{}, [] ->
        {:ok, %{status: 200, body: @table_info_response}}
      end)

      assert {:ok, response} = Store.fetch_table_info()
      assert response["id"] == "AKU100"
      assert response["text"] == "Arbejdskraftundersøgelsen"
      assert is_list(response["variables"])
    end
  end

  describe "fetch_data/1" do
    test "successfully fetches data" do
      MockClient
      |> expect(:request, fn :post,
                             "https://api.statbank.dk/v1/data",
                             [],
                             %{"format" => "json"},
                             [] ->
        {:ok, %{status: 200, body: @data_response}}
      end)

      assert {:ok, response} = Store.fetch_data(%{"format" => "json"})
      assert match?(%{"dataset" => [_]}, response)
      data = List.first(response["dataset"])
      assert data["value"] == "2500000"
    end
  end

  describe "parse_subject/2" do
    test "parses subject response with nested subjects" do
      parsed = Store.parse_subject(@subject_response)

      assert parsed.id == "2"
      assert parsed.description == "Arbejde og indkomst"
      assert parsed.active == true
      assert parsed.has_subjects == true
      assert length(parsed.children) == 1
      assert length(parsed.tables) == 0

      [child] = parsed.children
      assert child.id == "21"
      assert child.parent_id == "2"
    end

    test "parses subject with nested tables" do
      parsed = Store.parse_subject(@subject_with_tables_response)
      [child] = parsed.children
      [table] = child.tables

      assert table.id == "AKU100"
      # Child subject's ID
      assert table.subject_id == "21"
    end
  end

  describe "parse_table/2" do
    test "parses table data with subject_id" do
      parsed = Store.parse_table(@table_response, "2")

      assert parsed.id == "AKU100"
      assert parsed.text == "Arbejdskraftundersøgelsen"
      assert parsed.unit == "antal"
      assert parsed.updated == "2024-03-15T08:00:00"
      assert parsed.first_period == "2007K1"
      assert parsed.latest_period == "2024K1"
      assert parsed.active == true
      assert parsed.variables == 5
      assert parsed.subject_id == "2"
    end
  end
end
