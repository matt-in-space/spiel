defmodule ResumeWeb.UserSessionHTML do
  use ResumeWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:resume, Resume.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
