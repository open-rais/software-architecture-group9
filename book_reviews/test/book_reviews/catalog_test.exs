defmodule BookReviews.CatalogTest do
  use BookReviews.DataCase

  alias BookReviews.Catalog

  defp author_fixture(attrs \\ %{}) do
    {:ok, author} =
      attrs
      |> Enum.into(%{name: "Ursula K. Le Guin", country_of_origin: "United-States"})
      |> Catalog.create_author()

    author
  end

  defp book_fixture(attrs \\ %{}) do
    author = attrs[:author] || author_fixture()

    {:ok, book} =
      attrs
      |> Map.delete(:author)
      |> Enum.into(%{name: "The Left Hand of Darkness", author_id: author.id})
      |> Catalog.create_book()

    book
  end

  describe "authors" do
    test "list_authors/0 returns all authors ordered by name" do
      author_fixture(%{name: "Zeta"})
      author_fixture(%{name: "Alpha"})

      assert Enum.map(Catalog.list_authors(), & &1.name) == ["Alpha", "Zeta"]
    end

    test "get_author!/1 returns the author with its books preloaded" do
      author = author_fixture()
      book_fixture(%{author: author})

      fetched = Catalog.get_author!(author.id)
      assert fetched.id == author.id
      assert [%BookReviews.Catalog.Book{}] = fetched.books
    end

    test "create_author/1 requires a name" do
      assert {:error, changeset} = Catalog.create_author(%{name: ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "update_author/2 updates the author" do
      author = author_fixture()
      assert {:ok, author} = Catalog.update_author(author, %{name: "New Name"})
      assert author.name == "New Name"
    end

    test "delete_author/1 deletes the author" do
      author = author_fixture()
      assert {:ok, %BookReviews.Catalog.Author{}} = Catalog.delete_author(author)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_author!(author.id) end
    end

    test "change_author/2 returns an author changeset" do
      assert %Ecto.Changeset{} = Catalog.change_author(author_fixture())
    end
  end

  describe "books" do
    test "list_books/0 returns all books with their author preloaded" do
      book = book_fixture()

      assert [fetched] = Catalog.list_books()
      assert fetched.id == book.id
      assert %BookReviews.Catalog.Author{} = fetched.author
    end

    test "get_book!/1 returns the book with associations preloaded" do
      book = book_fixture()
      fetched = Catalog.get_book!(book.id)

      assert fetched.id == book.id
      assert %BookReviews.Catalog.Author{} = fetched.author
      assert fetched.reviews == []
      assert fetched.sales == []
    end

    test "create_book/1 requires a name and an author" do
      assert {:error, changeset} = Catalog.create_book(%{name: ""})
      assert %{name: ["can't be blank"], author_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_book/1 raises for an author that does not exist" do
      assert_raise Ecto.ConstraintError, fn ->
        Catalog.create_book(%{name: "Ghost", author_id: 999_999})
      end
    end

    test "update_book/2 updates the book" do
      book = book_fixture()
      assert {:ok, book} = Catalog.update_book(book, %{name: "Updated Title"})
      assert book.name == "Updated Title"
    end

    test "delete_book/1 deletes the book" do
      book = book_fixture()
      assert {:ok, %BookReviews.Catalog.Book{}} = Catalog.delete_book(book)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_book!(book.id) end
    end

    test "change_book/2 returns a book changeset" do
      assert %Ecto.Changeset{} = Catalog.change_book(book_fixture())
    end
  end

  describe "reviews" do
    test "list_reviews/1 returns only the reviews for the given book" do
      book = book_fixture()
      other_book = book_fixture()

      {:ok, review} = Catalog.create_review(%{review: "Great!", score: 5, book_id: book.id})
      Catalog.create_review(%{review: "Meh", score: 3, book_id: other_book.id})

      assert [fetched] = Catalog.list_reviews(book)
      assert fetched.id == review.id
    end

    test "create_review/1 validates score range and required fields" do
      book = book_fixture()

      assert {:error, changeset} =
               Catalog.create_review(%{review: "Ok", score: 6, book_id: book.id})

      assert %{score: ["must be less than or equal to 5"]} = errors_on(changeset)
    end

    test "update_review/2 updates the review" do
      book = book_fixture()
      {:ok, review} = Catalog.create_review(%{review: "Ok", score: 3, book_id: book.id})

      assert {:ok, review} = Catalog.update_review(review, %{upvotes: 10})
      assert review.upvotes == 10
    end

    test "delete_review/1 deletes the review" do
      book = book_fixture()
      {:ok, review} = Catalog.create_review(%{review: "Ok", score: 3, book_id: book.id})

      assert {:ok, %BookReviews.Catalog.Review{}} = Catalog.delete_review(review)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_review!(review.id) end
    end

    test "change_review/2 returns a review changeset" do
      book = book_fixture()
      {:ok, review} = Catalog.create_review(%{review: "Ok", score: 3, book_id: book.id})
      assert %Ecto.Changeset{} = Catalog.change_review(review)
    end
  end

  describe "sales" do
    test "list_sales/1 returns only the sales for the given book ordered by year" do
      book = book_fixture()
      other_book = book_fixture()

      Catalog.create_sale(%{year: 2021, sales: 100, book_id: book.id})
      {:ok, sale_2020} = Catalog.create_sale(%{year: 2020, sales: 50, book_id: book.id})
      Catalog.create_sale(%{year: 2020, sales: 10, book_id: other_book.id})

      assert [%{id: id, year: 2020}, %{year: 2021}] = Catalog.list_sales(book)
      assert id == sale_2020.id
    end

    test "create_sale/1 enforces one sales row per book per year" do
      book = book_fixture()
      assert {:ok, _} = Catalog.create_sale(%{year: 2020, sales: 100, book_id: book.id})

      assert {:error, changeset} = Catalog.create_sale(%{year: 2020, sales: 5, book_id: book.id})
      assert %{book_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_sale/2 updates the sale" do
      book = book_fixture()
      {:ok, sale} = Catalog.create_sale(%{year: 2020, sales: 100, book_id: book.id})

      assert {:ok, sale} = Catalog.update_sale(sale, %{sales: 200})
      assert sale.sales == 200
    end

    test "delete_sale/1 deletes the sale" do
      book = book_fixture()
      {:ok, sale} = Catalog.create_sale(%{year: 2020, sales: 100, book_id: book.id})

      assert {:ok, %BookReviews.Catalog.Sale{}} = Catalog.delete_sale(sale)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_sale!(sale.id) end
    end

    test "change_sale/2 returns a sale changeset" do
      book = book_fixture()
      {:ok, sale} = Catalog.create_sale(%{year: 2020, sales: 100, book_id: book.id})
      assert %Ecto.Changeset{} = Catalog.change_sale(sale)
    end
  end
end
