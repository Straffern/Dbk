import Config

# Configure the database
config :numeri, Numeri.Repo,
  database: Path.expand("../numeri_test.db", Path.dirname(__ENV__.file)),
  pool: Ecto.Adapters.SQL.Sandbox

config :ash, :disable_async?, true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :numeri, NumeriWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ld5PVtKxCSqoP8JMxISuS2wNxhQs+/o/FKs+HZjpJiOlsJ897Mpl5wUxv2DUUTc+",
  server: false

# Print only warnings and errors during test
config :logger,
  backends: [],
  level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure test-specific HTTP client
config :numeri, :http_client, Numeri.Http.MockClient

# Ash resources configuration
config :numeri,
  ash_domains: [Numeri.Search, Numeri.Dst, Numeri.Accounts]

# Configure Swoosh API client
config :swoosh, api_client: Swoosh.ApiClient.Test
