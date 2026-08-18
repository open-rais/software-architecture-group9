defmodule BookReviewsWeb.SaleLive.Form do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog
  alias BookReviews.Catalog.Sale

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage yearly sales for {@book.name}.</:subtitle>
      </.header>

      <.form for={@form} id="sale-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:year]} type="number" label="Year" />
        <.input field={@form[:sales]} type="number" label="Sales" min="0" />
        <footer class="flex gap-4">
          <.button phx-disable-with="Saving..." variant="primary">Save Sale</.button>
          <.button navigate={~p"/books/#{@book}/sales"}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"book_id" => book_id} = params, _session, socket) do
    book = Catalog.get_book!(book_id)

    {:ok,
     socket
     |> assign(:book, book)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    sale = Catalog.get_sale!(id)

    socket
    |> assign(:page_title, "Edit Sale")
    |> assign(:sale, sale)
    |> assign(:form, to_form(Catalog.change_sale(sale)))
  end

  defp apply_action(socket, :new, _params) do
    sale = %Sale{book_id: socket.assigns.book.id}

    socket
    |> assign(:page_title, "New Sale")
    |> assign(:sale, sale)
    |> assign(:form, to_form(Catalog.change_sale(sale)))
  end

  @impl true
  def handle_event("validate", %{"sale" => sale_params}, socket) do
    sale_params = Map.put(sale_params, "book_id", socket.assigns.book.id)
    changeset = Catalog.change_sale(socket.assigns.sale, sale_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"sale" => sale_params}, socket) do
    sale_params = Map.put(sale_params, "book_id", socket.assigns.book.id)
    save_sale(socket, socket.assigns.live_action, sale_params)
  end

  defp save_sale(socket, :edit, sale_params) do
    case Catalog.update_sale(socket.assigns.sale, sale_params) do
      {:ok, _sale} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sale updated successfully")
         |> push_navigate(to: ~p"/books/#{socket.assigns.book}/sales")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_sale(socket, :new, sale_params) do
    case Catalog.create_sale(sale_params) do
      {:ok, _sale} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sale created successfully")
         |> push_navigate(to: ~p"/books/#{socket.assigns.book}/sales")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
