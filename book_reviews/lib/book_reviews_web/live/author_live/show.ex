defmodule BookReviewsWeb.AuthorLive.Show do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@author.name}
        <:subtitle>Author record</:subtitle>
        <:actions>
          <.button navigate={~p"/authors"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/authors/#{@author}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit author
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@author.name}</:item>
        <:item title="Country of origin">{@author.country_of_origin}</:item>
        <:item title="Birth date">{@author.birth_date}</:item>
        <:item title="Description">{@author.description}</:item>
      </.list>

      <.header>
        Books
        <:actions>
          <.button variant="primary" navigate={~p"/books/new"}>
            <.icon name="hero-plus" /> New Book
          </.button>
        </:actions>
      </.header>

      <.table id="author-books" rows={@author.books}>
        <:col :let={book} label="Name">{book.name}</:col>
        <:col :let={book} label="Publication date">{book.publication_date}</:col>
        <:col :let={book} label="Sales count">{book.sales_count}</:col>
        <:action :let={book}>
          <.link navigate={~p"/books/#{book}"}>Show</.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Author")
     |> assign(:author, Catalog.get_author!(id))}
  end
end
