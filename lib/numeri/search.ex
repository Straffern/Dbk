defmodule Numeri.Search do
  use Ash.Domain,
    otp_app: :numeri

  resources do
    resource Numeri.Search.Concept
    resource Numeri.Search.Dimension
    resource Numeri.Search.ConceptDimension
    resource Numeri.Search.Value
    resource Numeri.Search.Fact
    resource Numeri.Search.FactValue
  end
end
