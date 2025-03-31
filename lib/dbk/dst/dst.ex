defmodule Dbk.Dst do
  use Ash.Domain

  alias Dbk.Dst.{Subject, Table}

  resources do
    resource(Subject)
    resource(Table)
  end
end
