defmodule BookReviews.Catalog.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field :review, :string
    field :score, :integer
    field :upvotes, :integer, default: 0

    belongs_to :book, BookReviews.Catalog.Book

    timestamps(type: :utc_datetime)
  end

  def changeset(review, attrs) do
    review
    |> cast(attrs, [:review, :score, :upvotes])
    |> validate_required([:review, :score])
    |> validate_number(:score, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
  end
end
