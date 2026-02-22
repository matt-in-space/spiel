defmodule Resume.Accounts.UserNotifier do
  import Swoosh.Email

  require Logger

  alias Resume.Mailer
  alias Resume.Accounts.User

  defp html_layout(inner_content) do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
    <body style="margin:0;padding:0;background-color:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f5;">
        <tr><td align="center" style="padding:40px 20px;">
          <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:#ffffff;border-radius:8px;overflow:hidden;">
            <tr><td align="center" style="padding:32px 0 24px;border-bottom:1px solid #e4e4e7;">
              <span style="font-family:Georgia,'Times New Roman',serif;font-size:28px;font-weight:700;color:#18181b;letter-spacing:-0.5px;">Spiel</span>
            </td></tr>
            <tr><td style="padding:32px 40px;">
              #{inner_content}
            </td></tr>
            <tr><td align="center" style="padding:24px 40px;border-top:1px solid #e4e4e7;">
              <p style="margin:0;font-size:13px;color:#a1a1aa;">&copy; #{Date.utc_today().year} Spiel</p>
              <p style="margin:4px 0 0;font-size:13px;color:#a1a1aa;">giveyourspiel.app</p>
            </td></tr>
          </table>
        </td></tr>
      </table>
    </body>
    </html>
    """
  end

  defp html_email(heading, message, {button_text, url}) do
    html_layout("""
    <h1 style="margin:0 0 16px;font-size:22px;font-weight:600;color:#18181b;">#{heading}</h1>
    <p style="margin:0 0 24px;font-size:16px;line-height:1.5;color:#3f3f46;">#{message}</p>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 24px;">
      <tr><td align="center" style="background-color:#7c3aed;border-radius:6px;">
        <a href="#{url}" target="_blank" style="display:inline-block;padding:12px 32px;font-size:16px;font-weight:600;color:#ffffff;text-decoration:none;">#{button_text}</a>
      </td></tr>
    </table>
    <p style="margin:0;font-size:13px;color:#71717a;">Or copy and paste this link into your browser:</p>
    <p style="margin:4px 0 0;font-size:13px;color:#7c3aed;word-break:break-all;">#{url}</p>
    """)
  end

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, text, html) do
    email =
      new()
      |> to(recipient)
      |> from(Resume.Mailer.Addresses.no_reply())
      |> subject(subject)
      |> text_body(text)
      |> html_body(html)

    case Mailer.deliver(email) do
      {:ok, metadata} ->
        Logger.info(
          "Email sent to #{recipient}, subject: #{subject}, metadata: #{inspect(metadata)}"
        )

        {:ok, email}

      {:error, reason} ->
        Logger.error(
          "Failed to send email to #{recipient}, subject: #{subject}, error: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(
      user.email,
      "Update your email",
      """
      Hi #{user.email},

      You can change your email by visiting the URL below:

      #{url}

      If you didn't request this change, please ignore this.
      """,
      html_email(
        "Update your email",
        "Click the button below to update your email address.",
        {"Update email", url}
      )
    )
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(
      user.email,
      "Log in to Spiel",
      """
      Hi #{user.email},

      You can log into your account by visiting the URL below:

      #{url}

      If you didn't request this email, please ignore this.
      """,
      html_email(
        "Log in to Spiel",
        "Click the button below to log in to your account.",
        {"Log in", url}
      )
    )
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(
      user.email,
      "Confirm your account",
      """
      Hi #{user.email},

      You can confirm your account by visiting the URL below:

      #{url}

      If you didn't create an account with us, please ignore this.
      """,
      html_email(
        "Confirm your account",
        "Click the button below to confirm your account.",
        {"Confirm account", url}
      )
    )
  end
end
