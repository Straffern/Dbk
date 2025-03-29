defmodule Dbk.Repo do
  use AshSqlite.Repo,
    otp_app: :dbk
end
