defmodule BookReviews.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :name, :string, null: false
      add :summary, :text
      add :publication_date, :date
      add :sales_count, :integer, null: false, default: 0

      add :author_id, references(:authors, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:books, [:author_id])
  end
end
