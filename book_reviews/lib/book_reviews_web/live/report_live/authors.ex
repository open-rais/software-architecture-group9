defmodule BookReviewsWeb.ReportLive.Authors do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog

  @default_filters %{
    "name" => "",
    "country_of_origin" => "",
    "min_books" => "",
    "min_avg_score" => "",
    "min_total_sales" => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    authors = Catalog.list_authors_with_stats()

    {:ok,
     socket
     |> assign(:page_title, "Authors Report")
     |> assign(:authors, authors)
     |> assign(:filters, @default_filters)
     |> assign(:sort_by, :name)
     |> assign(:sort_dir, :asc)
     |> assign_rows()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Authors Report
        <:subtitle>
          Books published, average review score and total sales per author
        </:subtitle>
      </.header>

      <form
        id="authors-filter-form"
        phx-change="filter"
        class="grid grid-cols-2 sm:grid-cols-5 gap-3 my-4"
      >
        <input
          type="text"
          name="filters[name]"
          value={@filters["name"]}
          placeholder="Filter by name"
          class="input input-bordered w-full"
        />
        <input
          type="text"
          name="filters[country_of_origin]"
          value={@filters["country_of_origin"]}
          placeholder="Filter by country"
          class="input input-bordered w-full"
        />
        <input
          type="number"
          name="filters[min_books]"
          value={@filters["min_books"]}
          placeholder="Min. books"
          class="input input-bordered w-full"
        />
        <input
          type="number"
          step="0.1"
          name="filters[min_avg_score]"
          value={@filters["min_avg_score"]}
          placeholder="Min. avg score"
          class="input input-bordered w-full"
        />
        <input
          type="number"
          name="filters[min_total_sales]"
          value={@filters["min_total_sales"]}
          placeholder="Min. total sales"
          class="input input-bordered w-full"
        />
      </form>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <.sort_th field={:name} label="Name" sort_by={@sort_by} sort_dir={@sort_dir} />
              <.sort_th
                field={:country_of_origin}
                label="Country of origin"
                sort_by={@sort_by}
                sort_dir={@sort_dir}
              />
              <.sort_th
                field={:books_count}
                label="Books published"
                sort_by={@sort_by}
                sort_dir={@sort_dir}
              />
              <.sort_th
                field={:avg_score}
                label="Average score"
                sort_by={@sort_by}
                sort_dir={@sort_dir}
              />
              <.sort_th
                field={:total_sales}
                label="Total sales"
                sort_by={@sort_by}
                sort_dir={@sort_dir}
              />
            </tr>
          </thead>
          <tbody>
            <tr :for={author <- @rows} id={"author-#{author.id}"}>
              <td>
                <.link navigate={~p"/authors/#{author.id}"} class="link">{author.name}</.link>
              </td>
              <td>{author.country_of_origin}</td>
              <td>{author.books_count}</td>
              <td>{format_score(author.avg_score)}</td>
              <td>{author.total_sales}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p :if={@rows == []} class="text-center text-base-content/60 py-6">
        No authors match these filters.
      </p>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_rows()}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    field = String.to_existing_atom(field)

    {sort_by, sort_dir} =
      if socket.assigns.sort_by == field do
        {field, toggle_dir(socket.assigns.sort_dir)}
      else
        {field, :asc}
      end

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:sort_dir, sort_dir)
     |> assign_rows()}
  end

  defp toggle_dir(:asc), do: :desc
  defp toggle_dir(:desc), do: :asc

  defp assign_rows(socket) do
    rows =
      socket.assigns.authors
      |> apply_filters(socket.assigns.filters)
      |> apply_sort(socket.assigns.sort_by, socket.assigns.sort_dir)

    assign(socket, :rows, rows)
  end

  defp apply_filters(authors, filters) do
    Enum.filter(authors, fn author ->
      matches_text?(author.name, filters["name"]) and
        matches_text?(author.country_of_origin, filters["country_of_origin"]) and
        matches_min?(author.books_count, filters["min_books"]) and
        matches_min?(author.avg_score, filters["min_avg_score"]) and
        matches_min?(author.total_sales, filters["min_total_sales"])
    end)
  end

  defp matches_text?(_value, filter) when filter in [nil, ""], do: true

  defp matches_text?(value, filter) do
    String.contains?(String.downcase(value || ""), String.downcase(filter))
  end

  defp matches_min?(_value, filter) when filter in [nil, ""], do: true

  defp matches_min?(value, filter) do
    case Float.parse(filter) do
      {min, _} -> (value || 0) >= min
      :error -> true
    end
  end

  defp apply_sort(authors, field, dir) do
    Enum.sort_by(authors, fn author -> Map.get(author, field) || 0 end, dir)
  end

  defp format_score(nil), do: "—"
  defp format_score(score), do: :erlang.float_to_binary(score * 1.0, decimals: 2)

  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :sort_by, :atom, required: true
  attr :sort_dir, :atom, required: true

  defp sort_th(assigns) do
    ~H"""
    <th phx-click="sort" phx-value-field={@field} class="cursor-pointer select-none hover:underline">
      {@label}
      <span :if={@sort_by == @field}>{if @sort_dir == :asc, do: "▲", else: "▼"}</span>
    </th>
    """
  end
end
