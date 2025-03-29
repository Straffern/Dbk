defmodule Dbk.Dst.Subject.ManualRead do
  use Ash.Resource.ManualRead
  require Logger

  def read(ash_query, _data_layer_query, _opts, _context) do
    # Get argument values with defaults
    args = ash_query.arguments
    include_tables = args.include_tables
    recursive = args.recursive
    omit_inactive_subjects = args.omit_inactive_subjects

    # Build base URL with subjects if provided
    base_url =
      case Map.get(args, :subjects) do
        nil -> "https://api.statbank.dk/v1/subjects"
        subjects -> "https://api.statbank.dk/v1/subjects/#{Enum.join(subjects, ",")}"
      end

    # Build query params
    params =
      [
        "includeTables=#{include_tables}",
        "recursive=#{recursive}",
        "omitInactiveSubjects=#{omit_inactive_subjects}"
      ]
      |> Enum.join("&")

    # Combine URL with query params
    url = if params != "", do: "#{base_url}?#{params}", else: base_url

    Logger.debug("Fetching subjects from #{url}")

    http_client = Application.get_env(:dbk, :http_client, Dbk.Http.FinchClient)

    case http_client.request(:get, url, [], "", []) do
      {:ok, %{status: 200, data: body}} ->
        case Jason.decode(body) do
          {:ok, decoded} ->
            subjects = transform_subjects(decoded, nil)
            {:ok, subjects}

          {:error, reason} ->
            {:error, "JSON decoding failed: #{inspect(reason)}"}
        end

      {:ok, %{status: status_code, data: body}} ->
        {:error, "API request failed with status #{status_code}: #{body}"}

      {:error, reason} ->
        {:error, "API request failed: #{inspect(reason)}"}
    end
  end

  defp transform_subjects(data, parent_id) do
    Enum.flat_map(data, fn item ->
      subject = %Dbk.Dst.Subject{
        id: item["id"],
        description: item["description"],
        active: item["active"],
        has_subjects: item["hasSubjects"],
        # Set the parent_id for this subject
        parent_id: parent_id
      }

      # Recursively transform subsubjects, setting their parent_id to this subject's id
      subsubjects = transform_subjects(item["subjects"] || [], item["id"])
      # Combine this subject with its subsubjects
      [subject | subsubjects]
    end)
  end
end

