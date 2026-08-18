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
    |> cast(attrs, [:year, :sales])
    |> validate_required([:year, :sales])
  end
end
