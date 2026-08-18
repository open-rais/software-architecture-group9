defmodule BookReviewsWeb.BookLive.Index do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Books
        <:actions>
          <.button variant="primary" navigate={~p"/books/new"}>
            <.icon name="hero-plus" /> New Book
          </.button>
        </:actions>
      </.header>

      <.table
        id="books"
        rows={@streams.books}
        row_click={fn {_id, book} -> JS.navigate(~p"/books/#{book}") end}
      >
        <:col :let={{_id, book}} label="Name">{book.name}</:col>
        <:col :let={{_id, book}} label="Author">{book.author.name}</:col>
        <:col :let={{_id, book}} label="Publication date">{book.publication_date}</:col>
        <:col :let={{_id, book}} label="Sales count">{book.sales_count}</:col>
        <:action :let={{_id, book}}>
          <div class="sr-only">
            <.link navigate={~p"/books/#{book}"}>Show</.link>
          </div>
          <.link navigate={~p"/books/#{book}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, book}}>
          <.link
            phx-click={JS.push("delete", value: %{id: book.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Books")
     |> stream(:books, Catalog.list_books())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    book = Catalog.get_book!(id)
    {:ok, _} = Catalog.delete_book(book)

    {:noreply, stream_delete(socket, :books, book)}
  end
end
