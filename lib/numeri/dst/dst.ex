defmodule Numeri.Dst do
  use Ash.Domain

  alias Numeri.Dst.{Store, Subject, Table, Variable, Value, TableVariables}

  resources do
    resource Store, do: define(:refresh_store, action: :refresh, args: [:subjects])

    resource Subject
    resource Table
    resource Variable
    resource Value
    resource TableVariables
  end
end
