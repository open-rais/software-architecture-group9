# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Populates:
#   - 50 authors
#   - 300 books (randomly distributed across authors)
#   - 1 to 10 reviews per book
#   - Yearly sales figures spanning at least 5 years per book

alias BookReviews.Repo
alias BookReviews.Catalog.{Author, Book, Review, Sale}

# --- Reset existing data so the script can be re-run safely -----------------

Repo.delete_all(Sale)
Repo.delete_all(Review)
Repo.delete_all(Book)
Repo.delete_all(Author)

# --- Fixture data -------------------------------------------------------

first_names = ~w(
  James Mary John Patricia Robert Jennifer Michael Linda William Elizabeth
  David Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen
  Daniel Nancy Matthew Lisa Anthony Betty Mark Margaret Donald Sandra
  Steven Ashley Andrew Kimberly Paul Emily Joshua Donna Kenneth Michelle
  Kevin Carol Brian Amanda George Melissa Edward Deborah Ronald Stephanie
  Sofia Mateo Valentina Diego Camila Sebastian Isabella Andres Lucia Javier
  Yuki Hiro Wei Mei Amara Kwame Fatima Omar Ingrid Lars
)

last_names = ~w(
  Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez
  Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin
  Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson
  Walker Young Allen King Wright Scott Torres Nguyen Hill Flores
  Green Adams Nelson Baker Hall Rivera Campbell Mitchell Carter Roberts
  Okafor Nakamura Ivanov Andersson Kowalski Dubois Rossi Silva Costa Muller
)

countries = ~w(
  United-States United-Kingdom Canada France Germany Japan Chile Spain Brazil
  India Nigeria Australia Italy Mexico South-Korea Sweden Russia Egypt
  Argentina Ireland
)

genres = ~w(
  Fiction Non-Fiction Mystery Science-Fiction Fantasy Romance Thriller
  Horror Biography History Poetry Self-Help Young-Adult Children's
  Graphic-Novel Historical-Fiction Adventure Crime Drama Philosophy
)

title_nouns = ~w(
  Shadow Garden Ocean Whisper Kingdom Journey Mirror Silence Ember Storm
  River Ashes Crown Labyrinth Harbor Echo Winter Flame Horizon Secret
  Promise Wolf Star Dream Rose Empire Tide Forest Key Prophecy
)

title_adjectives = ~w(
  Silent Hidden Lost Broken Distant Golden Forgotten Final Endless Quiet
  Crimson Fractured Restless Radiant Wandering Ancient Bitter Fragile
)

review_comments = %{
  low: [
    "Really did not connect with this one, the pacing dragged.",
    "Expected more from this book, felt flat overall.",
    "The plot had potential but the execution fell short.",
    "Couldn't get into the characters, unfortunately."
  ],
  mid: [
    "A decent read, some parts were stronger than others.",
    "Enjoyed parts of it but the middle section lost momentum.",
    "Good ideas, though the ending felt rushed.",
    "Solid book overall, worth a read if you like the genre."
  ],
  high: [
    "Absolutely loved this book, couldn't put it down!",
    "One of the best reads I've had this year.",
    "Beautifully written with a gripping storyline.",
    "The character development was outstanding from start to finish.",
    "A masterpiece, highly recommend to anyone who enjoys the genre."
  ]
}

random_date_between = fn from_date, to_date ->
  from_days = Date.to_gregorian_days(from_date)
  to_days = Date.to_gregorian_days(to_date)
  Date.from_gregorian_days(Enum.random(from_days..to_days))
end

random_name = fn ->
  "#{Enum.random(first_names)} #{Enum.random(last_names)}"
end

random_title = fn ->
  case Enum.random(1..4) do
    1 -> "The #{Enum.random(title_adjectives)} #{Enum.random(title_nouns)}"
    2 -> "#{Enum.random(title_nouns)} of #{Enum.random(title_nouns)}"
    3 -> "The #{Enum.random(title_nouns)}'s #{Enum.random(title_nouns)}"
    4 -> "A #{Enum.random(title_adjectives)} #{Enum.random(title_nouns)}"
  end
end

today = Date.utc_today()
current_year = today.year

# --- Authors --------------------------------------------------------------

authors =
  for _ <- 1..50 do
    birth_date = random_date_between.(~D[1930-01-01], ~D[1995-12-31])

    Repo.insert!(%Author{
      name: random_name.(),
      country_of_origin: Enum.random(countries),
      description:
        "#{Enum.random(countries)} author known for works in #{Enum.random(genres)} and #{Enum.random(genres)}.",
      birth_date: birth_date
    })
  end

# --- Books, reviews and sales -----------------------------------------------
#
# For each book we first decide its yearly sales figures (at least 5 years),
# derive the book's total `sales_count` from them, then insert the book and
# bulk-insert its reviews and sales rows.

now = DateTime.utc_now() |> DateTime.truncate(:second)

books_with_children =
  for _ <- 1..300 do
    author = Enum.random(authors)

    earliest_publish =
      author.birth_date
      |> Date.add(20 * 365)
      |> then(&Enum.max([&1, ~D[1950-01-01]], Date))

    publication_date = random_date_between.(earliest_publish, today)
    published_year = publication_date.year

    years_of_sales = Enum.random(5..10)
    latest_start = max(published_year, current_year - years_of_sales + 1)
    start_year = min(published_year, latest_start)

    base_sales = Enum.random(500..20_000)

    yearly_sales =
      for offset <- 0..(years_of_sales - 1) do
        year = start_year + offset
        # Sales taper off (or fluctuate) the further from publication
        decay = :math.pow(0.85, offset)
        fluctuation = Enum.random(70..130) / 100.0
        sales = max(round(base_sales * decay * fluctuation), 10)
        {year, sales}
      end

    total_sales = yearly_sales |> Enum.map(fn {_year, sales} -> sales end) |> Enum.sum()

    book =
      Repo.insert!(%Book{
        name: random_title.(),
        summary:
          "A #{String.downcase(Enum.random(genres))} story about #{Enum.random(title_nouns) |> String.downcase()} and #{Enum.random(title_nouns) |> String.downcase()}.",
        publication_date: publication_date,
        sales_count: total_sales,
        author_id: author.id
      })

    review_count = Enum.random(1..10)

    reviews =
      for _ <- 1..review_count do
        score = Enum.random(1..5)

        bucket =
          cond do
            score <= 2 -> :low
            score == 3 -> :mid
            true -> :high
          end

        %{
          review: Enum.random(review_comments[bucket]),
          score: score,
          upvotes: Enum.random(0..250),
          book_id: book.id,
          inserted_at: now,
          updated_at: now
        }
      end

    sales =
      for {year, sales} <- yearly_sales do
        %{
          year: year,
          sales: sales,
          book_id: book.id,
          inserted_at: now,
          updated_at: now
        }
      end

    {book, reviews, sales}
  end

books = Enum.map(books_with_children, fn {book, _, _} -> book end)
reviews = Enum.flat_map(books_with_children, fn {_, reviews, _} -> reviews end)
sales = Enum.flat_map(books_with_children, fn {_, _, sales} -> sales end)

reviews
|> Enum.chunk_every(500)
|> Enum.each(&Repo.insert_all(Review, &1))

sales
|> Enum.chunk_every(500)
|> Enum.each(&Repo.insert_all(Sale, &1))

IO.puts(
  "Seeded #{length(authors)} authors, #{length(books)} books, #{length(reviews)} reviews, #{length(sales)} sales."
)
