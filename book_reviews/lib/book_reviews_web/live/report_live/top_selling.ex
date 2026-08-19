defmodule BookReviewsWeb.ReportLive.TopSelling do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Top Selling Books")
     |> assign(:books, Catalog.top_selling_books(50))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} max_width="max-w-5xl">
      <.header>
        Top 50 Selling Books
        <:subtitle>
          Ranked by total sales, with each book's author total sales and whether it was a
          top-5 seller in its publication year
        </:subtitle>
      </.header>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>#</th>
              <th>Book</th>
              <th>Author</th>
              <th>Total sales (book)</th>
              <th>Total sales (author)</th>
              <th>Top 5 in publication year</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{entry, index} <- Enum.with_index(@books, 1)} id={"book-#{entry.book.id}"}>
              <td>{index}</td>
              <td>
                <.link navigate={~p"/books/#{entry.book}"} class="link">{entry.book.name}</.link>
              </td>
              <td>{entry.author_name}</td>
              <td>{entry.total_sales}</td>
              <td>{entry.author_total_sales}</td>
              <td>
                <span class={[
                  "badge",
                  if(entry.top5_in_publication_year, do: "badge-success", else: "badge-ghost")
                ]}>
                  {if entry.top5_in_publication_year, do: "Yes", else: "No"}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <p :if={@books == []} class="text-center text-base-content/60 py-6">
        No sales recorded yet.
      </p>
    </Layouts.app>
    """
  end
end
