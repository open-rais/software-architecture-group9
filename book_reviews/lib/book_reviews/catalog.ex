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

  ## Reports

  @doc """
  Returns every author with their published book count, average review
  score across all their books, and total sales across all their books.

  Each stat is computed in its own grouped subquery before being joined
  back to authors, so books with multiple reviews and multiple sales
  rows don't fan out against each other and inflate the aggregates.
  """
  def list_authors_with_stats do
    books_count =
      from b in Book,
        group_by: b.author_id,
        select: %{author_id: b.author_id, books_count: count(b.id)}

    review_stats =
      from b in Book,
        join: r in assoc(b, :reviews),
        group_by: b.author_id,
        select: %{author_id: b.author_id, avg_score: avg(r.score)}

    sales_stats =
      from b in Book,
        join: s in assoc(b, :sales),
        group_by: b.author_id,
        select: %{author_id: b.author_id, total_sales: sum(s.sales)}

    from(a in Author,
      left_join: bc in subquery(books_count),
      on: bc.author_id == a.id,
      left_join: rs in subquery(review_stats),
      on: rs.author_id == a.id,
      left_join: ss in subquery(sales_stats),
      on: ss.author_id == a.id,
      order_by: a.name,
      select: %{
        id: a.id,
        name: a.name,
        country_of_origin: a.country_of_origin,
        books_count: coalesce(bc.books_count, 0),
        avg_score: rs.avg_score,
        total_sales: coalesce(ss.total_sales, 0)
      }
    )
    |> Repo.all()
  end

  @doc """
  Returns the top `limit` books by average review score, each annotated
  with its author, average score, review count, and its single
  highest-rated and lowest-rated review.
  """
  def top_rated_books(limit \\ 10) do
    ranked =
      from r in Review,
        group_by: r.book_id,
        order_by: [desc: avg(r.score)],
        limit: ^limit,
        select: %{book_id: r.book_id, avg_score: avg(r.score), review_count: count(r.id)}

    top =
      from(b in Book,
        join: stats in subquery(ranked),
        on: stats.book_id == b.id,
        join: a in assoc(b, :author),
        order_by: [desc: stats.avg_score],
        select: %{
          book: b,
          author_name: a.name,
          avg_score: stats.avg_score,
          review_count: stats.review_count
        }
      )
      |> Repo.all()

    book_ids = Enum.map(top, & &1.book.id)

    reviews_by_book =
      from(r in Review, where: r.book_id in ^book_ids, order_by: [asc: r.id])
      |> Repo.all()
      |> Enum.group_by(& &1.book_id)

    Enum.map(top, fn entry ->
      reviews = Map.get(reviews_by_book, entry.book.id, [])

      entry
      |> Map.put(:highest_review, Enum.max_by(reviews, & &1.score, fn -> nil end))
      |> Map.put(:lowest_review, Enum.min_by(reviews, & &1.score, fn -> nil end))
    end)
  end

  @doc """
  Returns the top `limit` books by total sales, each annotated with its
  author, the book's total sales, the author's total sales across all
  their books, and whether the book ranked in the top 5 sellers among
  all books for the specific year it was published.
  """
  def top_selling_books(limit \\ 50) do
    book_totals =
      from s in Sale,
        group_by: s.book_id,
        select: %{book_id: s.book_id, total_sales: sum(s.sales)}

    top =
      from(b in Book,
        join: bt in subquery(book_totals),
        on: bt.book_id == b.id,
        join: a in assoc(b, :author),
        order_by: [desc: bt.total_sales],
        limit: ^limit,
        select: %{
          book: b,
          author_id: a.id,
          author_name: a.name,
          total_sales: bt.total_sales
        }
      )
      |> Repo.all()

    author_ids = top |> Enum.map(& &1.author_id) |> Enum.uniq()

    author_totals =
      from(b in Book,
        join: s in assoc(b, :sales),
        where: b.author_id in ^author_ids,
        group_by: b.author_id,
        select: {b.author_id, sum(s.sales)}
      )
      |> Repo.all()
      |> Map.new()

    ranks_by_book_and_year =
      from(s in Sale, select: {s.book_id, s.year, s.sales})
      |> Repo.all()
      |> Enum.group_by(fn {_book_id, year, _sales} -> year end)
      |> Enum.flat_map(fn {_year, rows} ->
        rows
        |> Enum.sort_by(fn {_book_id, _year, sales} -> sales end, :desc)
        |> Enum.with_index(1)
        |> Enum.map(fn {{book_id, year, _sales}, rank} -> {{book_id, year}, rank} end)
      end)
      |> Map.new()

    Enum.map(top, fn entry ->
      pub_year = entry.book.publication_date && entry.book.publication_date.year
      rank = pub_year && Map.get(ranks_by_book_and_year, {entry.book.id, pub_year})

      entry
      |> Map.put(:author_total_sales, Map.get(author_totals, entry.author_id, 0))
      |> Map.put(:top5_in_publication_year, rank != nil and rank <= 5)
    end)
  end
end
