defmodule Dbk.Dst do
  use Ash.Domain

  resources do
    resource(Dbk.Dst.Subject)
    resource(Dbk.Dst.Table)
  end
end

