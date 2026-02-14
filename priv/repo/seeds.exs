# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Resume.Repo.insert!(%Resume.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if Mix.env() == :dev do
  alias Resume.Accounts.User
  alias Resume.Repo

  unless Repo.get_by(User, email: "user@example.com") do
    %User{}
    |> User.email_changeset(%{email: "user@example.com"})
    |> User.password_changeset(%{password: "password1234"})
    |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now(:second))
    |> Repo.insert!()
  end
end
