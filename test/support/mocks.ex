defmodule Numeri.Test.Mocks do
  @moduledoc """
  Defines mocks used in tests
  """
  
  # Define mock for HTTP client
  Mox.defmock(Numeri.Http.MockClient, for: Numeri.Http.Client)
end