defmodule BookReviewsWeb.AuthorLive.Index do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Authors
        <:actions>
          <.button variant="primary" navigate={~p"/authors/new"}>
            <.icon name="hero-plus" /> New Author
          </.button>
        </:actions>
      </.header>

      <.table
        id="authors"
        rows={@streams.authors}
        row_click={fn {_id, author} -> JS.navigate(~p"/authors/#{author}") end}
      >
        <:col :let={{_id, author}} label="Name">{author.name}</:col>
        <:col :let={{_id, author}} label="Country of origin">{author.country_of_origin}</:col>
        <:col :let={{_id, author}} label="Birth date">{author.birth_date}</:col>
        <:action :let={{_id, author}}>
          <div class="sr-only">
            <.link navigate={~p"/authors/#{author}"}>Show</.link>
          </div>
          <.link navigate={~p"/authors/#{author}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, author}}>
          <.link
            phx-click={JS.push("delete", value: %{id: author.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Authors")
     |> stream(:authors, Catalog.list_authors())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    author = Catalog.get_author!(id)
    {:ok, _} = Catalog.delete_author(author)

    {:noreply, stream_delete(socket, :authors, author)}
  end
end
