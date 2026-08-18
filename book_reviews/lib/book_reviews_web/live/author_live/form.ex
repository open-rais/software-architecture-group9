defmodule BookReviewsWeb.AuthorLive.Form do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog
  alias BookReviews.Catalog.Author

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage author records.</:subtitle>
      </.header>

      <.form for={@form} id="author-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:birth_date]} type="date" label="Birth date" />
        <.input field={@form[:country_of_origin]} type="text" label="Country of origin" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <footer class="flex gap-4">
          <.button phx-disable-with="Saving..." variant="primary">Save Author</.button>
          <.button navigate={return_path(@return_to, @author)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    author = Catalog.get_author!(id)

    socket
    |> assign(:page_title, "Edit Author")
    |> assign(:author, author)
    |> assign(:form, to_form(Catalog.change_author(author)))
  end

  defp apply_action(socket, :new, _params) do
    author = %Author{}

    socket
    |> assign(:page_title, "New Author")
    |> assign(:author, author)
    |> assign(:form, to_form(Catalog.change_author(author)))
  end

  @impl true
  def handle_event("validate", %{"author" => author_params}, socket) do
    changeset = Catalog.change_author(socket.assigns.author, author_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"author" => author_params}, socket) do
    save_author(socket, socket.assigns.live_action, author_params)
  end

  defp save_author(socket, :edit, author_params) do
    case Catalog.update_author(socket.assigns.author, author_params) do
      {:ok, author} ->
        {:noreply,
         socket
         |> put_flash(:info, "Author updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, author))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_author(socket, :new, author_params) do
    case Catalog.create_author(author_params) do
      {:ok, author} ->
        {:noreply,
         socket
         |> put_flash(:info, "Author created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, author))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _author), do: ~p"/authors"
  defp return_path("show", author), do: ~p"/authors/#{author}"
end
