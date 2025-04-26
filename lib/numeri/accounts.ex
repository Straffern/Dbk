defmodule Numeri.Accounts do
  use Ash.Domain, otp_app: :numeri, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource(Numeri.Accounts.Token)
    resource(Numeri.Accounts.User)
  end
end
