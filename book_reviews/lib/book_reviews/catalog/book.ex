defmodule BookReviews.Catalog.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :name, :string
    field :summary, :string
    field :publication_date, :date
    field :sales_count, :integer, default: 0

    belongs_to :author, BookReviews.Catalog.Author
    has_many :reviews, BookReviews.Catalog.Review
    has_many :sales, BookReviews.Catalog.Sale

    timestamps(type: :utc_datetime)
  end

  def changeset(book, attrs) do
    book
    |> cast(attrs, [:name, :summary, :publication_date, :sales_count])
    |> validate_required([:name])
  end
end
