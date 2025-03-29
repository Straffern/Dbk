defmodule Dbk.Accounts do
  use Ash.Domain, otp_app: :dbk, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource(Dbk.Accounts.Token)
    resource(Dbk.Accounts.User)
  end
end
