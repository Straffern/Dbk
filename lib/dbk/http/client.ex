defmodule Dbk.Http.Client do
  @moduledoc """
  Behaviour for HTTP client implementations.
  """

  @type method :: :get | :post
  @type headers :: [{String.t(), String.t()}]
  @type response :: {:ok, %{status: integer(), body: term()}} | {:error, term()}

  @callback request(
              method(),
              String.t(),
              headers(),
              term(),
              keyword()
            ) :: response()
end