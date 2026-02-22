defmodule ResumeWeb.Router do
  use ResumeWeb, :router

  import ResumeWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ResumeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ResumeWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/templates", PageController, :templates
    get "/terms", PageController, :terms
    get "/privacy", PageController, :privacy
    get "/sitemap.xml", SitemapController, :index
  end

  get "/health", ResumeWeb.HealthController, :index

  scope "/api", ResumeWeb do
    pipe_through :api

    post "/stripe/webhook", StripeWebhookController, :handle
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:resume, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ResumeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ResumeWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", ResumeWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/home", HomeLive
    live "/record", RecordingLive
    live "/upload", UploadLive
    live "/onboarding", OnboardingLive
    live "/profile", ProfileSettingsLive
    live "/coach", CoachLive
    live "/resumes/:id", ResumesLive.Show
    live "/resumes/:id/cover-letter", CoverLetterLive
    live "/billing", BillingLive

    get "/resumes/:id/pdf", ResumePDFController, :show
    get "/resumes/:id/cover-letter/pdf", CoverLetterPDFController, :show

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/admin", ResumeWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    live "/", Admin.DashboardLive
    live "/costs", Admin.CostsLive
    live "/billing", Admin.BillingLive
    live "/users", Admin.UsersLive
    live "/users/:id", Admin.UserDetailLive
  end

  scope "/", ResumeWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
