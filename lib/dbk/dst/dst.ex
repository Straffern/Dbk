defmodule Dbk.Dst do
  use Ash.Domain

  alias Dbk.Dst.{Store, Subject, Table, Variable, Value, TableVariables}

  resources do
    resource Store
    resource Subject
    resource Table
    resource Variable
    resource Value
    resource TableVariables
  end
end
