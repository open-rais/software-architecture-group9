defmodule BookReviewsWeb.ReviewLive.Form do
  use BookReviewsWeb, :live_view

  alias BookReviews.Catalog
  alias BookReviews.Catalog.Review

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage reviews for {@book.name}.</:subtitle>
      </.header>

      <.form for={@form} id="review-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:score]} type="number" label="Score (1-5)" min="1" max="5" />
        <.input field={@form[:review]} type="textarea" label="Review" />
        <.input field={@form[:upvotes]} type="number" label="Upvotes" min="0" />
        <footer class="flex gap-4">
          <.button phx-disable-with="Saving..." variant="primary">Save Review</.button>
          <.button navigate={~p"/books/#{@book}/reviews"}>Cancel</.button>
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
    review = Catalog.get_review!(id)

    socket
    |> assign(:page_title, "Edit Review")
    |> assign(:review, review)
    |> assign(:form, to_form(Catalog.change_review(review)))
  end

  defp apply_action(socket, :new, _params) do
    review = %Review{book_id: socket.assigns.book.id}

    socket
    |> assign(:page_title, "New Review")
    |> assign(:review, review)
    |> assign(:form, to_form(Catalog.change_review(review)))
  end

  @impl true
  def handle_event("validate", %{"review" => review_params}, socket) do
    review_params = Map.put(review_params, "book_id", socket.assigns.book.id)
    changeset = Catalog.change_review(socket.assigns.review, review_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"review" => review_params}, socket) do
    review_params = Map.put(review_params, "book_id", socket.assigns.book.id)
    save_review(socket, socket.assigns.live_action, review_params)
  end

  defp save_review(socket, :edit, review_params) do
    case Catalog.update_review(socket.assigns.review, review_params) do
      {:ok, _review} ->
        {:noreply,
         socket
         |> put_flash(:info, "Review updated successfully")
         |> push_navigate(to: ~p"/books/#{socket.assigns.book}/reviews")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_review(socket, :new, review_params) do
    case Catalog.create_review(review_params) do
      {:ok, _review} ->
        {:noreply,
         socket
         |> put_flash(:info, "Review created successfully")
         |> push_navigate(to: ~p"/books/#{socket.assigns.book}/reviews")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
