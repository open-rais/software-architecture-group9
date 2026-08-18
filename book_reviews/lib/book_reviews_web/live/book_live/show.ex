defmodule BookReviewsWeb.BookLive.Show do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@book.name}
        <:subtitle>Book record</:subtitle>
        <:actions>
          <.button navigate={~p"/books"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/books/#{@book}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit book
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Author">
          <.link navigate={~p"/authors/#{@book.author}"} class="link">{@book.author.name}</.link>
        </:item>
        <:item title="Summary">{@book.summary}</:item>
        <:item title="Publication date">{@book.publication_date}</:item>
        <:item title="Sales count">{@book.sales_count}</:item>
      </.list>

      <.header>
        Reviews
        <:actions>
          <.button variant="primary" navigate={~p"/books/#{@book}/reviews"}>
            Manage reviews
          </.button>
        </:actions>
      </.header>

      <.table id="book-reviews" rows={@book.reviews}>
        <:col :let={review} label="Score">{review.score}</:col>
        <:col :let={review} label="Review">{review.review}</:col>
        <:col :let={review} label="Upvotes">{review.upvotes}</:col>
      </.table>

      <.header>
        Sales
        <:actions>
          <.button variant="primary" navigate={~p"/books/#{@book}/sales"}>
            Manage sales
          </.button>
        </:actions>
      </.header>

      <.table id="book-sales" rows={@book.sales}>
        <:col :let={sale} label="Year">{sale.year}</:col>
        <:col :let={sale} label="Sales">{sale.sales}</:col>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Book")
     |> assign(:book, Catalog.get_book!(id))}
  end
end
