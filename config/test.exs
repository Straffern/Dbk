import Config

# Configure the database
config :dbk, Dbk.Repo,
  database: Path.expand("../dbk_test.db", Path.dirname(__ENV__.file)),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dbk, DbkWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ld5PVtKxCSqoP8JMxISuS2wNxhQs+/o/FKs+HZjpJiOlsJ897Mpl5wUxv2DUUTc+",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure test-specific HTTP client
config :dbk, :http_client, Dbk.Http.MockClient

# Ash resources configuration
config :dbk,
  ash_domains: [Dbk.Dst, Dbk.Accounts]

# Configure Swoosh API client
config :swoosh, api_client: Swoosh.ApiClient.Test