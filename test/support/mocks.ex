defmodule Dbk.Test.Mocks do
  @moduledoc """
  Defines mocks used in tests
  """
  
  # Define mock for HTTP client
  Mox.defmock(Dbk.Http.MockClient, for: Dbk.Http.Client)
end