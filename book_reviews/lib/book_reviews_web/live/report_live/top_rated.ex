defmodule BookReviewsWeb.ReportLive.TopRated do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Top Rated Books")
     |> assign(:books, Catalog.top_rated_books(10))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} max_width="max-w-6xl">
      <.header>
        Top 10 Rated Books
        <:subtitle>
          Ranked by average review score, with each book's highest and lowest rated review
        </:subtitle>
      </.header>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>#</th>
              <th>Book</th>
              <th>Author</th>
              <th>Average score</th>
              <th>Reviews</th>
              <th>Highest-rated review</th>
              <th>Lowest-rated review</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={{entry, index} <- Enum.with_index(@books, 1)} id={"book-#{entry.book.id}"}>
              <td>{index}</td>
              <td>
                <.link navigate={~p"/books/#{entry.book}"} class="link">{entry.book.name}</.link>
              </td>
              <td>{entry.author_name}</td>
              <td>{format_score(entry.avg_score)}</td>
              <td>{entry.review_count}</td>
              <td>{review_summary(entry.highest_review)}</td>
              <td>{review_summary(entry.lowest_review)}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p :if={@books == []} class="text-center text-base-content/60 py-6">
        No reviewed books yet.
      </p>
    </Layouts.app>
    """
  end

  defp format_score(nil), do: "—"
  defp format_score(score), do: :erlang.float_to_binary(score * 1.0, decimals: 2)

  defp review_summary(nil), do: "—"
  defp review_summary(review), do: "#{review.score}/5 — #{review.review}"
end
