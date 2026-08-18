defmodule BookReviews.Catalog.Author do
  use Ecto.Schema
  import Ecto.Changeset

  schema "authors" do
    field :name, :string
    field :birth_date, :date
    field :country_of_origin, :string
    field :description, :string

    has_many :books, BookReviews.Catalog.Book

    timestamps(type: :utc_datetime)
  end

  def changeset(author, attrs) do
    author
    |> cast(attrs, [:name, :birth_date, :country_of_origin, :description])
    |> validate_required([:name])
  end
end
