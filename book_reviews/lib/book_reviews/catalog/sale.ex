defmodule BookReviews.Catalog.Sale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sales" do
    field :year, :integer
    field :sales, :integer

    belongs_to :book, BookReviews.Catalog.Book

    timestamps(type: :utc_datetime)
  end

  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [:year, :sales, :book_id])
    |> validate_required([:year, :sales, :book_id])
    |> foreign_key_constraint(:book_id)
    |> unique_constraint([:book_id, :year], name: :sales_book_id_year_index)
  end
end
