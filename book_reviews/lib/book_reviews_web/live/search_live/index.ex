defmodule BookReviewsWeb.SearchLive.Index do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Search Books")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = params["q"] || ""
    requested_page = params |> Map.get("page", "1") |> parse_page()

    result = Catalog.search_books(query, page: requested_page, per_page: @per_page)

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:page, result.page)
     |> assign(:total_pages, result.total_pages)
     |> assign(:total_count, result.total_count)
     |> assign(:books, result.books)}
  end

  defp parse_page(page) do
    case Integer.parse(to_string(page)) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: ~p"/search?#{[q: q]}")}
  end

  def handle_event("go_to_page", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: ~p"/search?#{[q: socket.assigns.query, page: page]}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Search Books
        <:subtitle>Find books whose summary contains any of your search words</:subtitle>
      </.header>

      <form phx-submit="search" id="book-search-form" class="flex gap-3 my-4">
        <input
          type="text"
          name="q"
          value={@query}
          placeholder="e.g. ocean secret kingdom"
          autocomplete="off"
          class="input input-bordered flex-1"
        />
        <.button>Search</.button>
      </form>

      <p :if={@query != ""} class="text-sm text-base-content/60 mb-4">
        {@total_count} result(s) for "{@query}"
      </p>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>Book</th>
              <th>Author</th>
              <th>Summary</th>
              <th>Published</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={book <- @books} id={"book-#{book.id}"}>
              <td>
                <.link navigate={~p"/books/#{book}"} class="link">{book.name}</.link>
              </td>
              <td>{book.author.name}</td>
              <td class="max-w-md truncate">{book.summary}</td>
              <td>{book.publication_date}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p :if={@query != "" and @books == []} class="text-center text-base-content/60 py-6">
        No books found for "{@query}".
      </p>

      <div :if={@total_pages > 1} class="flex items-center justify-center gap-4 mt-4">
        <.button phx-click="go_to_page" phx-value-page={@page - 1} disabled={@page <= 1}>
          Previous
        </.button>
        <span class="text-sm text-base-content/70">Page {@page} of {@total_pages}</span>
        <.button phx-click="go_to_page" phx-value-page={@page + 1} disabled={@page >= @total_pages}>
          Next
        </.button>
      </div>
    </Layouts.app>
    """
  end
end
