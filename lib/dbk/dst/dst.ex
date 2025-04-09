defmodule Dbk.Dst do
  use Ash.Domain

  alias Dbk.Dst.{Subject, Table, Variable, Value, TableVariables}

  resources do
    resource Subject
    resource Table
    resource Variable
    resource Value
    resource TableVariables
  end
end
