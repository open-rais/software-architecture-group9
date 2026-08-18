defmodule BookReviewsWeb.SaleLive.Index do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Sales for {@book.name}
        <:actions>
          <.button navigate={~p"/books/#{@book}"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/books/#{@book}/sales/new"}>
            <.icon name="hero-plus" /> New Sale
          </.button>
        </:actions>
      </.header>

      <.table id="sales" rows={@streams.sales}>
        <:col :let={{_id, sale}} label="Year">{sale.year}</:col>
        <:col :let={{_id, sale}} label="Sales">{sale.sales}</:col>
        <:action :let={{_id, sale}}>
          <.link navigate={~p"/books/#{@book}/sales/#{sale}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, sale}}>
          <.link
            phx-click={JS.push("delete", value: %{id: sale.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Sales")
     |> assign(:book, book)
     |> stream(:sales, Catalog.list_sales(book))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    sale = Catalog.get_sale!(id)
    {:ok, _} = Catalog.delete_sale(sale)

    {:noreply, stream_delete(socket, :sales, sale)}
  end
end
