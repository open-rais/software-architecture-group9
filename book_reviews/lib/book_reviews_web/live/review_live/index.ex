defmodule BookReviewsWeb.ReviewLive.Index do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Reviews for {@book.name}
        <:actions>
          <.button navigate={~p"/books/#{@book}"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/books/#{@book}/reviews/new"}>
            <.icon name="hero-plus" /> New Review
          </.button>
        </:actions>
      </.header>

      <.table id="reviews" rows={@streams.reviews}>
        <:col :let={{_id, review}} label="Score">{review.score}</:col>
        <:col :let={{_id, review}} label="Review">{review.review}</:col>
        <:col :let={{_id, review}} label="Upvotes">{review.upvotes}</:col>
        <:action :let={{_id, review}}>
          <.link navigate={~p"/books/#{@book}/reviews/#{review}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, review}}>
          <.link
            phx-click={JS.push("delete", value: %{id: review.id}) |> hide("##{id}")}
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
  def mount(%{"book_id" => book_id}, _session, socket) do
    book = Catalog.get_book!(book_id)

    {:ok,
     socket
     |> assign(:page_title, "Reviews")
     |> assign(:book, book)
     |> stream(:reviews, Catalog.list_reviews(book))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    review = Catalog.get_review!(id)
    {:ok, _} = Catalog.delete_review(review)

    {:noreply, stream_delete(socket, :reviews, review)}
  end
end
