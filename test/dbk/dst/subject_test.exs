defmodule Dbk.Dst.SubjectTest do
  use Dbk.DataCase, async: true
  alias Dbk.{Dst, Dst.Subject}

  # Import and setup Mox
  import Mox
  setup :verify_on_exit!

  describe "list_subjects/1" do
    test "lists subjects without any arguments" do
      # Prepare mock response data
      mock_response = [
        %{
          "id" => 1,
          "description" => "Population",
          "active" => true,
          "hasSubjects" => true,
          "subjects" => [
            %{
              "id" => 2,
              "description" => "Population Count",
              "active" => true,
              "hasSubjects" => false,
              "subjects" => []
            }
          ]
        }
      ]

      # Mock the HTTP request
      expect(Dbk.Http.MockClient, :request, fn :get, url, _headers, _body, _opts ->
        assert url == "https://api.statbank.dk/v1/subjects?includeTables=false&recursive=false&omitInactiveSubjects=false"
        {:ok, %{status: 200, data: Jason.encode!(mock_response)}}
      end)

      # Make the actual request through Ash
      result = Subject
        |> Ash.Query.for_read(:list_subjects)
        |> Ash.read!(domain: Dst)

      # Verify the response structure
      assert length(result) == 2
      [parent, child] = result
      
      assert parent.id == 1
      assert parent.description == "Population"
      assert parent.active == true
      assert parent.has_subjects == true
      assert is_nil(parent.parent_id)
      
      assert child.id == 2
      assert child.description == "Population Count"
      assert child.active == true
      assert child.has_subjects == false
      assert child.parent_id == 1
    end

    test "lists specific subjects with all options enabled" do
      # Prepare mock response data for specific subjects
      mock_response = [
        %{
          "id" => 1,
          "description" => "Population",
          "active" => true,
          "hasSubjects" => true,
          "subjects" => [
            %{
              "id" => 2,
              "description" => "Population Count",
              "active" => true,
              "hasSubjects" => false,
              "subjects" => []
            }
          ]
        }
      ]

      # Mock the HTTP request
      expect(Dbk.Http.MockClient, :request, fn :get, url, _headers, _body, _opts ->
        assert url == "https://api.statbank.dk/v1/subjects/1,2?includeTables=true&recursive=true&omitInactiveSubjects=true"
        {:ok, %{status: 200, data: Jason.encode!(mock_response)}}
      end)

      # Make the actual request with all options
      result = Subject
        |> Ash.Query.for_read(:list_subjects, %{
          subjects: [1, 2],
          include_tables: true,
          recursive: true,
          omit_inactive_subjects: true
        })
        |> Ash.read!(domain: Dst)

      # Verify the response structure
      assert length(result) == 2
      [parent, child] = result
      
      assert parent.id == 1
      assert parent.description == "Population"
      assert parent.active == true
      assert parent.has_subjects == true
      assert is_nil(parent.parent_id)
      
      assert child.id == 2
      assert child.description == "Population Count"
      assert child.active == true
      assert child.has_subjects == false
      assert child.parent_id == 1
    end

    test "handles API error responses" do
      # Mock an error response from the API
      expect(Dbk.Http.MockClient, :request, fn :get, _url, _headers, _body, _opts ->
        {:ok, %{status: 404, data: "Not Found"}}
      end)

      # Make the request and verify error handling
      query = Subject |> Ash.Query.for_read(:list_subjects)
      
      assert {:error, %Ash.Error.Unknown{errors: [error | _]}} = Ash.read(query, domain: Dst)
      assert error.error == "API request failed with status 404: Not Found"
    end

    test "handles network errors" do
      # Mock a network error
      expect(Dbk.Http.MockClient, :request, fn :get, _url, _headers, _body, _opts ->
        {:error, %Mint.TransportError{reason: :timeout}}
      end)

      # Make the request and verify error handling
      query = Subject |> Ash.Query.for_read(:list_subjects)
      
      assert {:error, %Ash.Error.Unknown{errors: [error | _]}} = Ash.read(query, domain: Dst)
      assert error.error == "API request failed: %Mint.TransportError{reason: :timeout}"
    end
  end
end