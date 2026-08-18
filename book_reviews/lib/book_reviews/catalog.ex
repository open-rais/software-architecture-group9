defmodule BookReviews.Catalog do
  @moduledoc """
  The Catalog context: authors, books, reviews, and sales.
  """

  import Ecto.Query, warn: false

  alias BookReviews.Repo
  alias BookReviews.Catalog.{Author, Book, Review, Sale}

  ## Authors

  def list_authors do
    Repo.all(from a in Author, order_by: a.name)
  end

  def get_author!(id) do
    Author
    |> Repo.get!(id)
    |> Repo.preload(:books)
  end

  def create_author(attrs \\ %{}) do
    %Author{}
    |> Author.changeset(attrs)
    |> Repo.insert()
  end

  def update_author(%Author{} = author, attrs) do
    author
    |> Author.changeset(attrs)
    |> Repo.update()
  end

  def delete_author(%Author{} = author) do
    Repo.delete(author)
  end

  def change_author(%Author{} = author, attrs \\ %{}) do
    Author.changeset(author, attrs)
  end

  ## Books

  def list_books do
    Repo.all(from b in Book, order_by: b.name, preload: :author)
  end

  def get_book!(id) do
    Book
    |> Repo.get!(id)
    |> Repo.preload([:author, :reviews, :sales])
  end

  def create_book(attrs \\ %{}) do
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end

  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  def delete_book(%Book{} = book) do
    Repo.delete(book)
  end

  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

  ## Reviews

  def list_reviews(%Book{} = book) do
    Repo.all(from r in Review, where: r.book_id == ^book.id, order_by: [desc: r.inserted_at])
  end

  def get_review!(id), do: Repo.get!(Review, id)

  def create_review(attrs \\ %{}) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  def update_review(%Review{} = review, attrs) do
    review
    |> Review.changeset(attrs)
    |> Repo.update()
  end

  def delete_review(%Review{} = review) do
    Repo.delete(review)
  end

  def change_review(%Review{} = review, attrs \\ %{}) do
    Review.changeset(review, attrs)
  end

  ## Sales

  def list_sales(%Book{} = book) do
    Repo.all(from s in Sale, where: s.book_id == ^book.id, order_by: s.year)
  end

  def get_sale!(id), do: Repo.get!(Sale, id)

  def create_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert()
  end

  def update_sale(%Sale{} = sale, attrs) do
    sale
    |> Sale.changeset(attrs)
    |> Repo.update()
  end

  def delete_sale(%Sale{} = sale) do
    Repo.delete(sale)
  end

  def change_sale(%Sale{} = sale, attrs \\ %{}) do
    Sale.changeset(sale, attrs)
  end
end
