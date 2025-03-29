defmodule Dbk.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Dbk.Accounts.User, _opts, _context) do
    Application.fetch_env(:dbk, :token_signing_secret)
  end
end
