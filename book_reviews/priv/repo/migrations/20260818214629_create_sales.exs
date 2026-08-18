defmodule BookReviews.Repo.Migrations.CreateSales do
  use Ecto.Migration

  def change do
    create table(:sales) do
      add :year, :integer, null: false
      add :sales, :integer, null: false

      add :book_id, references(:books, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:sales, [:book_id])
    create unique_index(:sales, [:book_id, :year])
  end
end
