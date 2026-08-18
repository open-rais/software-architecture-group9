defmodule BookReviews.Repo do
  use Ecto.Repo,
    otp_app: :book_reviews,
    adapter: Ecto.Adapters.SQLite3
end
