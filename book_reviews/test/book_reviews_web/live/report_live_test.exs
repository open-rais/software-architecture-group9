defmodule BookReviewsWeb.ReportLiveTest do
  use BookReviewsWeb.ConnCase

  import Phoenix.LiveViewTest

  alias BookReviews.Catalog

  defp author_fixture(attrs \\ %{}) do
    {:ok, author} =
      attrs
      |> Enum.into(%{name: "Ursula K. Le Guin", country_of_origin: "United-States"})
      |> Catalog.create_author()

    author
  end

  defp book_fixture(attrs) do
    author_id = attrs[:author_id] || author_fixture().id

    {:ok, book} =
      attrs
      |> Enum.into(%{name: "The Left Hand of Darkness", author_id: author_id})
      |> Catalog.create_book()

    book
  end

  defp review_fixture(attrs) do
    {:ok, review} =
      attrs
      |> Enum.into(%{review: "A review"})
      |> Catalog.create_review()

    review
  end

  defp sale_fixture(attrs) do
    {:ok, sale} = Catalog.create_sale(attrs)
    sale
  end

  describe "Authors report" do
    test "lists every author with computed stats", %{conn: conn} do
      author = author_fixture(%{name: "Zora Neale"})
      book = book_fixture(%{author_id: author.id})
      review_fixture(%{book_id: book.id, score: 4})
      review_fixture(%{book_id: book.id, score: 2})
      sale_fixture(%{book_id: book.id, year: 2020, sales: 100})
      sale_fixture(%{book_id: book.id, year: 2021, sales: 50})

      {:ok, view, html} = live(conn, ~p"/reports/authors")

      assert html =~ "Zora Neale"
      assert has_element?(view, "#author-#{author.id}", "Zora Neale")
      assert has_element?(view, "#author-#{author.id}", "1")
      assert has_element?(view, "#author-#{author.id}", "3.00")
      assert has_element?(view, "#author-#{author.id}", "150")
    end

    test "filters rows by name", %{conn: conn} do
      one = author_fixture(%{name: "Alpha Author"})
      two = author_fixture(%{name: "Beta Writer"})

      {:ok, view, _html} = live(conn, ~p"/reports/authors")

      assert has_element?(view, "#author-#{one.id}")
      assert has_element?(view, "#author-#{two.id}")

      view
      |> form("form[phx-change=filter]", %{"filters" => %{"name" => "Alpha"}})
      |> render_change()

      assert has_element?(view, "#author-#{one.id}")
      refute has_element?(view, "#author-#{two.id}")
    end

    test "sorts by clicking a column header", %{conn: conn} do
      a = author_fixture(%{name: "Aaron"})
      z = author_fixture(%{name: "Zeus"})

      {:ok, view, html} = live(conn, ~p"/reports/authors")

      assert index_of(html, a.name) < index_of(html, z.name)

      html = view |> element("th", "Name") |> render_click()

      assert index_of(html, a.name) > index_of(html, z.name)
    end
  end

  describe "Top rated books report" do
    test "shows up to 10 books ordered by average score with best/worst reviews", %{conn: conn} do
      book = book_fixture(%{name: "Great Novel"})
      review_fixture(%{book_id: book.id, score: 5, review: "Loved it"})
      review_fixture(%{book_id: book.id, score: 1, review: "Hated it"})

      {:ok, view, _html} = live(conn, ~p"/reports/top-rated-books")

      assert has_element?(view, "#book-#{book.id}", "Great Novel")
      assert has_element?(view, "#book-#{book.id}", "Loved it")
      assert has_element?(view, "#book-#{book.id}", "Hated it")
    end
  end

  describe "Top selling books report" do
    test "shows total sales for the book and its author, and top-5-of-year status", %{
      conn: conn
    } do
      author = author_fixture()

      other_book =
        book_fixture(%{author_id: author.id, publication_date: ~D[2019-01-01]})

      sale_fixture(%{book_id: other_book.id, year: 2019, sales: 20})

      book =
        book_fixture(%{
          author_id: author.id,
          name: "Bestseller",
          publication_date: ~D[2020-01-01]
        })

      sale_fixture(%{book_id: book.id, year: 2020, sales: 500})

      {:ok, view, _html} = live(conn, ~p"/reports/top-selling-books")

      assert has_element?(view, "#book-#{book.id}", "Bestseller")
      assert has_element?(view, "#book-#{book.id}", "500")
      assert has_element?(view, "#book-#{book.id}", "520")
      assert has_element?(view, "#book-#{book.id}", "Yes")
    end
  end

  defp index_of(html, needle) do
    :binary.match(html, needle) |> elem(0)
  end
end
