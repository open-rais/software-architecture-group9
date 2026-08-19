defmodule BookReviewsWeb.SearchLiveTest do
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
      |> Enum.into(%{name: "Untitled", author_id: author_id})
      |> Catalog.create_book()

    book
  end

  test "shows no results until a query is entered", %{conn: conn} do
    book_fixture(%{name: "Any Book", summary: "a story about the ocean"})

    {:ok, _view, html} = live(conn, ~p"/search")

    refute html =~ "result(s)"
  end

  test "finds books whose summary contains any of the search words", %{conn: conn} do
    match = book_fixture(%{name: "Ocean Tale", summary: "a story about the ocean and a whale"})
    other = book_fixture(%{name: "Desert Tale", summary: "a story about the desert"})

    {:ok, view, _html} = live(conn, ~p"/search")

    view
    |> form("#book-search-form", %{"q" => "ocean mountain"})
    |> render_submit()

    assert has_element?(view, "#book-#{match.id}")
    refute has_element?(view, "#book-#{other.id}")
  end

  test "paginates results", %{conn: conn} do
    for n <- 1..12 do
      book_fixture(%{name: "Book #{n}", summary: "shared search term"})
    end

    {:ok, view, html} = live(conn, ~p"/search?q=shared")

    assert html =~ "12 result(s)"
    assert html =~ "Page 1 of 2"

    {:ok, view_page_2, _html} = live(conn, ~p"/search?q=shared&page=2")
    refute view == view_page_2
    assert render(view_page_2) =~ "Page 2 of 2"
  end
end
