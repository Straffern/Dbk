defmodule NumeriWeb.ErrorJSONTest do
  use NumeriWeb.ConnCase, async: true

  test "renders 404" do
    assert NumeriWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert NumeriWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
