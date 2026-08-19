defmodule BookReviewsWeb.Router do
  use BookReviewsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BookReviewsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BookReviewsWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/authors", AuthorLive.Index, :index
    live "/authors/new", AuthorLive.Form, :new
    live "/authors/:id", AuthorLive.Show, :show
    live "/authors/:id/edit", AuthorLive.Form, :edit

    live "/books", BookLive.Index, :index
    live "/books/new", BookLive.Form, :new
    live "/books/:id", BookLive.Show, :show
    live "/books/:id/edit", BookLive.Form, :edit

    live "/books/:book_id/reviews", ReviewLive.Index, :index
    live "/books/:book_id/reviews/new", ReviewLive.Form, :new
    live "/books/:book_id/reviews/:id/edit", ReviewLive.Form, :edit

    live "/books/:book_id/sales", SaleLive.Index, :index
    live "/books/:book_id/sales/new", SaleLive.Form, :new
    live "/books/:book_id/sales/:id/edit", SaleLive.Form, :edit

    live "/search", SearchLive.Index, :index

    live "/reports/authors", ReportLive.Authors, :index
    live "/reports/top-rated-books", ReportLive.TopRated, :index
    live "/reports/top-selling-books", ReportLive.TopSelling, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", BookReviewsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:book_reviews, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BookReviewsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
