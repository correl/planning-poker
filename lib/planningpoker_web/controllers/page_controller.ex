defmodule PlanningpokerWeb.PageController do
  use PlanningpokerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
