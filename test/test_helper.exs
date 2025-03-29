ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Dbk.Repo, :manual)

# Define mock for HTTP client
Mox.defmock(Dbk.Http.MockClient, for: Dbk.Http.Client)
Application.put_env(:dbk, :http_client, Dbk.Http.MockClient)